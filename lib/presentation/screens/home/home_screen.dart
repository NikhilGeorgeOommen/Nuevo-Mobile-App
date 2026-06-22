import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/home_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../providers/core_providers.dart';
import '../../providers/phase_provider.dart';
import '../../../domain/entities/task.dart' as entities;
import '../../../domain/entities/user.dart' as entities;
import '../../../domain/entities/wellness_program.dart';
import '../../../domain/entities/home/home_dashboard.dart';
import '../../../data/models/phase_model.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/home/wellness_card.dart';
import '../../widgets/home/info_card.dart';
import '../../widgets/home/task_card.dart';
import '../../widgets/home/program_card.dart';
import '../../widgets/home/quick_access_grid.dart';
import '../../widgets/home/quick_access_card.dart';
import '../../widgets/home/dietitian_session_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  entities.Task _mapPatientTaskToEntity(PatientTaskModel pTask) {
    entities.TaskType type;
    final String actualType = (pTask.taskType.isNotEmpty ? pTask.taskType : (pTask.phaseTask?.taskType ?? '')).toUpperCase();
    
    switch (actualType) {
      case 'QUESTIONNAIRE':
        type = entities.TaskType.questionnaire;
        break;
      case 'APPOINTMENT':
        type = entities.TaskType.appointment;
        break;
      case 'EXERCISE':
        type = entities.TaskType.exercise;
        break;
      case 'NUTRITION':
        type = entities.TaskType.nutrition;
        break;
      default:
        type = entities.TaskType.general;
    }
    return entities.Task(
      id: pTask.id,
      title: pTask.taskName.isNotEmpty ? pTask.taskName : (pTask.phaseTask?.title ?? 'Task'),
      description: pTask.phaseTask?.description ?? '',
      durationMinutes: pTask.phaseTask?.points ?? 5,
      isCompleted: pTask.legacyStatus == 'COMPLETED' || pTask.status == 'COMPLETED',
      type: type,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(homeDashboardProvider);
    final userState = ref.watch(userProvider);
    
    // Call active phase API after auth and home api are loaded
    final activePhaseState = ref.watch(activePhaseProvider);
    final isHomeAndProfileLoaded = userState.valueOrNull != null && dashboardState.valueOrNull != null;
    
    // Only fetch when home is first loaded (profile + dashboard ready) and not yet fetched.
    // Sub-screens are responsible for calling fetchActivePhase() after task completion.
    if (isHomeAndProfileLoaded && 
        activePhaseState.valueOrNull == null && 
        !ref.read(activePhaseProvider.notifier).hasInitiatedFetch && 
        !activePhaseState.hasError) {
      Future.microtask(() => ref.read(activePhaseProvider.notifier).fetchActivePhase());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F8),
      body: dashboardState.when(
        data: (dashboard) {
          return Stack(
            children: [
              SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  onRefresh: () async {
                    return ref.refresh(homeDashboardProvider.future);
                  },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getHorizontalPadding(context),
                    vertical: ResponsiveUtils.spacing(context, base: 20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Header with profile and notification
                      _buildHeader(context, dashboard.welcome, userState),
                      SizedBox(
                        height: ResponsiveUtils.spacing(context, base: 24),
                      ),

                      // 2. Wellness Reset Card (Using WellnessProgress)
                      _buildWellnessSection(
                        context,
                        dashboard.wellnessProgress,
                      ),
                      SizedBox(
                        height: ResponsiveUtils.spacing(context, base: 20),
                      ),

                      // 3. Info Cards (Age & Session)
                      _buildInfoSection(context, dashboard.quickStats),
                      SizedBox(
                        height: ResponsiveUtils.spacing(context, base: 24),
                      ),
                      // 5. Task Completed
                      if (activePhaseState.valueOrNull != null) ...[
                        Builder(
                          builder: (context) {
                            final activePhaseTasks = activePhaseState.value?.tasks ?? [];
                            final completedPhaseTasks = activePhaseTasks.where((t) => t.legacyStatus == 'COMPLETED' || t.status == 'COMPLETED').map(_mapPatientTaskToEntity).toList();
                            final pendingPhaseTasks = activePhaseTasks.where((t) => t.legacyStatus != 'COMPLETED' && t.status != 'COMPLETED').map(_mapPatientTaskToEntity).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (completedPhaseTasks.isNotEmpty) ...[
                                  _buildSectionHeader(
                                    context,
                                    'Task Completed',
                                    onActionTap: () {
                                      context.push('/completed-tasks',
                                          extra: {'showCompleted': true});
                                    },
                                    actionLabel: 'See All',
                                    showArrow: false,
                                  ),
                                  SizedBox(
                                    height: ResponsiveUtils.spacing(context, base: 24),
                                  ),
                                ],
                                if (pendingPhaseTasks.isNotEmpty) ...[
                                  // 4. Action Required
                                  _buildSectionHeader(
                                    context,
                                    'Action required',
                                    onActionTap: () => context.push(
                                      '/completed-tasks',
                                      extra: {'showCompleted': false},
                                    ),
                                    actionLabel: 'Complete Now',
                                    showArrow: true,
                                  ),
                                  SizedBox(
                                    height: ResponsiveUtils.spacing(context, base: 16),
                                  ),
                                  _buildTasksList(context, ref, activePhaseTasks.where((t) => t.legacyStatus != 'COMPLETED' && t.status != 'COMPLETED').toList()),
                                  SizedBox(
                                    height: ResponsiveUtils.spacing(context, base: 24),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],


                      // 6. Program Card
                      // "Your Program" header removed per request
                      // _buildSectionHeader(
                      //   context,
                      //   'Your Program',
                      //   showArrow: false,
                      // ),
                      // SizedBox(height: ResponsiveUtils.spacing(context, base: 16)),
                      _buildProgramSection(context, dashboard.yourProgram),
                      SizedBox(
                        height: ResponsiveUtils.spacing(context, base: 24),
                      ),

                      // 7. Quick Access Grid
                      _buildSectionHeader(
                        context,
                        'Quick Access',
                        showArrow: false,
                      ),
                      SizedBox(
                        height: ResponsiveUtils.spacing(context, base: 16),
                      ),
                      _buildQuickAccessSection(context, dashboard.quickAccess),

                      // Bottom padding for scroll
                      SizedBox(
                        height: ResponsiveUtils.spacing(context, base: 40),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (dashboard.yourProgram == null)
            Positioned.fill(
              child: _buildNoProgramOverlay(context, ref),
            ),
        ],
      );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => AppErrorWidget(message: err.toString(), onRetry: () => ref.refresh(homeDashboardProvider)),
      ),
    );
  }

  Widget _buildNoProgramOverlay(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFFFDF9F8), // Match background to fully cover
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getHorizontalPadding(context)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: ResponsiveUtils.iconSize(context, base: 64),
            color: const Color(0xFF964A38),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, base: 24)),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, base: 16),
                color: const Color(0xFF17110D),
                height: 1.5,
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
              ),
              children: [
                const TextSpan(text: "Looks like you haven’t chosen a program yet. Please head to our "),
                TextSpan(
                  text: "website",
                  style: const TextStyle(
                    color: Color(0xFF964A38),
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      //                      final url = Uri.parse('https://nuevo-medical.simelabs.in');
                      final url = Uri.parse('https://nuevo-dev.simelabs.in/');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                ),
                const TextSpan(text: ", select a program, and come back to start using the app."),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, base: 32)),
          SizedBox(
            width: double.infinity,
            height: ResponsiveUtils.spacing(context, base: 56),
            child: ElevatedButton(
              onPressed: () {
                ref.refresh(homeDashboardProvider.future);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF964A38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.spacing(context, base: 12),
                  ),
                ),
              ),
              child: Text(
                'Refresh',
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, base: 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, base: 16)),
          SizedBox(
            width: double.infinity,
            height: ResponsiveUtils.spacing(context, base: 56),
            child: OutlinedButton(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF964A38)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.spacing(context, base: 12),
                  ),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, base: 16),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF964A38),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WelcomeData welcome, AsyncValue<entities.User?> userState) {
    final userImageUrl = userState.value?.profileImageUrl;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: ResponsiveUtils.iconSize(context, base: 48),
                height: ResponsiveUtils.iconSize(context, base: 48),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
                clipBehavior: Clip.antiAlias,
                child: (userImageUrl != null && userImageUrl.isNotEmpty)
                    ? (userImageUrl.toLowerCase().endsWith('.svg')
                        ? Image.asset(
                            'assets/images/details_image.png',
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            userImageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/images/details_image.png',
                              fit: BoxFit.cover,
                            ),
                          ))
                    : Image.asset(
                        'assets/images/details_image.png',
                        fit: BoxFit.cover,
                      ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, base: 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome",//welcome.greeting,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, base: 12),
                        color: const Color(0xFF3E160D).withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '${welcome.firstName} ${welcome.lastName}'.trim(),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, base: 20),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: const Color(0xFF3E160D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, base: 8)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: const Color(0xFF3E160D),
            size: ResponsiveUtils.iconSize(context, base: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildWellnessSection(
    BuildContext context,
    WellnessProgress progress,
  ) {
    return WellnessCard(wellnessProgress: progress);
  }

  Widget _buildInfoSection(BuildContext context, QuickStats stats) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            //child: InfoCard(value: stats.nuevoAge ?? '--', label: 'Nuevo Age'),
            child: InfoCard(value:'--', label: 'Nuevo Age'),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, base: 8)),
          Expanded(
            child: (stats.nextSession != null && stats.nextSession!.label == 'Doctor Session')
                ? DietitianSessionCard(
                    sessionInfo: stats.nextSession,
                    onTap: () {
                      // Handle tap, e.g., navigate to session details
                    },
                  )
                : Container(
                    height: ResponsiveUtils.spacing(context, base: 68),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6ECE9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '--',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, base: 24),
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onActionTap,
    String? actionLabel,
    bool showArrow = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, base: 16),
            fontWeight: FontWeight.w300,
            color: const Color(0xFF17110D),
            height: 1.5,
            letterSpacing: 0,
            fontFamily: 'Inter',
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: [
                Text(
                  actionLabel,
                  style: TextStyle(
                    color: const Color(0xFF964A38),
                    fontSize: ResponsiveUtils.fontSize(context, base: 12),
                    fontWeight: FontWeight.w300,
                    height: 16 / 12,
                    letterSpacing: 0,
                    fontFamily: 'Inter',
                  ),
                ),
                if (showArrow) ...[
                  SizedBox(width: ResponsiveUtils.spacing(context, base: 6)),
                  Icon(
                    Icons.arrow_forward,
                    size: ResponsiveUtils.iconSize(context, base: 14),
                    color: const Color(0xFF964A38),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  void _showTaskStatusDialog(BuildContext context, WidgetRef ref, PatientTaskModel pTask, List<String> options) {
    final title = pTask.taskName.isNotEmpty ? pTask.taskName : (pTask.phaseTask?.title ?? 'Update Status');
    String selectedOption = options.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF3E160D)),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please confirm your selection before submitting.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ...options.map((opt) => RadioListTile<String>(
                        title: Text(opt.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w500)),
                        value: opt,
                        groupValue: selectedOption,
                        activeColor: const Color(0xFF964A38),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedOption = val);
                        },
                      )),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF964A38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    // Capture navigator and messenger securely before async gap
                    final rootNavigator = Navigator.of(ctx, rootNavigator: true);
                    final messenger = ScaffoldMessenger.of(ctx);
                    
                    Navigator.of(ctx).pop(); // dismiss dialog
                    
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const PopScope(
                        canPop: false,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                    
                    final error = await ref.read(activePhaseTaskProvider.notifier).updateStatus(pTask.id, selectedOption);
                    
                    rootNavigator.pop(); // securely dismiss loader
                    
                    if (error == null) {
                      ref.read(activePhaseProvider.notifier).fetchActivePhase();
                      ref.refresh(homeDashboardProvider.future);
                      messenger.showSnackBar(const SnackBar(content: Text('Status updated successfully')));
                    } else {
                      messenger.showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
                  child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildTasksList(BuildContext context, WidgetRef ref, List<PatientTaskModel> patientTasks) {
    return SizedBox(
      height: ResponsiveUtils.spacing(context, base: 110),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: patientTasks.length,
        separatorBuilder: (_, __) =>
            SizedBox(width: ResponsiveUtils.spacing(context, base: 12)),
        itemBuilder: (context, index) {
          final pTask = patientTasks[index];
          final mappedTask = _mapPatientTaskToEntity(pTask);
          
          return TaskCard(
            task: mappedTask,
            onTap: mappedTask.isCompleted ? null : () async {
              final type = (pTask.taskType.isNotEmpty ? pTask.taskType : (pTask.phaseTask?.taskType ?? '')).toUpperCase();
              final options = pTask.statusOptions.isNotEmpty ? pTask.statusOptions : (pTask.phaseTask?.statusOptions ?? []);
              final isBooleanOptions = options.isNotEmpty && options.every((o) => ['yes', 'no', 'true', 'false'].contains(o.toLowerCase()));
              
              if (type == 'QUESTIONNAIRE') {
                if (isBooleanOptions) {
                  _showTaskStatusDialog(context, ref, pTask, options);
                  return;
                }
                
                final rootNavigator = Navigator.of(context, rootNavigator: true);
                final messenger = ScaffoldMessenger.of(context);
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const PopScope(
                    canPop: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
                
                // Yield the frame to ensure the dialog is fully pushed before popping
                await Future.delayed(const Duration(milliseconds: 100));
                
                try {
                  final response = await ref.read(apiClientProvider).getTaskById(pTask.id);
                  rootNavigator.pop(); // dismiss loader
                  
                  if (response.success && response.data != null) {
                    final qId = response.data!.phaseTask?.questionnaireId;
                    if (qId != null && qId.isNotEmpty) {
                      if (context.mounted) {
                        await context.push('/questionnaire/$qId/${pTask.id}');
                        if (context.mounted) {
                          ref.read(activePhaseProvider.notifier).fetchActivePhase();
                          ref.refresh(homeDashboardProvider.future);
                        }
                      }
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Questionnaire ID not found for this task')),
                      );
                    }
                  } else {
                    messenger.showSnackBar(
                      SnackBar(content: Text(response.message ?? 'Failed to fetch task details')),
                    );
                  }
                } catch (e) {
                  rootNavigator.pop(); // dismiss loader on exception
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error fetching task: $e')),
                  );
                }
              } else if (type == 'APPOINTMENT') {
                if (options.isNotEmpty) {
                  _showTaskStatusDialog(context, ref, pTask, options);
                } else {
                  context.push('/connecting-session');
                }
              } else {
                if (isBooleanOptions) {
                  _showTaskStatusDialog(context, ref, pTask, options);
                } else {
                  await context.push('/task/${pTask.id}');
                  if (context.mounted) {
                    ref.read(activePhaseProvider.notifier).fetchActivePhase();
                    ref.refresh(homeDashboardProvider.future);
                  }
                }
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildProgramSection(BuildContext context, WellnessProgram? program) {
    // Fallback if program is null
    final displayProgram =
        program ??
        const WellnessProgram(
          id: 'program-insight',
          name: 'Insight Program',
          description: 'Advanced assessment and specialist-led profiling',
          progressPercentage: 0,
          habitsCount: 0,
        );

    return ProgramCard(
      program: displayProgram,
      onViewPlan: () => context.go('/my-plan'),
      onCardTap: () => context.push('/your-program'),
    );
  }

  Widget _buildQuickAccessSection(
    BuildContext context,
    List<HomeQuickAccessItem> items,
  ) {
    return QuickAccessGrid(
      items: items
          .map(
            (e) => QuickAccessItem(
              title: e.title,
              icon: _getIconForName(e.icon),
              onTap: () => _handleQuickAccessTap(context, e),
            ),
          )
          .toList(),
    );
  }

  IconData _getIconForName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'dumbbell':
      case 'exercise':
        return Icons.fitness_center;
      case 'nutrition':
      case 'apple':
        return Icons.restaurant;
      case 'calendar':
      case 'appointments':
        return Icons.calendar_today_outlined;
      case 'heart':
      case 'health':
        // For custom images, QuickAccessItem uses imagePath if available.
        // Here we return an icon, but if we want images we need to map IDs/icons to asset paths.
        // The API returns "icon": "dumbbell".
        // QuickAccessItem accepts icon OR imagePath.
        // Let's try to map to assets if they match known ones to keep UI consistent.
        return Icons.favorite_outline;
      default:
        return Icons.grid_view;
    }
  }

  void _handleQuickAccessTap(BuildContext context, HomeQuickAccessItem item) {
    final titleLower = item.title.toLowerCase();
    final idLower = item.id.toLowerCase();

    if (idLower.contains('insight') || titleLower.contains('insight')) {
      context.push('/quick-health', extra: {'initialTabIndex': 3}); // Route to Insights tab
      return;
    }

    if (idLower.contains('exercise') || titleLower.contains('exercise')) {
      context.push('/quick-health');
      return;
    }

    if (idLower.contains('nutrition') || titleLower.contains('nutrition')) {
      context.push('/quick-health', extra: {'initialTabIndex': 1}); // Route to Diet tab
      return;
    }

    if (idLower.contains('appointment') || titleLower.contains('appointment')) {
      context.go('/appointments');
      return;
    }

    if (idLower.contains('health') || titleLower.contains('health')) {
      context.push('/quick-health');
      return;
    }

    switch (item.id) {
      case 'daily-exercise':
        context.push('/quick-health');
        break;
      case 'daily-nutrition':
        context.push('/quick-health', extra: {'initialTabIndex': 1});
        break;
      case 'appointments':
        context.go('/appointments');
        break;
      case 'health-insight':
        context.push('/quick-health', extra: {'initialTabIndex': 3});
        break;
      default:
        // Handle unknown or show toast
        break;
    }
  }
}

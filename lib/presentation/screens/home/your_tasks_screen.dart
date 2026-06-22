import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../../providers/phase_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/core_providers.dart';
import '../../../data/models/phase_model.dart';
import '../../../domain/usecases/phase/phase_usecases.dart';
import 'package:flutter_svg/flutter_svg.dart';

class YourTasksScreen extends ConsumerStatefulWidget {
  final String programName;
  final String programDescription;
  final String phaseId;
  final bool isActive;

  const YourTasksScreen({
    super.key,
    required this.programName,
    required this.programDescription,
    required this.phaseId,
    required this.isActive,
  });

  @override
  ConsumerState<YourTasksScreen> createState() => _YourTasksScreenState();
}



class _YourTasksScreenState extends ConsumerState<YourTasksScreen> {
  int _durationWeeks = 1;
  bool _isLoadingPhase = true;

  bool _isValidField(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final lower = value.trim().toLowerCase();
    return lower != 'n_a' && lower != 'n/a' && lower != 'null';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      final getPhaseByIdUseCase = ref.read(getPhaseByIdUseCaseProvider);
      final phaseResult = await getPhaseByIdUseCase(PhaseByIdParams(widget.phaseId));
      
      phaseResult.fold(
        (failure) {
           if (mounted) setState(() => _isLoadingPhase = false);
        },
        (phaseData) {
           if (mounted) {
             setState(() {
               _durationWeeks = phaseData.durationWeeks;
               _isLoadingPhase = false;
             });
           }
           
           if (widget.isActive) {
             ref.read(weeklyViewProvider.notifier).fetchCurrentWeek();
           } else {
             final phaseTasks = phaseData.phaseTasks;
             int weekNumber = phaseTasks.isNotEmpty ? phaseTasks.first.weekNumberGlobal : 1;
             ref.read(weeklyViewProvider.notifier).fetchWeekByNumber(weekNumber);
           }
        }
      );
    } catch (e) {
      if (mounted) setState(() => _isLoadingPhase = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeklyViewState = ref.watch(weeklyViewProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF9F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Your Tasks',
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, base: 16),
            fontWeight: FontWeight.w400,
            color: const Color(0xFF17110D),
          ),
        ),
        centerTitle: true,
      ),
      body: weeklyViewState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (weeklyView) {
          final pendingTasks = weeklyView.tasks.where((t) => t.legacyStatus == 'PENDING').toList();
          final completedTasks = weeklyView.tasks.where((t) => t.legacyStatus == 'COMPLETED').toList();

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getHorizontalPadding(context),
              vertical: ResponsiveUtils.spacing(context, base: 20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(context),
                SizedBox(height: ResponsiveUtils.spacing(context, base: 24)),
                _buildCurrentPhaseWeekCard(context, weeklyView),
                SizedBox(height: ResponsiveUtils.spacing(context, base: 16)),
                _buildWeekNavigation(context, weeklyView),
                if (pendingTasks.isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, base: 24)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Action Required',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, base: 16),
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF17110D),
                        ),
                      ),
                      const Icon(Icons.error_outline, color: Color(0xFF964A38), size: 20),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, base: 16)),
                  ...pendingTasks.map((t) => Padding(
                        padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, base: 12)),
                        child: _buildPendingTaskCard(context, t),
                      )),
                ],
                if (completedTasks.isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, base: 24)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Completed Tasks',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, base: 16),
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF17110D),
                        ),
                      ),
                      const Icon(Icons.check_circle_outline, color: Color(0xFF438A7A), size: 20),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, base: 16)),
                  ...completedTasks.map((t) => Padding(
                        padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, base: 12)),
                        child: _buildCompletedTaskCard(context, t),
                      )),
                ],
                SizedBox(height: ResponsiveUtils.spacing(context, base: 40)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, base: 20)),
      decoration: BoxDecoration(
        color: const Color(0xFF6B3528),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.self_improvement,
                  color: Color(0xFF6B3528),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.programName,
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.fontSize(context, base: 18),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.programDescription,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: ResponsiveUtils.fontSize(context, base: 14),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPhaseWeekCard(BuildContext context, WeeklyViewModel weeklyView) {
    if (_isLoadingPhase) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, base: 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DCD8), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isValidField(weeklyView.phaseName) ? weeklyView.phaseName : widget.programName,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, base: 16),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF17110D),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, base: 4)),
              Text(
                'Week: ${weeklyView.weekInPhase}/$_durationWeeks',
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, base: 14),
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF735B4D),
                ),
              ),
            ],
          ),
          if (widget.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF964A38),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Active',
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, base: 12),
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigation(BuildContext context, WeeklyViewModel weeklyView) {
    if (_isLoadingPhase) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, base: 16),
        vertical: ResponsiveUtils.spacing(context, base: 12),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: weeklyView.weekInPhase > 1,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: IconButton(
              icon: const Icon(Icons.arrow_left, color: Color(0xFF6B3528)),
              onPressed: () {
                final weekNumber = weeklyView.currentWeekGlobal - 1;
                if (weekNumber >= 1) {
                  ref.read(weeklyViewProvider.notifier).fetchWeekByNumber(weekNumber);
                }
              },
            ),
          ),
          Text(
            'Week: ${weeklyView.weekInPhase}/$_durationWeeks',
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, base: 14),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF17110D),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return ListView.builder(
                    itemCount: _durationWeeks,
                    itemBuilder: (context, index) {
                      final inputValue = index + 1;
                      return ListTile(
                        title: Text('Week $inputValue'),
                        onTap: () {
                          Navigator.pop(context);
                          if (inputValue == weeklyView.weekInPhase) return;
                          
                          int weekNumber;
                          if (inputValue < weeklyView.weekInPhase) {
                            weekNumber = weeklyView.currentWeekGlobal - (weeklyView.weekInPhase - inputValue);
                          } else {
                            weekNumber = weeklyView.currentWeekGlobal + (inputValue - weeklyView.weekInPhase);
                          }
                          
                          ref.read(weeklyViewProvider.notifier).fetchWeekByNumber(weekNumber);
                        },
                      );
                    },
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5DCD8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${weeklyView.weekInPhase}',
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, base: 14),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B3528),
                ),
              ),
            ),
          ),
          Visibility(
            visible: weeklyView.weekInPhase < _durationWeeks,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: IconButton(
              icon: const Icon(Icons.arrow_right, color: Color(0xFF6B3528)),
              onPressed: () {
                final weekNumber = weeklyView.currentWeekGlobal + 1;
                if (weeklyView.weekInPhase < _durationWeeks) {
                  ref.read(weeklyViewProvider.notifier).fetchWeekByNumber(weekNumber);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the same confirmation dialog as the home screen for selecting a task status.
  void _showTaskStatusDialog(BuildContext context, PatientTaskModel task, List<String> options) {
    final title = task.taskName.isNotEmpty ? task.taskName : (task.phaseTask?.title ?? 'Update Status');
    String selectedOption = options.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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
                          if (val != null) setDialogState(() => selectedOption = val);
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

                    final error = await ref.read(activePhaseTaskProvider.notifier).updateStatus(task.id, selectedOption);

                    rootNavigator.pop(); // dismiss loader

                    if (error == null) {
                      ref.read(activePhaseProvider.notifier).fetchActivePhase();
                      ref.refresh(homeDashboardProvider.future);
                      final currentWeek = ref.read(weeklyViewProvider).value?.currentWeekGlobal;
                      if (currentWeek != null) {
                        ref.read(weeklyViewProvider.notifier).fetchWeekByNumber(currentWeek);
                      } else {
                        ref.read(weeklyViewProvider.notifier).fetchCurrentWeek();
                      }
                      messenger.showSnackBar(const SnackBar(content: Text('Status updated successfully')));
                    } else {
                      messenger.showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
                  child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPendingTaskCard(BuildContext context, PatientTaskModel task) {
    final options = task.statusOptions.isNotEmpty ? task.statusOptions : (task.phaseTask?.statusOptions ?? []);
    final isBooleanOptions = options.isNotEmpty && options.every((o) => ['yes', 'no', 'true', 'false'].contains(o.toLowerCase()));

    return GestureDetector(
      onTap: () async {
        if (task.taskType == 'QUESTIONNAIRE') {
          if (isBooleanOptions) {
            // Show same popup dialog as home screen
            _showTaskStatusDialog(context, task, options);
            return;
          }

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          );

          try {
            final response = await ref.read(apiClientProvider).getTaskById(task.id);
            if (context.mounted) {
              Navigator.of(context).pop(); // dismiss loading
            }

            if (response.success && response.data != null) {
              final fullTask = response.data!;
              final qId = fullTask.phaseTask?.questionnaireId;

              if (qId != null && qId.isNotEmpty) {
                if (context.mounted) {
                  await context.push('/questionnaire/$qId/${task.id}');
                  if (context.mounted) {
                    // Refresh active phase + home dashboard so progress bar updates
                    ref.read(activePhaseProvider.notifier).fetchActivePhase();
                    ref.refresh(homeDashboardProvider.future);
                    final currentWeek = ref.read(weeklyViewProvider).value?.currentWeekGlobal;
                    if (currentWeek != null) {
                      ref.read(weeklyViewProvider.notifier).fetchWeekByNumber(currentWeek);
                    } else {
                      ref.read(weeklyViewProvider.notifier).fetchCurrentWeek();
                    }
                  }
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Questionnaire ID not found for this task')),
                  );
                }
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(response.message ?? 'Failed to fetch task details')),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.of(context).pop(); // dismiss loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error fetching task: $e')),
              );
            }
          }
        } else if (task.taskType == 'APPOINTMENT') {
          if (options.isNotEmpty) {
            // Show popup dialog for appointment status selection
            _showTaskStatusDialog(context, task, options);
          }
        } else {
          if (options.isNotEmpty) {
            // Show popup dialog for any other task type with options (replaces inline toggles)
            _showTaskStatusDialog(context, task, options);
          } else {
            await context.push('/task/${task.id}');
            if (context.mounted) {
              // Refresh active phase + home dashboard so progress bar updates
              ref.read(activePhaseProvider.notifier).fetchActivePhase();
              ref.refresh(homeDashboardProvider.future);
              final currentWeek = ref.read(weeklyViewProvider).value?.currentWeekGlobal;
              if (currentWeek != null) {
                ref.read(weeklyViewProvider.notifier).fetchWeekByNumber(currentWeek);
              } else {
                ref.read(weeklyViewProvider.notifier).fetchCurrentWeek();
              }
            }
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, base: 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5DCD8), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isValidField(task.taskName) ? task.taskName : 'Task',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, base: 16),
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF17110D),
                    ),
                  ),
                  if (_isValidField(task.practitioner)) ...[
                    SizedBox(height: ResponsiveUtils.spacing(context, base: 4)),
                    Text(
                      task.practitioner,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, base: 14),
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF735B4D),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF6ECE9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF6B3528),
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedTaskCard(BuildContext context, PatientTaskModel task) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, base: 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DCD8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isValidField(task.taskName) ? task.taskName : 'Task',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, base: 16),
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF17110D),
                      ),
                    ),
                    if (_isValidField(task.practitioner)) ...[
                      SizedBox(height: ResponsiveUtils.spacing(context, base: 4)),
                      Text(
                        task.practitioner,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, base: 14),
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF735B4D),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.check_circle,
                color: Color(0xFF438A7A), // Greenish completed color
                size: 24,
              ),
            ],
          ),
          if (task.statusOptions.isNotEmpty && task.taskType == 'APPOINTMENT') ...[
             SizedBox(height: ResponsiveUtils.spacing(context, base: 16)),
             Row(
                children: task.statusOptions.where((opt) => opt == task.statusValue).map((opt) {
                   final isSelected = true; // since we pre-filtered, it is true
                   return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6B3528) : Colors.white,
                        border: Border.all(color: isSelected ? const Color(0xFF6B3528) : const Color(0xFFDFDFDF)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        opt,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF735B4D),
                          fontSize: ResponsiveUtils.fontSize(context, base: 14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                   );
                }).toList(),
             ),
          ] else if (task.taskType == 'QUESTIONNAIRE') ...[
             SizedBox(height: ResponsiveUtils.spacing(context, base: 12)),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EE),
                  borderRadius: BorderRadius.circular(8),
               ),
               child: Text(
                  'Done',
                  style: TextStyle(
                     color: const Color(0xFF438A7A),
                     fontSize: ResponsiveUtils.fontSize(context, base: 12),
                     fontWeight: FontWeight.w500,
                  ),
               ),
             ),
          ] else ...[
              // Fallback for visual indicator toggles like Low/Partially/Fully
               if (task.statusOptions.isNotEmpty && task.visualIndicator == 'toggle') ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, base: 16)),
                  Row(
                    children: task.statusOptions.map((opt) {
                      final isSelected = opt == task.statusValue;
                      return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6B3528) : Colors.white,
                            border: Border.all(color: isSelected ? const Color(0xFF6B3528) : const Color(0xFFDFDFDF)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            opt,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF735B4D),
                              fontSize: ResponsiveUtils.fontSize(context, base: 14),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      );
                    }).toList(),
                  ),
               ]
          ]
        ],
      ),
    );
  }
}

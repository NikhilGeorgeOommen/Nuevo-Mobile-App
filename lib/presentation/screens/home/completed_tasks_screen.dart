import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/phase_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/home_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/home/task_card.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../../domain/entities/task.dart' as entities;
import '../../../data/models/phase_model.dart';

class CompletedTasksScreen extends ConsumerWidget {
  /// When [showCompleted] is true, shows tasks where isCompleted == true.
  /// When false, shows tasks where isCompleted == false (Action Required).
  final bool showCompleted;

  const CompletedTasksScreen({super.key, this.showCompleted = true});

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
                    final rootNavigator = Navigator.of(ctx, rootNavigator: true);
                    final messenger = ScaffoldMessenger.of(ctx);
                    
                    Navigator.of(ctx).pop(); 
                    
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const PopScope(
                        canPop: false,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                    
                    final error = await ref.read(activePhaseTaskProvider.notifier).updateStatus(pTask.id, selectedOption);
                    
                    rootNavigator.pop(); 
                    
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePhaseState = ref.watch(activePhaseProvider);

    final String title = showCompleted ? 'Completed Tasks' : 'Action Required';
    final String emptyMessage =
        showCompleted ? 'No completed tasks yet' : 'No pending actions';
    final IconData emptyIcon =
        showCompleted ? Icons.check_circle_outline : Icons.task_alt_outlined;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F8),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF17110D),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF17110D)),
          onPressed: () => context.pop(),
        ),
      ),
      body: activePhaseState.when(
        data: (activePhase) {
          final patientTasks = activePhase.tasks.where((t) {
            final isTCompleted = t.legacyStatus == 'COMPLETED' || t.status == 'COMPLETED';
            return isTCompleted == showCompleted;
          }).toList();

          final tasks = patientTasks.map(_mapPatientTaskToEntity).toList();

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    emptyIcon,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, base: 20)),
            itemCount: tasks.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: ResponsiveUtils.spacing(context, base: 12)),
            itemBuilder: (context, index) {
              return TaskCard(
                task: tasks[index],
                width: double.infinity,
                onTap: tasks[index].isCompleted ? null : () async {
                  final pTask = patientTasks[index];
                  final type = (pTask.taskType.isNotEmpty ? pTask.taskType : (pTask.phaseTask?.taskType ?? '')).toUpperCase();
                  final options = pTask.statusOptions.isNotEmpty ? pTask.statusOptions : (pTask.phaseTask?.statusOptions ?? []);
                  final isBooleanOptions = options.isNotEmpty && options.every((o) => ['yes', 'no', 'true', 'false'].contains(o.toLowerCase()));
                  
                  if (type == 'QUESTIONNAIRE') {
                    if (isBooleanOptions) {
                      _showTaskStatusDialog(context, ref, pTask, options);
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const Center(child: CircularProgressIndicator()),
                    );
                    
                    // Yield the frame to ensure the dialog is fully pushed before popping
                    await Future.delayed(const Duration(milliseconds: 100));
                    
                    try {
                      final response = await ref.read(apiClientProvider).getTaskById(pTask.id);
                      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                      
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
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Questionnaire ID not found for this task')),
                          );
                        }
                      } else {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(response.message ?? 'Failed to fetch task details')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error fetching task: $e')),
                        );
                      }
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref.read(activePhaseProvider.notifier).fetchActivePhase(),
        ),
      ),
    );
  }
}

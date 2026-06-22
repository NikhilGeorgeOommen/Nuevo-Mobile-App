import '../../../domain/entities/home/home_dashboard.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/entities/wellness_program.dart';
import '../wellness_program_model.dart';
import 'welcome_data_model.dart';
import 'wellness_progress_model.dart';
import 'quick_stats_model.dart';
import 'home_quick_access_item_model.dart';

class HomeDashboardModel extends HomeDashboard {
  const HomeDashboardModel({
    required super.welcome,
    required super.wellnessProgress,
    required super.quickStats,
    required super.actionRequired,
    required super.tasksCompleted,
    super.yourProgram,
    required super.quickAccess,
  });

  factory HomeDashboardModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> 
        ? json['data'] as Map<String, dynamic> 
        : <String, dynamic>{};

    return HomeDashboardModel(
      welcome: data['welcome'] is Map<String, dynamic>
          ? WelcomeDataModel.fromJson(data['welcome'] as Map<String, dynamic>)
          : const WelcomeDataModel(firstName: 'User', lastName: '', greeting: 'Welcome'),
      wellnessProgress: data['wellnessProgress'] is Map<String, dynamic>
          ? WellnessProgressModelResponse.fromJson(data['wellnessProgress'] as Map<String, dynamic>)
          : const WellnessProgressModelResponse(
              phaseName: 'Wellness Phase',
              subtitle: "Let's get started",
              progressPercent: 0,
              currentStep: '',
            ),
      quickStats: data['quickStats'] is Map<String, dynamic>
          ? QuickStatsModel.fromJson(data['quickStats'] as Map<String, dynamic>)
          : const QuickStatsModel(),
      actionRequired: data['actionRequired'] is List
          ? (data['actionRequired'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => _parseTask(e))
              .toList()
          : [],
      tasksCompleted: data['tasksCompleted'] is List
          ? (data['tasksCompleted'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => _parseTask(e))
              .toList()
          : [],
      yourProgram: data['yourProgram'] is Map<String, dynamic>
          ? WellnessProgramModel.fromJson(data['yourProgram'] as Map<String, dynamic>).toEntity()
          : null,
      quickAccess: data['quickAccess'] is List
          ? (data['quickAccess'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => HomeQuickAccessItemModel.fromJson(e))
              .toList()
          : [],
    );
  }

  static Task _parseTask(Map<String, dynamic> json) {
    // Parse duration string "5 minutes" to int 5
    int duration = 0;
    if (json['duration'] != null) {
      final durationStr = json['duration'].toString();
      final digits =  durationStr.replaceAll(RegExp(r'[^0-9]'), '');
      duration = int.tryParse(digits) ?? 0;
    }

    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Task',
      description: '', // Not in API
      durationMinutes: duration,
      imageUrl: json['thumbnail'],
      isCompleted: (json['status'] as String?)?.toLowerCase() == 'completed',
      type: TaskType.general, // Default as not in API
      dueDate: null,
      completedAt: null,
    );
  }

  HomeDashboard toEntity() {
    return this;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/repositories/health_repository_impl.dart';
import '../../domain/repositories/health_repository.dart';
import '../../data/models/daily_exercise_model.dart';
import '../../data/models/weekly_schedule_model.dart';
import '../../data/models/session_progress_model.dart';
import '../../data/models/active_progress_model.dart';
import 'core_providers.dart';
import '../../data/models/api_response.dart';
import '../../data/models/lab_report_model.dart';
import '../../data/models/lab_request_model.dart';
import '../../domain/models/health/patient_habit_history.dart';
import 'auth_provider.dart';
import 'auth_state.dart';

// Provider for HealthRepository
final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final apiClient = ApiClient(dioClient: dioClient);
  return HealthRepositoryImpl(apiClient);
});

// FutureProvider for Today's Exercise
final todayExerciseProvider = FutureProvider<DailyExerciseModel?>((ref) async {
  final repository = ref.watch(healthRepositoryProvider);
  final result = await repository.getTodayExercise();
  
  return result.fold(
    (failure) => throw failure.message,
    (data) => data,
  );
});

// FutureProvider for Weekly Schedule
final weeklyScheduleProvider = FutureProvider<WeeklyScheduleModel?>((ref) async {
  final repository = ref.watch(healthRepositoryProvider);
  final result = await repository.getWeeklySchedule();
  
  return result.fold(
    (failure) => throw failure.message,
    (data) => data,
  );
});

// FutureProvider.family for Session Details
final sessionDetailsProvider = FutureProvider.family<GuidedSessionModel?, String>((ref, id) async {
  final repository = ref.watch(healthRepositoryProvider);
  final result = await repository.getSessionDetails(id);
  
  return result.fold(
    (failure) => throw failure.message,
    (data) => data,
  );
});

// FutureProvider.family for Start Session
final startSessionProvider = FutureProvider.family<SessionProgressModel?, String>((ref, id) async {
  final repository = ref.watch(healthRepositoryProvider);
  final result = await repository.startSession(id);
  
  return result.fold(
    (failure) => throw failure.message,
    (data) => data,
  );
});

// FutureProvider.family for Complete Session
final completeSessionProvider = FutureProvider.family<ApiResponse<SessionProgressModel>?, String>((ref, id) async {
  final repository = ref.watch(healthRepositoryProvider);
  final result = await repository.completeSession(id);

  return result.fold(
    (failure) => throw failure.message,
    (data) => data,
  );
});

// FutureProvider.family for Sync Session Progress
final syncSessionProgressProvider = FutureProvider.family<SessionProgressModel?, Map<String, dynamic>>((ref, params) async {
  final repository = ref.watch(healthRepositoryProvider);
  final id = params['id'] as String;
  final data = params['data'] as Map<String, dynamic>;
  final result = await repository.syncSessionProgress(id, data);

  return result.fold(
    (failure) => throw failure.message,
    (data) => data,
  );
});

// FutureProvider for Active Progress
final activeProgressProvider = FutureProvider.autoDispose<ActiveProgressModel?>((ref) async {
  final repository = ref.watch(healthRepositoryProvider);
  final result = await repository.getActiveProgress();
  
  return result.fold(
    (failure) => throw failure.message,
    (data) => data,
  );
});

// FutureProvider.family for Lab Report Details / Comparison
// We return LabReportDetailData so we have access to .parameters and .comparison
final labReportDetailsProvider = FutureProvider.family<LabReportDetailData?, String>((ref, id) async {
  final repository = ref.watch(healthRepositoryProvider);
  final result = await repository.getLabReportDetails(id);
  
  return result.fold(
    (failure) => throw failure.message,
    (data) => data,
  );
});

// FutureProvider.family for creating Lab Requests
final createLabRequestProvider = FutureProvider.family<LabRequestData?, String>((ref, notes) async {
  final repository = ref.watch(healthRepositoryProvider);
  final result = await repository.createLabRequest(notes);
  
  return result.fold(
    (failure) => throw failure.message,
    (data) => data,
  );
});

// FutureProvider.family for Patient Habit History
final patientHabitHistoryProvider = FutureProvider.family<PatientHabitHistory?, String>((ref, date) async {
  final repository = ref.watch(healthRepositoryProvider);
  final result = await repository.getPatientHabitHistory(date);
  
  return result.fold(
    (failure) => throw failure.message,
    (data) => data,
  );
});

// FutureProvider for All Patient Habit History
final patientHabitHistoryListProvider = FutureProvider<List<PatientHabitHistory>>((ref) async {
  final repository = ref.watch(healthRepositoryProvider);
  final result = await repository.getAllPatientHabitHistory();
  
  return result.fold(
    (failure) => throw failure.message,
    (data) => data,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/phase_model.dart';
import '../../domain/entities/phase.dart';
import '../../domain/usecases/usecase.dart';
import '../../domain/usecases/phase/phase_usecases.dart';
import 'core_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PhaseListNotifier — All Phases List (existing, preserved)
// ─────────────────────────────────────────────────────────────────────────────

class PhaseListNotifier extends StateNotifier<AsyncValue<List<Phase>>> {
  final Ref _ref;

  PhaseListNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> fetchPhases() async {
    state = const AsyncValue.loading();
    final getPhasesUseCase = _ref.read(getPhasesUseCaseProvider);
    final result = await getPhasesUseCase(const NoParams());

    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (phases) {
        final sortedPhases = List<Phase>.from(phases)
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        state = AsyncValue.data(sortedPhases);
      },
    );
  }
}

final phaseListProvider =
    StateNotifierProvider<PhaseListNotifier, AsyncValue<List<Phase>>>((ref) {
  return PhaseListNotifier(ref);
});

// ─────────────────────────────────────────────────────────────────────────────
// ActivePhaseNotifier — GET /phases/my-active-phase
// ─────────────────────────────────────────────────────────────────────────────

class ActivePhaseNotifier
    extends StateNotifier<AsyncValue<ActivePhaseResponseModel>> {
  final Ref _ref;
  bool hasInitiatedFetch = false;

  ActivePhaseNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> fetchActivePhase() async {
    hasInitiatedFetch = true;
    state = const AsyncValue.loading();
    final useCase = _ref.read(getMyActivePhaseUseCaseProvider);
    final result = await useCase(const NoParams());

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (data) => state = AsyncValue.data(data),
    );
  }
}

final activePhaseProvider = StateNotifierProvider<ActivePhaseNotifier,
    AsyncValue<ActivePhaseResponseModel>>((ref) {
  return ActivePhaseNotifier(ref);
});

// ─────────────────────────────────────────────────────────────────────────────
// WeeklyViewNotifier — GET /phases/my-active-phase/weekly
// ─────────────────────────────────────────────────────────────────────────────

class WeeklyViewNotifier extends StateNotifier<AsyncValue<WeeklyViewModel>> {
  final Ref _ref;

  WeeklyViewNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> fetchCurrentWeek() async {
    state = const AsyncValue.loading();
    final useCase = _ref.read(getCurrentWeeklyViewUseCaseProvider);
    final result = await useCase(const NoParams());

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (data) => state = AsyncValue.data(data),
    );
  }

  Future<void> fetchWeekByNumber(int weekNumber) async {
    state = const AsyncValue.loading();
    final useCase = _ref.read(getWeekByNumberUseCaseProvider);
    final result = await useCase(WeekNumberParams(weekNumber));

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (data) => state = AsyncValue.data(data),
    );
  }
}

final weeklyViewProvider = StateNotifierProvider<WeeklyViewNotifier,
    AsyncValue<WeeklyViewModel>>((ref) {
  return WeeklyViewNotifier(ref);
});

// ─────────────────────────────────────────────────────────────────────────────
// PhaseProgressNotifier — GET /phases/my-active-phase/progress
// ─────────────────────────────────────────────────────────────────────────────

class PhaseProgressNotifier
    extends StateNotifier<AsyncValue<PhaseProgressModel>> {
  final Ref _ref;

  PhaseProgressNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> fetchProgress() async {
    state = const AsyncValue.loading();
    final useCase = _ref.read(getPhaseProgressUseCaseProvider);
    final result = await useCase(const NoParams());

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (data) => state = AsyncValue.data(data),
    );
  }
}

final phaseProgressProvider = StateNotifierProvider<PhaseProgressNotifier,
    AsyncValue<PhaseProgressModel>>((ref) {
  return PhaseProgressNotifier(ref);
});

// ─────────────────────────────────────────────────────────────────────────────
// ActivePhaseTaskNotifier — GET / PATCH task operations
// ─────────────────────────────────────────────────────────────────────────────

class ActivePhaseTaskNotifier
    extends StateNotifier<AsyncValue<PatientTaskModel?>> {
  final Ref _ref;

  ActivePhaseTaskNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> fetchTask(String taskId) async {
    state = const AsyncValue.loading();
    final useCase = _ref.read(getTaskByIdUseCaseProvider);
    final result = await useCase(TaskIdParams(taskId));

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (data) => state = AsyncValue.data(data),
    );
  }

  // Future<bool> markCompleted(String taskId) async {
  //   final useCase = _ref.read(markTaskCompletedUseCaseProvider);
  //   final result = await useCase(TaskIdParams(taskId));
  //
  //   return result.fold(
  //     (failure) => false,
  //     (data) {
  //       state = AsyncValue.data(data);
  //       return true;
  //     },
  //   );
  // }

  Future<String?> updateStatus(String taskId, String statusValue) async {
    final useCase = _ref.read(updateTaskStatusUseCaseProvider);
    final result = await useCase(
        UpdateTaskStatusParams(taskId: taskId, statusValue: statusValue));

    return result.fold(
      (failure) => failure.message,
      (data) {
        state = AsyncValue.data(data);
        return null;
      },
    );
  }
}

final activePhaseTaskProvider = StateNotifierProvider<ActivePhaseTaskNotifier,
    AsyncValue<PatientTaskModel?>>((ref) {
  return ActivePhaseTaskNotifier(ref);
});

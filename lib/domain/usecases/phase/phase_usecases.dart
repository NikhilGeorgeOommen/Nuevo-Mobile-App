import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/phase_repository.dart';
import '../../../data/models/phase_model.dart';
import '../usecase.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GetPhaseByIdUseCase
// ─────────────────────────────────────────────────────────────────────────────

class PhaseByIdParams {
  final String phaseId;
  const PhaseByIdParams(this.phaseId);
}

class GetPhaseByIdUseCase implements UseCase<PhaseModel, PhaseByIdParams> {
  final PhaseRepository repository;
  GetPhaseByIdUseCase(this.repository);

  @override
  Future<Either<Failure, PhaseModel>> call(PhaseByIdParams params) =>
      repository.getPhaseById(params.phaseId);
}

// ─────────────────────────────────────────────────────────────────────────────
// GetMyActivePhaseUseCase
// ─────────────────────────────────────────────────────────────────────────────

class GetMyActivePhaseUseCase
    implements UseCase<ActivePhaseResponseModel, NoParams> {
  final PhaseRepository repository;
  GetMyActivePhaseUseCase(this.repository);

  @override
  Future<Either<Failure, ActivePhaseResponseModel>> call(NoParams _) =>
      repository.getMyActivePhase();
}

// ─────────────────────────────────────────────────────────────────────────────
// GetCurrentWeeklyViewUseCase
// ─────────────────────────────────────────────────────────────────────────────

class GetCurrentWeeklyViewUseCase
    implements UseCase<WeeklyViewModel, NoParams> {
  final PhaseRepository repository;
  GetCurrentWeeklyViewUseCase(this.repository);

  @override
  Future<Either<Failure, WeeklyViewModel>> call(NoParams _) =>
      repository.getCurrentWeeklyView();
}

// ─────────────────────────────────────────────────────────────────────────────
// GetPhaseProgressUseCase
// ─────────────────────────────────────────────────────────────────────────────

class GetPhaseProgressUseCase implements UseCase<PhaseProgressModel, NoParams> {
  final PhaseRepository repository;
  GetPhaseProgressUseCase(this.repository);

  @override
  Future<Either<Failure, PhaseProgressModel>> call(NoParams _) =>
      repository.getPhaseProgress();
}

// ─────────────────────────────────────────────────────────────────────────────
// GetWeekByNumberUseCase
// ─────────────────────────────────────────────────────────────────────────────

class WeekNumberParams {
  final int weekNumber;
  const WeekNumberParams(this.weekNumber);
}

class GetWeekByNumberUseCase
    implements UseCase<WeeklyViewModel, WeekNumberParams> {
  final PhaseRepository repository;
  GetWeekByNumberUseCase(this.repository);

  @override
  Future<Either<Failure, WeeklyViewModel>> call(WeekNumberParams params) =>
      repository.getWeekByNumber(params.weekNumber);
}

// ─────────────────────────────────────────────────────────────────────────────
// GetTaskByIdUseCase
// ─────────────────────────────────────────────────────────────────────────────

class TaskIdParams {
  final String taskId;
  const TaskIdParams(this.taskId);
}

class GetTaskByIdUseCase implements UseCase<PatientTaskModel, TaskIdParams> {
  final PhaseRepository repository;
  GetTaskByIdUseCase(this.repository);

  @override
  Future<Either<Failure, PatientTaskModel>> call(TaskIdParams params) =>
      repository.getTaskById(params.taskId);
}

// // ─────────────────────────────────────────────────────────────────────────────
// // MarkTaskCompletedUseCase
// // ─────────────────────────────────────────────────────────────────────────────
//
// class MarkTaskCompletedUseCase
//     implements UseCase<PatientTaskModel, TaskIdParams> {
//   final PhaseRepository repository;
//   MarkTaskCompletedUseCase(this.repository);
//
//   @override
//   Future<Either<Failure, PatientTaskModel>> call(TaskIdParams params) =>
//       repository.markTaskCompleted(params.taskId);
// }

// ─────────────────────────────────────────────────────────────────────────────
// UpdateTaskStatusUseCase
// ─────────────────────────────────────────────────────────────────────────────

class UpdateTaskStatusParams {
  final String taskId;
  final String statusValue;
  const UpdateTaskStatusParams({required this.taskId, required this.statusValue});
}

class UpdateTaskStatusUseCase
    implements UseCase<PatientTaskModel, UpdateTaskStatusParams> {
  final PhaseRepository repository;
  UpdateTaskStatusUseCase(this.repository);

  @override
  Future<Either<Failure, PatientTaskModel>> call(
          UpdateTaskStatusParams params) =>
      repository.updateTaskStatus(params.taskId, params.statusValue);
}

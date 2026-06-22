import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/phase.dart';
import '../../data/models/phase_model.dart';

abstract class PhaseRepository {
  // ── Existing ──────────────────────────────────────────────────────────────
  Future<Either<Failure, List<Phase>>> getPhases();

  // ── New Phase APIs ─────────────────────────────────────────────────────────
  Future<Either<Failure, PhaseModel>> getPhaseById(String phaseId);
  Future<Either<Failure, ActivePhaseResponseModel>> getMyActivePhase();
  Future<Either<Failure, WeeklyViewModel>> getCurrentWeeklyView();
  Future<Either<Failure, PhaseProgressModel>> getPhaseProgress();
  Future<Either<Failure, WeeklyViewModel>> getWeekByNumber(int weekNumber);
  Future<Either<Failure, PatientTaskModel>> getTaskById(String taskId);
  // Future<Either<Failure, PatientTaskModel>> markTaskCompleted(String taskId);
  Future<Either<Failure, PatientTaskModel>> updateTaskStatus(
      String taskId, String statusValue);
}

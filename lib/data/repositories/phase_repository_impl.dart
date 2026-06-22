import '../../core/errors/exceptions.dart';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/phase.dart';
import '../../domain/repositories/phase_repository.dart';
import '../../data/models/phase_model.dart';
import '../datasources/remote/api_client.dart';

class PhaseRepositoryImpl implements PhaseRepository {
  final ApiClient apiClient;

  PhaseRepositoryImpl({required this.apiClient});

  // ── Existing ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Phase>>> getPhases() async {
    try {
      final response = await apiClient.getPhases();
      if (response.success) {
        return Right(response.data?.map((m) => m.toEntity()).toList() ?? []);
      } else {
        return Left(ServerFailure(response.message ?? 'Server error'));
      }
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── New Phase APIs ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, PhaseModel>> getPhaseById(String phaseId) async {
    try {
      final response = await apiClient.getPhaseById(phaseId);
      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(response.message ?? 'Server error'));
      }
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ActivePhaseResponseModel>> getMyActivePhase() async {
    try {
      final response = await apiClient.getMyActivePhase();
      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(response.message ?? 'Server error'));
      }
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WeeklyViewModel>> getCurrentWeeklyView() async {
    try {
      final response = await apiClient.getCurrentWeeklyView();
      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(response.message ?? 'Server error'));
      }
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PhaseProgressModel>> getPhaseProgress() async {
    try {
      final response = await apiClient.getPhaseProgress();
      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(response.message ?? 'Server error'));
      }
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WeeklyViewModel>> getWeekByNumber(
      int weekNumber) async {
    try {
      final response = await apiClient.getWeekByNumber(weekNumber);
      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(response.message ?? 'Server error'));
      }
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PatientTaskModel>> getTaskById(
      String taskId) async {
    try {
      final response = await apiClient.getTaskById(taskId);
      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(response.message ?? 'Server error'));
      }
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // @override
  // Future<Either<Failure, PatientTaskModel>> markTaskCompleted(
  //     String taskId) async {
  //   try {
  //     final response = await apiClient.markTaskCompleted(taskId);
  //     if (response.success && response.data != null) {
  //       return Right(response.data!);
  //     } else {
  //       return Left(ServerFailure(response.message ?? 'Server error'));
  //     }
  //   } on AppException catch (e) {
  //     return Left(ServerFailure(e.message));
  //   } catch (e) {
  //     return Left(ServerFailure(e.toString()));
  //   }
  // }

  @override
  Future<Either<Failure, PatientTaskModel>> updateTaskStatus(
      String taskId, String statusValue) async {
    try {
      final response = await apiClient.updateTaskStatus(taskId, statusValue);
      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(response.message ?? 'Server error'));
      }
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

import 'package:dartz/dartz.dart';
import '../../domain/entities/questionnaire.dart';
import '../../domain/repositories/questionnaire_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/remote/api_client.dart';
import 'package:dio/dio.dart';

class QuestionnaireRepositoryImpl implements QuestionnaireRepository {
  final ApiClient _apiClient;

  QuestionnaireRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Either<Failure, Questionnaire>> getQuestionnaire(String id) async {
    try {
      final response = await _apiClient.getQuestionnaire(id);
      if (response.success && response.data != null) {
        if (response.data is Map) {
          try {
            final mapData = Map<String, dynamic>.from(response.data as Map);
            return Right(Questionnaire.fromJson(mapData));
          } catch (e) {
            return Left(ServerFailure('Failed to parse questionnaire: $e'));
          }
        }
        return Left(ServerFailure('Invalid questionnaire data format'));
      } else {
        return Left(ServerFailure(response.message ?? 'Failed to parse questionnaire json'));
      }
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to fetch questionnaire'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitQuestionnaire(
      String patientTaskId, List<QuestionResponse> responses) async {
    try {
      final jsonResponses = responses.map((r) => r.toJson()).toList();
      final response = await _apiClient.submitQuestionnaire(patientTaskId, jsonResponses);
      if (response.success) {
        return const Right(null);
      } else {
        return Left(ServerFailure(response.message ?? 'Failed to submit questionnaire'));
      }
    } on DioException catch (e) {
      return Left(ServerFailure( e.message ?? 'Failed to submit questionnaire'));
    } catch (e) {
      return Left(ServerFailure( e.toString() ));
    }
  }
}

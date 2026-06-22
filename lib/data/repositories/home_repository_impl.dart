import '../../core/errors/exceptions.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/home/home_dashboard.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/home/home_dashboard_model.dart'; // Add this import

class HomeRepositoryImpl implements HomeRepository {
  final DioClient _client;

  HomeRepositoryImpl(this._client); // Assuming DioClient via DI or passed directly

  @override
  Future<Either<Failure, HomeDashboard>> getHomeDashboard() async {
    try {
      final response = await _client.get(ApiConstants.home);


      if (response.statusCode == 200 && response.data is Map && response.data['success'] == true) {
        try {
          final dashboardModel = HomeDashboardModel.fromJson(response.data);
          return Right(dashboardModel.toEntity());
        } catch (e, stackTrace) {
          return Left(ServerFailure('Failed to parse dashboard data: $e'));
        }
      } else {
        final message = response.data is Map ? response.data['message']?.toString() : null;
        return Left(ServerFailure(message ?? 'Failed to load dashboard'));
      }
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e, s) {

      return Left(UnknownFailure(message: e.toString()));
    }
  }
}

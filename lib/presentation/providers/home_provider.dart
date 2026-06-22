import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/home/home_dashboard.dart';
import '../../domain/repositories/home_repository.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/usecases/usecase.dart';
import '../../domain/usecases/home/get_home_dashboard_usecase.dart';
import '../../presentation/providers/core_providers.dart'; // Import core_providers
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/auth_state.dart';

/// Home Repository Provider
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return HomeRepositoryImpl(dioClient);
});

/// Get Home Dashboard UseCase Provider
final getHomeDashboardUseCaseProvider = Provider<GetHomeDashboardUseCase>((ref) {
  return GetHomeDashboardUseCase(ref.watch(homeRepositoryProvider));
});

/// Home Dashboard Provider
final homeDashboardProvider = FutureProvider<HomeDashboard>((ref) async {
  final getHomeDashboard = ref.watch(getHomeDashboardUseCaseProvider);
  final result = await getHomeDashboard(const NoParams());
  
  return result.fold(
    (failure) => throw failure.message,
    (dashboard) => dashboard,
  );
});

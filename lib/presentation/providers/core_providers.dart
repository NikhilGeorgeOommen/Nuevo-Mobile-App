import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasources/local/local_data_source.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/repositories/lab_repository_impl.dart';
import '../../data/repositories/specialist_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/lab_repository.dart';
import '../../domain/repositories/specialist_repository.dart';
import '../../domain/usecases/lab/create_lab_request_usecase.dart';
import '../../domain/usecases/lab/get_lab_requests_usecase.dart';
import '../../domain/usecases/lab/get_lab_request_by_id_usecase.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/refresh_token_usecase.dart';
import '../../domain/usecases/auth/send_otp_usecase.dart';
import '../../domain/usecases/auth/signup_usecase.dart';
import '../../domain/usecases/auth/verify_otp_usecase.dart';
import '../../domain/usecases/auth/forgot_password_usecase.dart';
import '../../domain/usecases/subscription/check_feature_access_usecase.dart';
import '../../domain/usecases/subscription/get_subscription_status_usecase.dart';
import '../../domain/usecases/subscription/is_subscription_active_usecase.dart';
import '../../domain/usecases/user/get_user_profile_usecase.dart';
import '../../domain/usecases/user/update_user_profile_usecase.dart';
import '../../domain/usecases/user/update_preferences_usecase.dart';
import '../../domain/usecases/user/update_preferences_usecase.dart';
import '../../domain/usecases/user/get_preferences_usecase.dart';
import '../../domain/usecases/specialist/get_my_specialists_usecase.dart';
import '../../domain/usecases/specialist/get_specialist_details_usecase.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../domain/usecases/goal/get_goals_usecase.dart';
import '../../domain/usecases/goal/create_goal_usecase.dart';
import '../../domain/usecases/goal/get_goal_by_id_usecase.dart';
import '../../domain/usecases/goal/update_goal_usecase.dart';
import '../../domain/usecases/goal/delete_goal_usecase.dart';
import '../../domain/usecases/phase/get_phases_usecase.dart';
import '../../domain/usecases/phase/phase_usecases.dart';
import '../../data/repositories/phase_repository_impl.dart';
import '../../domain/repositories/phase_repository.dart';
// import 'auth_provider.dart'; // Removing to break circularity

// ============================================
// Core Dependencies
// ============================================

/// A simple provider to signal that a logout should occur (e.g. on 401 unauthorized access)
/// This helps break circular dependencies between DioClient and AuthProvider
final logoutEventProvider = StateProvider<int>((ref) => 0);

/// Shared Preferences Provider
/// Must be overridden in main.dart:
/// ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)])
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

/// Flutter Secure Storage Provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
});

/// Dio Client Provider
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    getAccessToken: () async {
      try {
        final localDataSource = ref.read(localDataSourceProvider);
        return await localDataSource.getAccessToken();
      } catch (_) {
        return null;
      }
    },
    onUnauthorized: () {
      // Trigger logout event without directly depending on authProvider
      ref.read(logoutEventProvider.notifier).state++;
    },
  );
});

// ============================================
// Data Sources
// ============================================

/// Remote Data Source (API Client)
final apiClientProvider = Provider<ApiClient>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiClient(dioClient: dioClient);
});

/// Local Data Source
final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return LocalDataSource(
    secureStorage: secureStorage,
    preferences: sharedPreferences,
  );
});

// ============================================
// Repositories
// ============================================

/// Auth Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localDataSource = ref.watch(localDataSourceProvider);
  return AuthRepositoryImpl(
    apiClient: apiClient,
    localDataSource: localDataSource,
  );
});

/// Subscription Repository
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SubscriptionRepositoryImpl(apiClient: apiClient);
});

/// User Repository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localDataSource = ref.watch(localDataSourceProvider);
  return UserRepositoryImpl(
    apiClient: apiClient,
    localDataSource: localDataSource,
  );
});

// ============================================
// Use Cases - Auth
// ============================================

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository: repository);
});

final sendOtpUseCaseProvider = Provider<SendOtpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendOtpUseCase(repository);
});

final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyOtpUseCase(repository);
});

final signupUseCaseProvider = Provider<SignupUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignupUseCase(repository: repository);
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository: repository);
});

final refreshTokenUseCaseProvider = Provider<RefreshTokenUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RefreshTokenUseCase(repository: repository);
});

final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ForgotPasswordUseCase(repository);
});

// ============================================
// Use Cases - Subscription
// ============================================

final getSubscriptionStatusUseCaseProvider = Provider<GetSubscriptionStatusUseCase>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return GetSubscriptionStatusUseCase(repository: repository);
});

final checkFeatureAccessUseCaseProvider = Provider<CheckFeatureAccessUseCase>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return CheckFeatureAccessUseCase(repository: repository);
});

final isSubscriptionActiveUseCaseProvider = Provider<IsSubscriptionActiveUseCase>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return IsSubscriptionActiveUseCase(repository: repository);
});

// ============================================
// Use Cases - User
// ============================================

final getUserProfileUseCaseProvider = Provider<GetUserProfileUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return GetUserProfileUseCase(repository: repository);
});

final updateUserProfileUseCaseProvider = Provider<UpdateUserProfileUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UpdateUserProfileUseCase(repository: repository);
});

final updatePreferencesUseCaseProvider = Provider<UpdatePreferencesUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UpdatePreferencesUseCase(repository);
});

final getPreferencesUseCaseProvider = Provider<GetPreferencesUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return GetPreferencesUseCase(repository);
});

// ============================================
// Repositories - Lab
// ============================================

final labRepositoryProvider = Provider<LabRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LabRepositoryImpl(apiClient: apiClient);
});

/// Specialist Repository
final specialistRepositoryProvider = Provider<SpecialistRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SpecialistRepositoryImpl(apiClient: apiClient);
});

/// Goal Repository
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GoalRepositoryImpl(apiClient: apiClient);
});

/// Phase Repository
final phaseRepositoryProvider = Provider<PhaseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PhaseRepositoryImpl(apiClient: apiClient);
});

// ============================================
// Use Cases - Lab
// ============================================

final createLabRequestUseCaseProvider = Provider<CreateLabRequestUseCase>((ref) {
  final repository = ref.watch(labRepositoryProvider);
  return CreateLabRequestUseCase(repository: repository);
});

final getLabRequestsUseCaseProvider = Provider<GetLabRequestsUseCase>((ref) {
  final repository = ref.watch(labRepositoryProvider);
  return GetLabRequestsUseCase(repository: repository);
});

final getLabRequestByIdUseCaseProvider =
    Provider<GetLabRequestByIdUseCase>((ref) {
  final repository = ref.watch(labRepositoryProvider);
  return GetLabRequestByIdUseCase(repository: repository);
});

// ============================================
// Use Cases - Specialist
// ============================================

final getMySpecialistsUseCaseProvider = Provider<GetMySpecialistsUseCase>((ref) {
  final repository = ref.watch(specialistRepositoryProvider);
  return GetMySpecialistsUseCase(repository);
});

final getSpecialistDetailsUseCaseProvider =
    Provider<GetSpecialistDetailsUseCase>((ref) {
  final repository = ref.watch(specialistRepositoryProvider);
  return GetSpecialistDetailsUseCase(repository);
});

// ============================================
// Use Cases - Goal
// ============================================

final getGoalsUseCaseProvider = Provider<GetGoalsUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GetGoalsUseCase(repository);
});

final createGoalUseCaseProvider = Provider<CreateGoalUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return CreateGoalUseCase(repository);
});

final getGoalByIdUseCaseProvider = Provider<GetGoalByIdUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GetGoalByIdUseCase(repository);
});

final updateGoalUseCaseProvider = Provider<UpdateGoalUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return UpdateGoalUseCase(repository);
});

final deleteGoalUseCaseProvider = Provider<DeleteGoalUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return DeleteGoalUseCase(repository);
});

// ============================================
// Use Cases - Phase
// ============================================

final getPhasesUseCaseProvider = Provider<GetPhasesUseCase>((ref) {
  final repository = ref.watch(phaseRepositoryProvider);
  return GetPhasesUseCase(repository);
});

final getPhaseByIdUseCaseProvider = Provider<GetPhaseByIdUseCase>((ref) {
  final repository = ref.watch(phaseRepositoryProvider);
  return GetPhaseByIdUseCase(repository);
});

final getMyActivePhaseUseCaseProvider =
    Provider<GetMyActivePhaseUseCase>((ref) {
  final repository = ref.watch(phaseRepositoryProvider);
  return GetMyActivePhaseUseCase(repository);
});

final getCurrentWeeklyViewUseCaseProvider =
    Provider<GetCurrentWeeklyViewUseCase>((ref) {
  final repository = ref.watch(phaseRepositoryProvider);
  return GetCurrentWeeklyViewUseCase(repository);
});

final getPhaseProgressUseCaseProvider =
    Provider<GetPhaseProgressUseCase>((ref) {
  final repository = ref.watch(phaseRepositoryProvider);
  return GetPhaseProgressUseCase(repository);
});

final getWeekByNumberUseCaseProvider =
    Provider<GetWeekByNumberUseCase>((ref) {
  final repository = ref.watch(phaseRepositoryProvider);
  return GetWeekByNumberUseCase(repository);
});

final getTaskByIdUseCaseProvider = Provider<GetTaskByIdUseCase>((ref) {
  final repository = ref.watch(phaseRepositoryProvider);
  return GetTaskByIdUseCase(repository);
});

// final markTaskCompletedUseCaseProvider =
//     Provider<MarkTaskCompletedUseCase>((ref) {
//   final repository = ref.watch(phaseRepositoryProvider);
//   return MarkTaskCompletedUseCase(repository);
// });

final updateTaskStatusUseCaseProvider =
    Provider<UpdateTaskStatusUseCase>((ref) {
  final repository = ref.watch(phaseRepositoryProvider);
  return UpdateTaskStatusUseCase(repository);
});

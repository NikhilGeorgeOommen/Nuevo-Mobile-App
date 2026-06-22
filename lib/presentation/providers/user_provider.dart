import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/usecase.dart';
import '../../domain/usecases/user/get_user_profile_usecase.dart';
import '../../domain/usecases/user/update_user_profile_usecase.dart';
import 'auth_provider.dart';
import 'auth_state.dart';
import 'core_providers.dart';

/// User Profile Notifier
/// Manages fetching and updating user profile
class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final GetUserProfileUseCase _getUserProfileUseCase;
  final UpdateUserProfileUseCase _updateUserProfileUseCase;
  final Ref _ref;

  UserNotifier(
    this._ref, {
    required GetUserProfileUseCase getUserProfile,
    required UpdateUserProfileUseCase updateUserProfile,
    User? initialUser,
  })  : _getUserProfileUseCase = getUserProfile,
        _updateUserProfileUseCase = updateUserProfile,
        super(initialUser != null ? AsyncValue.data(initialUser) : const AsyncValue.loading());

  /// Fetch User Profile
  Future<void> fetchProfile({bool isBackground = false}) async {
    if (!isBackground || state.value == null) {
       state = const AsyncValue.loading();
    }
    final result = await _getUserProfileUseCase(const NoParams());

    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (user) => state = AsyncValue.data(user),
    );
  }

  /// Update Profile
  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    String? dateOfBirth,
    double? height,
    double? weight,
  }) async {
    // Optimistic update or set loading
    state = const AsyncValue.loading(); 
    
    final result = await _updateUserProfileUseCase(UpdateProfileParams(
      name: name,
      phoneNumber: phoneNumber,
      profileImageUrl: profileImageUrl,
      dateOfBirth: dateOfBirth,
      height: height,
      weight: weight,
    ));
    
    result.fold(
      (failure) {
         // Handle error, maybe revert state if optimistic
         state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (user) => state = AsyncValue.data(user),
    );
  }
}

/// User Provider
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  // Watch auth state changes - fetch profile when authenticated
  final authState = ref.watch(authProvider);
  
  final notifier = UserNotifier(
    ref,
    getUserProfile: ref.watch(getUserProfileUseCaseProvider),
    updateUserProfile: ref.watch(updateUserProfileUseCaseProvider),
    initialUser: authState.user,
  );
  
  // Auto-fetch profile if we are authenticated but have no user, OR just to refresh
  if (authState.status == AuthStatus.authenticated) {
     if (authState.user == null) {
        Future.microtask(() => notifier.fetchProfile());
     } else {
        // Optionally, we could refresh in background here, but since authProvider 
        // JUST fetched it during checkLoginStatus(), doing it again immediately 
        // causes duplicate network calls. We rely on the initial auth data.
     }
  } else if (authState.status == AuthStatus.unauthenticated) {
    // Determine if we should clear state? UserNotifier is recreated anyway if authProvider changes
  }
  
  return notifier;
});

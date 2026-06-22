import 'package:dartz/dartz.dart';
import 'package:nuevo_app/core/errors/failures.dart';
import 'package:nuevo_app/domain/entities/preferences.dart';
import 'package:nuevo_app/domain/entities/user.dart';

/// User Repository Interface (Domain Layer)
/// Defines the contract for user profile operations
abstract class UserRepository {
  /// Get current user profile
  /// Returns User on success, Failure on error
  Future<Either<Failure, User>> getUserProfile();
  
  /// Update user profile
  /// Returns updated User on success, Failure on error
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    String? dateOfBirth,
    double? height,
    double? weight,
  });

  /// Update user preferences (Notification & Consent)
  /// Returns updated Preferences on success, Failure on error
  Future<Either<Failure, Preferences>> updatePreferences(Preferences preferences);

  /// Get user preferences
  /// Returns Preferences on success, Failure on error
  Future<Either<Failure, Preferences>> getPreferences();
}

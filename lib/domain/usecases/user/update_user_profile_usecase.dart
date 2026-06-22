import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:nuevo_app/core/errors/failures.dart';
import 'package:nuevo_app/domain/entities/user.dart';
import 'package:nuevo_app/domain/repositories/user_repository.dart';
import 'package:nuevo_app/domain/usecases/usecase.dart';

/// Update User Profile Use Case
/// Updates user's profile information
class UpdateUserProfileUseCase implements UseCase<User, UpdateProfileParams> {
  final UserRepository repository;
  
  UpdateUserProfileUseCase({required this.repository});
  
  @override
  Future<Either<Failure, User>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(
      name: params.name,
      phoneNumber: params.phoneNumber,
      profileImageUrl: params.profileImageUrl,
      dateOfBirth: params.dateOfBirth,
      height: params.height,
      weight: params.weight,
    );
  }
}

/// Update Profile Parameters
class UpdateProfileParams extends Equatable {
  final String? name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? dateOfBirth;
  final double? height;
  final double? weight;

  const UpdateProfileParams({
    this.name,
    this.phoneNumber,
    this.profileImageUrl,
    this.dateOfBirth,
    this.height,
    this.weight,
  });
  
  @override
  List<Object?> get props => [name, phoneNumber, profileImageUrl, dateOfBirth, height, weight];
}

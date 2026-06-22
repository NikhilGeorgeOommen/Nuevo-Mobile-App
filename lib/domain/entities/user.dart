import 'package:equatable/equatable.dart';
import 'subscription.dart';

/// User Entity (Domain Layer)
/// Represents the authenticated user with their profile and subscription
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime? dateOfBirth;
  final Subscription? subscription;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final double? height;
  final double? weight;
  
  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.profileImageUrl,
    this.dateOfBirth,
    this.subscription,
    this.createdAt,
    this.lastLoginAt,
    this.height,
    this.weight,
  });
  
  /// Check if user has an active subscription
  bool get hasActiveSubscription => subscription?.isActive ?? false;
  
  /// Check if user can access a specific feature
  bool canAccessFeature(String featureName) {
    return subscription?.hasFeature(featureName) ?? false;
  }
  
  /// Get user's initials for avatar
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
  
  /// Copy with method for updating user data
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    Subscription? subscription,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    double? height,
    double? weight,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      subscription: subscription ?? this.subscription,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    email,
    name,
    phoneNumber,
    profileImageUrl,
    dateOfBirth,
    subscription,
    createdAt,
    lastLoginAt,
    height,
    weight,
  ];
  
  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, hasActiveSubscription: $hasActiveSubscription)';
  }
}

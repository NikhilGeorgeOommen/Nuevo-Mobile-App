// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  phoneNumber: json['phone_number'] as String?,
  profileImageUrl: json['profileImage'] as String?,
  dateOfBirth: json['dateOfBirth'] as String?,
  subscription: json['subscription'] == null
      ? null
      : SubscriptionModel.fromJson(
          json['subscription'] as Map<String, dynamic>,
        ),
  createdAt: json['created_at'] as String?,
  lastLoginAt: json['last_login_at'] as String?,
  height: (json['height'] as num?)?.toDouble(),
  weight: (json['weight'] as num?)?.toDouble(),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'phone_number': instance.phoneNumber,
  'profileImage': instance.profileImageUrl,
  'dateOfBirth': instance.dateOfBirth,
  'subscription': instance.subscription,
  'created_at': instance.createdAt,
  'last_login_at': instance.lastLoginAt,
  'height': instance.height,
  'weight': instance.weight,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  uid: json['uid'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  role: json['role'] as String? ?? 'technician',
  isActive: json['isActive'] as bool? ?? true,
  language: json['language'] as String? ?? 'en',
  themeMode: json['themeMode'] as String? ?? 'dark',
  createdAt: _timestampFromJson(json['createdAt']),
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
      'isActive': instance.isActive,
      'language': instance.language,
      'themeMode': instance.themeMode,
      'createdAt': _timestampToJson(instance.createdAt),
    };

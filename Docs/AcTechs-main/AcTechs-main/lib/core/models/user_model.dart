// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String name,
    required String email,
    @Default('technician') String role,
    @Default(true) bool isActive,
    @Default('en') String language,
    @Default('dark') String themeMode,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawRole = (data['role'] as String? ?? 'technician').trim();
    final normalizedRole =
        (rawRole.toLowerCase() == 'admin' ||
            rawRole.toLowerCase() == 'administrator')
        ? 'admin'
        : 'technician';
    return UserModel.fromJson({'uid': doc.id, ...data, 'role': normalizedRole});
  }
}

DateTime? _timestampFromJson(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

dynamic _timestampToJson(DateTime? date) {
  if (date == null) return null;
  return Timestamp.fromDate(date);
}

extension UserModelX on UserModel {
  bool get isAdmin {
    final normalized = role.trim().toLowerCase();
    return normalized == 'admin' || normalized == 'administrator';
  }

  bool get isTechnician => !isAdmin;

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('uid');
    return json;
  }
}

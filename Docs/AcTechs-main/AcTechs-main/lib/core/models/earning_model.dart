// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'earning_model.freezed.dart';
part 'earning_model.g.dart';

enum EarningApprovalStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
}

enum PaymentType {
  @JsonValue('advance')
  advance,
  @JsonValue('settlement')
  settlement,
  @JsonValue('regular')
  regular,
}

/// A single earning entry (sold old AC, sold scrap, etc.).
@freezed
abstract class EarningModel with _$EarningModel {
  const factory EarningModel({
    @Default('') String id,
    required String techId,
    required String techName,
    required String category,
    required double amount,
    @Default('') String note,
    @Default(EarningApprovalStatus.pending) EarningApprovalStatus status,
    @Default('') String approvedBy,
    @Default('') String adminNote,
    @Default(PaymentType.regular) PaymentType paymentType,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? date,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? createdAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? reviewedAt,
    @JsonKey(defaultValue: false) @Default(false) bool isDeleted,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? deletedAt,
  }) = _EarningModel;

  factory EarningModel.fromJson(Map<String, dynamic> json) =>
      _$EarningModelFromJson(json);

  factory EarningModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EarningModel.fromJson({'id': doc.id, ...data});
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

extension EarningModelX on EarningModel {
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    // Archive fields are managed via direct .update() in the repository;
    // they must NOT appear in create payloads (Firestore hasOnly() rules).
    json.remove('isDeleted');
    json.remove('deletedAt');
    return json;
  }

  bool get isPending => status == EarningApprovalStatus.pending;
  bool get isApproved => status == EarningApprovalStatus.approved;
  bool get isRejected => status == EarningApprovalStatus.rejected;
}

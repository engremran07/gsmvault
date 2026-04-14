// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'ac_install_model.freezed.dart';
part 'ac_install_model.g.dart';

enum AcInstallStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
}

/// A daily AC installation record — tracks unit counts (not SAR amounts).
/// Separate from earnings/expenses. Tech records total units on the invoice
/// and their personal share installed for each AC type.
@freezed
abstract class AcInstallModel with _$AcInstallModel {
  const factory AcInstallModel({
    @Default('') String id,
    required String techId,
    required String techName,
    @Default(0) int splitTotal,
    @Default(0) int splitShare,
    @Default(0) int windowTotal,
    @Default(0) int windowShare,
    @Default(0) int freestandingTotal,
    @Default(0) int freestandingShare,
    @Default('') String note,
    @Default(AcInstallStatus.pending) AcInstallStatus status,
    @Default('') String approvedBy,
    @Default('') String adminNote,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? date,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? createdAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? reviewedAt,
    @JsonKey(defaultValue: false) @Default(false) bool isDeleted,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? deletedAt,
  }) = _AcInstallModel;

  factory AcInstallModel.fromJson(Map<String, dynamic> json) =>
      _$AcInstallModelFromJson(json);

  factory AcInstallModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AcInstallModel.fromJson({'id': doc.id, ...data});
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

extension AcInstallModelX on AcInstallModel {
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    // Archive fields are managed via direct .update() in the repository;
    // they must NOT appear in create payloads (Firestore hasOnly() rules).
    json.remove('isDeleted');
    json.remove('deletedAt');
    return json;
  }

  bool get isPending => status == AcInstallStatus.pending;
  bool get isApproved => status == AcInstallStatus.approved;
  bool get isRejected => status == AcInstallStatus.rejected;

  /// Total units this tech personally installed across all types.
  int get totalPersonalUnits => splitShare + windowShare + freestandingShare;

  /// Total units on the full invoice (all technicians combined).
  int get totalInvoiceUnits => splitTotal + windowTotal + freestandingTotal;
}

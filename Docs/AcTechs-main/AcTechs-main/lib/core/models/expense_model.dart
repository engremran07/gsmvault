// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'expense_model.freezed.dart';
part 'expense_model.g.dart';

enum ExpenseApprovalStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
}

/// A single daily expense entry (food, petrol, consumables, rent, etc.).
@freezed
abstract class ExpenseModel with _$ExpenseModel {
  const factory ExpenseModel({
    @Default('') String id,
    required String techId,
    required String techName,
    required String category,
    required double amount,
    @Default('') String note,
    @Default(ExpenseApprovalStatus.pending) ExpenseApprovalStatus status,
    @Default('') String approvedBy,
    @Default('') String adminNote,

    /// 'work' for regular expenses, 'home' for home chores
    @Default('work') String expenseType,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? date,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? createdAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? reviewedAt,
    @JsonKey(defaultValue: false) @Default(false) bool isDeleted,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? deletedAt,
  }) = _ExpenseModel;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExpenseModel.fromJson({'id': doc.id, ...data});
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

extension ExpenseModelX on ExpenseModel {
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    // Archive fields are managed via direct .update() in the repository;
    // they must NOT appear in create payloads (Firestore hasOnly() rules).
    json.remove('isDeleted');
    json.remove('deletedAt');
    return json;
  }

  bool get isPending => status == ExpenseApprovalStatus.pending;
  bool get isApproved => status == ExpenseApprovalStatus.approved;
  bool get isRejected => status == ExpenseApprovalStatus.rejected;
}

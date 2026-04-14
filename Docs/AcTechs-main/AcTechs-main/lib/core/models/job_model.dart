// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'job_model.freezed.dart';
part 'job_model.g.dart';

enum JobStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
}

enum JobSettlementStatus {
  @JsonValue('unpaid')
  unpaid,
  @JsonValue('awaiting_technician')
  awaitingTechnician,
  @JsonValue('correction_required')
  correctionRequired,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('disputed_final')
  disputedFinal,
}

extension JobSettlementStatusX on JobSettlementStatus {
  String get firestoreValue {
    switch (this) {
      case JobSettlementStatus.unpaid:
        return 'unpaid';
      case JobSettlementStatus.awaitingTechnician:
        return 'awaiting_technician';
      case JobSettlementStatus.correctionRequired:
        return 'correction_required';
      case JobSettlementStatus.confirmed:
        return 'confirmed';
      case JobSettlementStatus.disputedFinal:
        return 'disputed_final';
    }
  }
}

/// Represents one AC service line item on an invoice.
@freezed
abstract class AcUnit with _$AcUnit {
  const factory AcUnit({required String type, @Default(1) int quantity}) =
      _AcUnit;

  factory AcUnit.fromJson(Map<String, dynamic> json) => _$AcUnitFromJson(json);
}

/// Additional charges that may appear on an invoice.
@freezed
abstract class InvoiceCharges with _$InvoiceCharges {
  const factory InvoiceCharges({
    @Default(false) bool acBracket,
    @Default(0) int bracketCount,
    @Default(0.0) double bracketAmount,
    @Default(false) bool deliveryCharge,
    @Default(0.0) double deliveryAmount,
    @Default('') String deliveryNote,
  }) = _InvoiceCharges;

  factory InvoiceCharges.fromJson(Map<String, dynamic> json) =>
      _$InvoiceChargesFromJson(json);
}

@freezed
abstract class JobModel with _$JobModel {
  @JsonSerializable(explicitToJson: true)
  const factory JobModel({
    @Default('') String id,
    required String techId,
    required String techName,
    @Default('') String companyId,
    @Default('') String companyName,
    required String invoiceNumber,
    required String clientName,
    @Default('') String clientContact,
    @Default(<AcUnit>[]) List<AcUnit> acUnits,
    @Default(JobStatus.pending) JobStatus status,
    @Default(0.0) double expenses,
    @Default('') String expenseNote,
    @Default('') String adminNote,
    @Default(JobSettlementStatus.unpaid) JobSettlementStatus settlementStatus,
    @Default('') String settlementBatchId,
    @Default(0) int settlementRound,
    @Default(0.0) double settlementAmount,
    @Default('') String settlementPaymentMethod,
    @Default('') String settlementAdminNote,
    @Default('') String settlementTechnicianComment,
    @Default('') String settlementRequestedBy,
    @Default(<String, dynamic>{}) Map<String, dynamic> importMeta,
    String? approvedBy,
    @Default(false) bool isSharedInstall,
    @Default('') String sharedInstallGroupKey,
    @Default(0) int sharedInvoiceTotalUnits,
    @Default(0) int sharedContributionUnits,
    @Default(0) int sharedInvoiceSplitUnits,
    @Default(0) int sharedInvoiceWindowUnits,
    @Default(0) int sharedInvoiceFreestandingUnits,
    @Default(0) int sharedInvoiceUninstallSplitUnits,
    @Default(0) int sharedInvoiceUninstallWindowUnits,
    @Default(0) int sharedInvoiceUninstallFreestandingUnits,
    @Default(0) int sharedInvoiceBracketCount,
    @Default(0) int sharedDeliveryTeamCount,
    @Default(0.0) double sharedInvoiceDeliveryAmount,

    // Tech's personal installation share (how many of the invoice ACs they personally installed).
    @Default(0) int techSplitShare,
    @Default(0) int techWindowShare,
    @Default(0) int techFreestandingShare,
    @Default(0) int techUninstallSplitShare,
    @Default(0) int techUninstallWindowShare,
    @Default(0) int techUninstallFreestandingShare,
    @Default(0) int techBracketShare,

    /// Additional invoice charges (bracket, delivery).
    InvoiceCharges? charges,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? date,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? submittedAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? reviewedAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? settlementRequestedAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? settlementRespondedAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? settlementPaidAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? settlementCorrectedAt,
    @JsonKey(defaultValue: false) @Default(false) bool isDeleted,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? deletedAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? editRequestedAt,
  }) = _JobModel;

  factory JobModel.fromJson(Map<String, dynamic> json) =>
      _$JobModelFromJson(json);

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return JobModel.fromJson({'id': doc.id, ...data});
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

extension JobModelX on JobModel {
  bool get isPending => status == JobStatus.pending;
  bool get isApproved => status == JobStatus.approved;
  bool get isRejected => status == JobStatus.rejected;

  bool get isUnpaid => settlementStatus == JobSettlementStatus.unpaid;
  bool get isSettlementAwaitingTechnician =>
      settlementStatus == JobSettlementStatus.awaitingTechnician;
  bool get isSettlementCorrectionRequired =>
      settlementStatus == JobSettlementStatus.correctionRequired;
  bool get isSettlementConfirmed =>
      settlementStatus == JobSettlementStatus.confirmed;
  bool get isSettlementDisputedFinal =>
      settlementStatus == JobSettlementStatus.disputedFinal;
  bool get isSettlementLocked =>
      isSettlementConfirmed || isSettlementDisputedFinal;

  bool get hasInvoiceConflict => importMeta['invoiceConflict'] == true;

  List<String> get invoiceConflictCompanies {
    final raw = importMeta['invoiceConflictCompanies'];
    if (raw is! List) return const <String>[];
    return raw
        .map((value) => value?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  int get effectiveBracketCount {
    if (isSharedInstall && sharedInvoiceBracketCount > 0) {
      return techBracketShare > 0
          ? techBracketShare
          : sharedInvoiceBracketCount;
    }

    final currentCharges = charges;
    if (currentCharges == null) return 0;
    if (currentCharges.bracketCount > 0) return currentCharges.bracketCount;
    if (currentCharges.acBracket || currentCharges.bracketAmount > 0) {
      return 1;
    }
    return 0;
  }

  bool canTechnicianEdit({
    required bool approvalRequired,
    required bool sharedApprovalRequired,
  }) {
    if (isSettlementLocked || isSettlementAwaitingTechnician) {
      return false;
    }
    if (isPending || isRejected) {
      return true;
    }
    if (!isApproved) {
      return false;
    }
    final requiresApproval = isSharedInstall
        ? sharedApprovalRequired
        : approvalRequired;
    // Approved + approval OFF → editable for both solo and shared install jobs.
    // For shared installs the repository applies aggregate delta logic;
    // Firestore rules allow it via technicianCanEditApprovedJob() when
    // !sharedJobApprovalRequired(). Team-size changes (sharedDeliveryTeamCount)
    // remain immutable in the aggregate \u2014 only admin can fix a wrong team size
    // by deleting the job and letting the tech re-submit.
    return !requiresApproval && isUnpaid;
  }

  int get totalUnits => acUnits.fold(0, (s, unit) => s + unit.quantity);

  int unitsForType(String type) {
    return acUnits
        .where((unit) => unit.type == type)
        .fold(0, (total, unit) => total + unit.quantity);
  }

  int get sharedInstallUnitsTotal => sharedInvoiceTotalUnits > 0
      ? sharedInvoiceTotalUnits
      : unitsForType('Split AC') +
            unitsForType('Window AC') +
            unitsForType('Freestanding AC') +
            unitsForType('Uninstallation Split') +
            unitsForType('Uninstallation Window') +
            unitsForType('Uninstallation Freestanding');

  /// Total of all additional charges on this invoice.
  double get totalCharges {
    final c = charges;
    if (c == null) return 0;
    return (c.acBracket ? c.bracketAmount : 0) +
        (c.deliveryCharge ? c.deliveryAmount : 0);
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    json.remove('isDeleted');
    json.remove('deletedAt');
    return json;
  }
}

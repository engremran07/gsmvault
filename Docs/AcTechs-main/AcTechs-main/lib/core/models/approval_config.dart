import 'package:cloud_firestore/cloud_firestore.dart';

class ApprovalConfig {
  const ApprovalConfig({
    required this.jobApprovalRequired,
    required this.sharedJobApprovalRequired,
    required this.inOutApprovalRequired,
    required this.enforceMinimumBuild,
    required this.minSupportedBuildNumber,
    required this.lockedBeforeDate,
  });

  final bool jobApprovalRequired;
  final bool sharedJobApprovalRequired;
  final bool inOutApprovalRequired;
  final bool enforceMinimumBuild;
  final int minSupportedBuildNumber;
  final DateTime? lockedBeforeDate;

  factory ApprovalConfig.defaults() => const ApprovalConfig(
    jobApprovalRequired: true,
    sharedJobApprovalRequired: true,
    inOutApprovalRequired: true,
    enforceMinimumBuild: false,
    minSupportedBuildNumber: 1,
    lockedBeforeDate: null,
  );

  factory ApprovalConfig.fromMap(Map<String, dynamic>? data) {
    final minSupportedBuildNumber = data?['minSupportedBuildNumber'] is int
        ? data!['minSupportedBuildNumber'] as int
        : 1;
    return ApprovalConfig(
      jobApprovalRequired: data?['jobApprovalRequired'] is bool
          ? data!['jobApprovalRequired'] as bool
          : true,
      sharedJobApprovalRequired: data?['sharedJobApprovalRequired'] is bool
          ? data!['sharedJobApprovalRequired'] as bool
          : true,
      inOutApprovalRequired: data?['inOutApprovalRequired'] is bool
          ? data!['inOutApprovalRequired'] as bool
          : true,
      enforceMinimumBuild: data?['enforceMinimumBuild'] is bool
          ? data!['enforceMinimumBuild'] as bool
          : false,
      minSupportedBuildNumber: minSupportedBuildNumber < 1
          ? 1
          : minSupportedBuildNumber,
      lockedBeforeDate: _timestampFromConfig(data?['lockedBefore']),
    );
  }

  static DateTime? _timestampFromConfig(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  ApprovalConfig copyWith({
    bool? jobApprovalRequired,
    bool? sharedJobApprovalRequired,
    bool? inOutApprovalRequired,
    bool? enforceMinimumBuild,
    int? minSupportedBuildNumber,
    DateTime? lockedBeforeDate,
    bool clearLockedBeforeDate = false,
  }) {
    return ApprovalConfig(
      jobApprovalRequired: jobApprovalRequired ?? this.jobApprovalRequired,
      sharedJobApprovalRequired:
          sharedJobApprovalRequired ?? this.sharedJobApprovalRequired,
      inOutApprovalRequired:
          inOutApprovalRequired ?? this.inOutApprovalRequired,
      enforceMinimumBuild: enforceMinimumBuild ?? this.enforceMinimumBuild,
      minSupportedBuildNumber:
          minSupportedBuildNumber ?? this.minSupportedBuildNumber,
      lockedBeforeDate: clearLockedBeforeDate
          ? null
          : lockedBeforeDate ?? this.lockedBeforeDate,
    );
  }

  Map<String, dynamic> toMap() => {
    'jobApprovalRequired': jobApprovalRequired,
    'sharedJobApprovalRequired': sharedJobApprovalRequired,
    'inOutApprovalRequired': inOutApprovalRequired,
    'enforceMinimumBuild': enforceMinimumBuild,
    'minSupportedBuildNumber': minSupportedBuildNumber,
    'lockedBefore': lockedBeforeDate == null
        ? null
        : Timestamp.fromDate(lockedBeforeDate!),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  bool locksDate(DateTime value) {
    final lockDate = lockedBeforeDate;
    return lockDate != null && value.isBefore(lockDate);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApprovalConfig &&
        other.jobApprovalRequired == jobApprovalRequired &&
        other.sharedJobApprovalRequired == sharedJobApprovalRequired &&
        other.inOutApprovalRequired == inOutApprovalRequired &&
        other.enforceMinimumBuild == enforceMinimumBuild &&
        other.minSupportedBuildNumber == minSupportedBuildNumber &&
        other.lockedBeforeDate == lockedBeforeDate;
  }

  @override
  int get hashCode => Object.hash(
    jobApprovalRequired,
    sharedJobApprovalRequired,
    inOutApprovalRequired,
    enforceMinimumBuild,
    minSupportedBuildNumber,
    lockedBeforeDate,
  );
}

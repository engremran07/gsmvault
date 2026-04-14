class ApprovalHistoryEntry {
  const ApprovalHistoryEntry({
    required this.changedBy,
    required this.changedAt,
    required this.previousStatus,
    required this.newStatus,
    this.reason = '',
  });

  final String changedBy;
  final DateTime? changedAt;
  final String previousStatus;
  final String newStatus;
  final String reason;

  factory ApprovalHistoryEntry.fromMap(Map<String, dynamic>? data) {
    final changedAtRaw = data?['changedAt'];
    return ApprovalHistoryEntry(
      changedBy: data?['changedBy'] as String? ?? '',
      changedAt: changedAtRaw is DateTime
          ? changedAtRaw
          : changedAtRaw?.toDate() as DateTime?,
      previousStatus: data?['previousStatus'] as String? ?? '',
      newStatus: data?['newStatus'] as String? ?? '',
      reason: data?['reason'] as String? ?? '',
    );
  }
}

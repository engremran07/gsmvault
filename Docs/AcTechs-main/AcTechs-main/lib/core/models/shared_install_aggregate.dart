import 'package:cloud_firestore/cloud_firestore.dart';

/// Plain Dart model for a shared_install_aggregates document.
///
/// Not Freezed — shared_install_aggregates is append-only from the client's
/// perspective (tech only contributes consumed* counters). The model is used
/// read-only in the UI for team display and capacity checks.
///
/// [teamMemberIds] element[0] is always the createdBy uid (first submitter).
/// Legacy documents without a teamMemberIds field are tolerated: [teamMemberIds]
/// will be an empty list in that case.
class SharedInstallAggregate {
  const SharedInstallAggregate({
    required this.id,
    required this.groupKey,
    required this.companyId,
    required this.companyName,
    required this.createdBy,
    required this.teamMemberIds,
    required this.teamMemberNames,
    required this.sharedInvoiceSplitUnits,
    required this.sharedInvoiceWindowUnits,
    required this.sharedInvoiceFreestandingUnits,
    required this.sharedInvoiceUninstallSplitUnits,
    required this.sharedInvoiceUninstallWindowUnits,
    required this.sharedInvoiceUninstallFreestandingUnits,
    required this.sharedInvoiceBracketCount,
    required this.sharedDeliveryTeamCount,
    required this.sharedInvoiceDeliveryAmount,
    required this.consumedSplitUnits,
    required this.consumedWindowUnits,
    required this.consumedFreestandingUnits,
    required this.consumedUninstallSplitUnits,
    required this.consumedUninstallWindowUnits,
    required this.consumedUninstallFreestandingUnits,
    required this.consumedBracketCount,
    required this.consumedDeliveryAmount,
    this.clientName = '',
    this.clientContact = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String groupKey;

  /// Company that owns this shared install invoice.
  /// Stored directly on the aggregate so team members can pre-fill the
  /// company selector without querying each other's jobs (which would be
  /// PERMISSION_DENIED). Falls back to extracting from [groupKey] for
  /// legacy aggregates created before this field was added.
  final String companyId;
  final String companyName;

  final String createdBy;

  /// UIDs of all team members. Element[0] == [createdBy].
  /// Empty list on legacy documents (before team-roster feature was deployed).
  final List<String> teamMemberIds;
  final List<String> teamMemberNames;

  // Invoice totals — immutable after first submission.
  final int sharedInvoiceSplitUnits;
  final int sharedInvoiceWindowUnits;
  final int sharedInvoiceFreestandingUnits;
  final int sharedInvoiceUninstallSplitUnits;
  final int sharedInvoiceUninstallWindowUnits;
  final int sharedInvoiceUninstallFreestandingUnits;
  final int sharedInvoiceBracketCount;
  final int sharedDeliveryTeamCount;
  final double sharedInvoiceDeliveryAmount;

  // Running totals of what has been consumed so far.
  final int consumedSplitUnits;
  final int consumedWindowUnits;
  final int consumedFreestandingUnits;
  final int consumedUninstallSplitUnits;
  final int consumedUninstallWindowUnits;
  final int consumedUninstallFreestandingUnits;
  final int consumedBracketCount;
  final double consumedDeliveryAmount;

  /// Client details copied from the first submitter's job —
  /// allows teammates to pre-fill the form without reading each other's jobs.
  final String clientName;
  final String clientContact;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SharedInstallAggregate.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? {};
    return SharedInstallAggregate(
      id: snap.id,
      groupKey: (data['groupKey'] as String?) ?? '',
      companyId: (data['companyId'] as String?) ?? '',
      companyName: (data['companyName'] as String?) ?? '',
      createdBy: (data['createdBy'] as String?) ?? '',
      teamMemberIds: List<String>.from(data['teamMemberIds'] as List? ?? []),
      teamMemberNames: List<String>.from(
        data['teamMemberNames'] as List? ?? [],
      ),
      sharedInvoiceSplitUnits: _int(data, 'sharedInvoiceSplitUnits'),
      sharedInvoiceWindowUnits: _int(data, 'sharedInvoiceWindowUnits'),
      sharedInvoiceFreestandingUnits: _int(
        data,
        'sharedInvoiceFreestandingUnits',
      ),
      sharedInvoiceUninstallSplitUnits: _int(
        data,
        'sharedInvoiceUninstallSplitUnits',
      ),
      sharedInvoiceUninstallWindowUnits: _int(
        data,
        'sharedInvoiceUninstallWindowUnits',
      ),
      sharedInvoiceUninstallFreestandingUnits: _int(
        data,
        'sharedInvoiceUninstallFreestandingUnits',
      ),
      sharedInvoiceBracketCount: _int(data, 'sharedInvoiceBracketCount'),
      sharedDeliveryTeamCount: _int(data, 'sharedDeliveryTeamCount'),
      sharedInvoiceDeliveryAmount: _double(data, 'sharedInvoiceDeliveryAmount'),
      consumedSplitUnits: _int(data, 'consumedSplitUnits'),
      consumedWindowUnits: _int(data, 'consumedWindowUnits'),
      consumedFreestandingUnits: _int(data, 'consumedFreestandingUnits'),
      consumedUninstallSplitUnits: _int(data, 'consumedUninstallSplitUnits'),
      consumedUninstallWindowUnits: _int(data, 'consumedUninstallWindowUnits'),
      consumedUninstallFreestandingUnits: _int(
        data,
        'consumedUninstallFreestandingUnits',
      ),
      consumedBracketCount: _int(data, 'consumedBracketCount'),
      consumedDeliveryAmount: _double(data, 'consumedDeliveryAmount'),
      clientName: (data['clientName'] as String?) ?? '',
      clientContact: (data['clientContact'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static int _int(Map<String, dynamic> data, String key) =>
      (data[key] as num?)?.toInt() ?? 0;

  static double _double(Map<String, dynamic> data, String key) =>
      (data[key] as num?)?.toDouble() ?? 0.0;

  /// Display name for team member at [index], or empty string if out of range.
  String teamMemberNameAt(int index) =>
      (index < teamMemberNames.length) ? teamMemberNames[index] : '';

  /// Whether [uid] is enrolled in this aggregate's team roster.
  /// Always returns true for legacy aggregates without a roster (empty list).
  bool isMember(String uid) =>
      teamMemberIds.isEmpty || teamMemberIds.contains(uid);

  /// Whether all expected team contributions have been consumed.
  ///
  /// Returns true when every consumed counter has reached the corresponding
  /// invoice total, meaning no team member has remaining work to submit.
  /// The delivery check uses a 0.001 epsilon to tolerate floating-point drift.
  ///
  /// Edge case: if ALL invoice values are 0 (e.g. a zero-unit test aggregate),
  /// we return false so it never self-hides without any real contribution.
  bool get isFullyConsumed {
    final hasWork =
        sharedInvoiceSplitUnits > 0 ||
        sharedInvoiceWindowUnits > 0 ||
        sharedInvoiceFreestandingUnits > 0 ||
        sharedInvoiceUninstallSplitUnits > 0 ||
        sharedInvoiceUninstallWindowUnits > 0 ||
        sharedInvoiceUninstallFreestandingUnits > 0 ||
        sharedInvoiceBracketCount > 0 ||
        sharedInvoiceDeliveryAmount > 0.0;

    if (!hasWork) return false;

    return consumedSplitUnits >= sharedInvoiceSplitUnits &&
        consumedWindowUnits >= sharedInvoiceWindowUnits &&
        consumedFreestandingUnits >= sharedInvoiceFreestandingUnits &&
        consumedUninstallSplitUnits >= sharedInvoiceUninstallSplitUnits &&
        consumedUninstallWindowUnits >= sharedInvoiceUninstallWindowUnits &&
        consumedUninstallFreestandingUnits >=
            sharedInvoiceUninstallFreestandingUnits &&
        consumedBracketCount >= sharedInvoiceBracketCount &&
        (sharedInvoiceDeliveryAmount <= 0.0 ||
            consumedDeliveryAmount >= sharedInvoiceDeliveryAmount - 0.001);
  }

  /// Invoice number extracted from [groupKey].
  /// GroupKey format: "{companyId}-{invoiceNumber}". Firestore auto-IDs are
  /// base62 (no hyphens), so splitting at the first '-' is safe.
  String get invoiceNumber {
    final idx = groupKey.indexOf('-');
    return idx == -1 ? groupKey : groupKey.substring(idx + 1);
  }
}

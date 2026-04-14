import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/features/settings/data/period_lock_guard.dart';

final acInstallRepositoryProvider = Provider<AcInstallRepository>((ref) {
  return AcInstallRepository(firestore: FirebaseFirestore.instance);
});

class AcInstallRepository {
  AcInstallRepository({required this.firestore});

  final FirebaseFirestore firestore;

  List<AcInstallModel> _activeInstallsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final installs = <AcInstallModel>[];
    for (final doc in snap.docs) {
      if (doc.data()['isDeleted'] == true) {
        continue;
      }
      installs.add(AcInstallModel.fromFirestore(doc));
    }
    return installs;
  }

  CollectionReference<Map<String, dynamic>> get _ref =>
      firestore.collection(AppConstants.acInstallsCollection);

  CollectionReference<Map<String, dynamic>> _historyRef(String installId) =>
      _ref.doc(installId).collection(AppConstants.historySubCollection);

  PeriodLockGuard get _periodLockGuard => PeriodLockGuard(firestore: firestore);

  Future<void> _ensureMutableRecord(String id) async {
    final snap = await _ref.doc(id).get();
    final status = snap.data()?['status'] as String?;
    if (status == AcInstallStatus.approved.name) {
      throw AcInstallException.approvedRecordLocked();
    }
  }

  void _validateInstall(AcInstallModel install) {
    final totals = <(int total, int share)>[
      (install.splitTotal, install.splitShare),
      (install.windowTotal, install.windowShare),
      (install.freestandingTotal, install.freestandingShare),
    ];

    final hasAnyUnits = totals.any((entry) => entry.$1 > 0);
    final hasInvalidPair = totals.any(
      (entry) => entry.$1 < 0 || entry.$2 < 0 || entry.$2 > entry.$1,
    );

    if (!hasAnyUnits || hasInvalidPair) {
      throw AcInstallException.saveFailed();
    }
  }

  Map<String, dynamic> _normalizedInstallData(AcInstallModel install) {
    final now = DateTime.now();
    final data = install.toFirestore();
    data['approvedBy'] = install.approvedBy;
    data['adminNote'] = install.adminNote;
    data['date'] ??= Timestamp.fromDate(now);
    data['createdAt'] ??= Timestamp.fromDate(now);
    if (!data.containsKey('reviewedAt') && install.reviewedAt != null) {
      data['reviewedAt'] = Timestamp.fromDate(install.reviewedAt!);
    }
    return data;
  }

  /// Stream of all AC install records for a technician (for monthly summaries).
  Stream<List<AcInstallModel>> watchTechInstalls(String techId) {
    return _ref
        .where('techId', isEqualTo: techId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(_activeInstallsFromSnapshot);
  }

  /// Admin: stream of all pending AC install records.
  Stream<List<AcInstallModel>> watchPendingInstalls() {
    return _ref
        .where('status', isEqualTo: 'pending')
        .orderBy('date', descending: true)
        .snapshots()
        .map(_activeInstallsFromSnapshot);
  }

  Future<List<ApprovalHistoryEntry>> fetchInstallHistory(
    String installId, {
    int limit = 10,
  }) async {
    final snap = await _historyRef(
      installId,
    ).orderBy('changedAt', descending: true).limit(limit).get();
    return snap.docs
        .map((doc) => ApprovalHistoryEntry.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<void> addInstall(
    AcInstallModel install, {
    DateTime? lockedBeforeDate,
  }) async {
    try {
      _validateInstall(install);
      await _periodLockGuard.ensureUnlockedDate(
        install.date,
        cachedLockedBefore: lockedBeforeDate,
      );
      await _ref.add(_normalizedInstallData(install));
    } on PeriodException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('addInstall error: ${e.code} — ${e.message}');
      throw AcInstallException.saveFailed();
    } on AcInstallException {
      rethrow;
    } catch (e) {
      debugPrint('addInstall unknown: $e');
      throw AcInstallException.saveFailed();
    }
  }

  // NEVER hard-delete technician-owned records — use archiveInstall().
  // Admin restore is available via restoreInstall().
  // NOTE: Archiving a shared AC install does NOT decrement aggregate consumed*
  // counters. Counter rollback requires a cross-collection transaction that
  // breaks the free-tier read budget. Discrepancies must be fixed via admin
  // flush + rebuild. Document this at all archive call sites.
  Future<void> archiveInstall(String id) async {
    try {
      await _periodLockGuard.ensureUnlockedDocument(_ref.doc(id));
      await _ensureMutableRecord(id);
      await _ref.doc(id).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } on AcInstallException {
      rethrow;
    } on PeriodException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('archiveInstall error: ${e.code} — ${e.message}');
      throw AcInstallException.deleteFailed();
    } catch (e) {
      debugPrint('archiveInstall unknown: $e');
      throw AcInstallException.deleteFailed();
    }
  }

  Future<void> restoreInstall(String id) async {
    try {
      await _ref.doc(id).update({'isDeleted': false, 'deletedAt': null});
    } on FirebaseException catch (e) {
      debugPrint('restoreInstall error: ${e.code} — ${e.message}');
      throw AcInstallException.saveFailed();
    } catch (e) {
      debugPrint('restoreInstall unknown: $e');
      throw AcInstallException.saveFailed();
    }
  }

  Future<void> approveInstall(String id, String adminUid) async {
    try {
      await _periodLockGuard.ensureUnlockedDocument(_ref.doc(id));
      await firestore.runTransaction((tx) async {
        final installRef = _ref.doc(id);
        final snap = await tx.get(installRef);
        final previousStatus = snap.data()?['status'] as String? ?? 'pending';
        if (previousStatus == AcInstallStatus.approved.name) {
          throw AcInstallException.approvedRecordLocked();
        }
        tx.update(installRef, {
          'status': 'approved',
          'approvedBy': adminUid,
          'adminNote': '',
          'reviewedAt': FieldValue.serverTimestamp(),
        });
        tx.set(_historyRef(id).doc(), {
          'changedBy': adminUid,
          'changedAt': FieldValue.serverTimestamp(),
          'previousStatus': previousStatus,
          'newStatus': 'approved',
        });
      });
    } on AcInstallException {
      rethrow;
    } on PeriodException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('approveInstall error: ${e.code} — ${e.message}');
      throw AcInstallException.updateFailed();
    } catch (e) {
      debugPrint('approveInstall unknown: $e');
      throw AcInstallException.updateFailed();
    }
  }

  Future<void> rejectInstall(String id, String adminUid, String note) async {
    try {
      await _periodLockGuard.ensureUnlockedDocument(_ref.doc(id));
      await firestore.runTransaction((tx) async {
        final installRef = _ref.doc(id);
        final snap = await tx.get(installRef);
        final previousStatus = snap.data()?['status'] as String? ?? 'pending';
        if (previousStatus == AcInstallStatus.approved.name) {
          throw AcInstallException.approvedRecordLocked();
        }
        tx.update(installRef, {
          'status': 'rejected',
          'approvedBy': adminUid,
          'adminNote': note,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
        tx.set(_historyRef(id).doc(), {
          'changedBy': adminUid,
          'changedAt': FieldValue.serverTimestamp(),
          'previousStatus': previousStatus,
          'newStatus': 'rejected',
          'reason': note,
        });
      });
    } on AcInstallException {
      rethrow;
    } on PeriodException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('rejectInstall error: ${e.code} — ${e.message}');
      throw AcInstallException.updateFailed();
    } catch (e) {
      debugPrint('rejectInstall unknown: $e');
      throw AcInstallException.updateFailed();
    }
  }
}

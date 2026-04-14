import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/features/settings/data/period_lock_guard.dart';

final earningRepositoryProvider = Provider<EarningRepository>((ref) {
  return EarningRepository(firestore: FirebaseFirestore.instance);
});

class EarningRepository {
  EarningRepository({required this.firestore});

  final FirebaseFirestore firestore;

  List<EarningModel> _activeEarningsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final earnings = <EarningModel>[];
    for (final doc in snap.docs) {
      if (doc.data()['isDeleted'] == true) {
        continue;
      }
      earnings.add(EarningModel.fromFirestore(doc));
    }
    return earnings;
  }

  CollectionReference<Map<String, dynamic>> get _ref =>
      firestore.collection(AppConstants.earningsCollection);

  CollectionReference<Map<String, dynamic>> _historyRef(String earningId) {
    return _ref.doc(earningId).collection(AppConstants.historySubCollection);
  }

  PeriodLockGuard get _periodLockGuard => PeriodLockGuard(firestore: firestore);

  Future<List<ApprovalHistoryEntry>> fetchHistory(
    String earningId, {
    int limit = 10,
  }) async {
    final snap = await _historyRef(
      earningId,
    ).orderBy('changedAt', descending: true).limit(limit).get();
    return snap.docs
        .map((doc) => ApprovalHistoryEntry.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<void> addEarning(
    EarningModel earning, {
    DateTime? lockedBeforeDate,
  }) async {
    try {
      await _periodLockGuard.ensureUnlockedDate(
        earning.date,
        cachedLockedBefore: lockedBeforeDate,
      );
      await _ref.add(earning.toFirestore());
    } on PeriodException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('addEarning error: ${e.code} — ${e.message}');
      if (e.code == 'permission-denied') {
        throw EarningException.permissionDenied();
      }
      throw EarningException.saveFailed();
    } catch (e) {
      debugPrint('addEarning unknown: $e');
      throw EarningException.saveFailed();
    }
  }

  // NEVER hard-delete technician-owned records — use archiveEarning().
  // Admin restore is available via restoreEarning().
  Future<void> archiveEarning(String id, {DateTime? lockedBeforeDate}) async {
    try {
      await _periodLockGuard.ensureUnlockedDocument(
        _ref.doc(id),
        cachedLockedBefore: lockedBeforeDate,
      );
      // Note: no app-layer approved-record check here. When inOutApprovalRequired
      // is false all new entries are auto-approved, so blocking archive on
      // approved status would make items permanently unarchivable. Firestore
      // rules are the authoritative gate.
      await _ref.doc(id).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } on EarningException {
      rethrow;
    } on PeriodException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('archiveEarning error: ${e.code} — ${e.message}');
      throw EarningException.deleteFailed();
    } catch (e) {
      debugPrint('archiveEarning unknown: $e');
      throw EarningException.deleteFailed();
    }
  }

  Future<void> restoreEarning(String id) async {
    try {
      await _ref.doc(id).update({'isDeleted': false, 'deletedAt': null});
    } on FirebaseException catch (e) {
      debugPrint('restoreEarning error: ${e.code} — ${e.message}');
      throw EarningException.saveFailed();
    } catch (e) {
      debugPrint('restoreEarning unknown: $e');
      throw EarningException.saveFailed();
    }
  }

  Future<void> updateEarning(
    EarningModel earning, {
    DateTime? lockedBeforeDate,
  }) async {
    try {
      await _periodLockGuard.ensureUnlockedDate(
        earning.date,
        cachedLockedBefore: lockedBeforeDate,
      );
      // Note: no app-layer approved-record check here. When inOutApprovalRequired
      // is false all new entries are auto-approved; blocking update on approved
      // status would make all edits permanently forbidden. Firestore rules are
      // the authoritative gate.
      await _ref.doc(earning.id).update(earning.toFirestore());
    } on EarningException {
      rethrow;
    } on PeriodException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('updateEarning error: ${e.code} — ${e.message}');
      if (e.code == 'permission-denied') {
        throw EarningException.permissionDenied();
      }
      throw EarningException.updateFailed();
    } catch (e) {
      debugPrint('updateEarning unknown: $e');
      throw EarningException.updateFailed();
    }
  }

  Future<void> approveEarning(String id, String adminUid) async {
    try {
      await _periodLockGuard.ensureUnlockedDocument(_ref.doc(id));
      await firestore.runTransaction((tx) async {
        final docRef = _ref.doc(id);
        final snap = await tx.get(docRef);
        final prevStatus = snap.data()?['status'] as String? ?? 'pending';
        if (prevStatus == EarningApprovalStatus.approved.name) {
          throw EarningException.approvedRecordLocked();
        }
        tx.update(docRef, {
          'status': 'approved',
          'approvedBy': adminUid,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
        tx.set(_historyRef(id).doc(), {
          'changedBy': adminUid,
          'changedAt': FieldValue.serverTimestamp(),
          'previousStatus': prevStatus,
          'newStatus': 'approved',
        });
      });
    } on EarningException {
      rethrow;
    } on PeriodException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('approveEarning error: ${e.code} — ${e.message}');
      throw EarningException.updateFailed();
    } catch (e) {
      debugPrint('approveEarning unknown: $e');
      throw EarningException.updateFailed();
    }
  }

  Future<void> rejectEarning(String id, String adminUid, String reason) async {
    try {
      await _periodLockGuard.ensureUnlockedDocument(_ref.doc(id));
      await firestore.runTransaction((tx) async {
        final docRef = _ref.doc(id);
        final snap = await tx.get(docRef);
        final prevStatus = snap.data()?['status'] as String? ?? 'pending';
        if (prevStatus == EarningApprovalStatus.approved.name) {
          throw EarningException.approvedRecordLocked();
        }
        tx.update(docRef, {
          'status': 'rejected',
          'approvedBy': adminUid,
          'adminNote': reason,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
        tx.set(_historyRef(id).doc(), {
          'changedBy': adminUid,
          'changedAt': FieldValue.serverTimestamp(),
          'previousStatus': prevStatus,
          'newStatus': 'rejected',
          'reason': reason,
        });
      });
    } on EarningException {
      rethrow;
    } on PeriodException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('rejectEarning error: ${e.code} — ${e.message}');
      throw EarningException.updateFailed();
    } catch (e) {
      debugPrint('rejectEarning unknown: $e');
      throw EarningException.updateFailed();
    }
  }

  Stream<List<EarningModel>> pendingEarnings() {
    return _ref
        .where('status', isEqualTo: 'pending')
        .orderBy('date', descending: false)
        .snapshots()
        .map(_activeEarningsFromSnapshot);
  }

  Stream<List<EarningModel>> allEarnings() {
    return _ref
        .orderBy('date', descending: true)
        .snapshots()
        .map(_activeEarningsFromSnapshot);
  }

  Future<List<EarningModel>> fetchEarnings({
    DateTime? start,
    DateTime? end,
    String? techId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _ref;
      if (techId != null && techId.trim().isNotEmpty) {
        query = query.where('techId', isEqualTo: techId.trim());
      }
      if (start != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        );
      }
      if (end != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(end),
        );
      }
      final snap = await query.orderBy('date', descending: true).get();
      return _activeEarningsFromSnapshot(snap);
    } on FirebaseException catch (e) {
      debugPrint('fetchEarnings error: ${e.code} — ${e.message}');
      throw EarningException.saveFailed();
    } catch (e) {
      debugPrint('fetchEarnings unknown: $e');
      throw EarningException.saveFailed();
    }
  }

  /// Real-time stream of a tech's earnings, newest first.
  Stream<List<EarningModel>> techEarnings(String techId) {
    return _ref
        .where('techId', isEqualTo: techId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(_activeEarningsFromSnapshot);
  }

  /// Earnings for a specific month.
  Stream<List<EarningModel>> monthlyEarnings(String techId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return _ref
        .where('techId', isEqualTo: techId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map(_activeEarningsFromSnapshot);
  }
}

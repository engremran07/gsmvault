import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/features/settings/data/period_lock_guard.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(firestore: FirebaseFirestore.instance);
});

class ExpenseRepository {
  ExpenseRepository({required this.firestore});

  final FirebaseFirestore firestore;

  List<ExpenseModel> _activeExpensesFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final expenses = <ExpenseModel>[];
    for (final doc in snap.docs) {
      if (doc.data()['isDeleted'] == true) {
        continue;
      }
      expenses.add(ExpenseModel.fromFirestore(doc));
    }
    return expenses;
  }

  CollectionReference<Map<String, dynamic>> get _ref =>
      firestore.collection(AppConstants.expensesCollection);

  CollectionReference<Map<String, dynamic>> _historyRef(String expenseId) {
    return _ref.doc(expenseId).collection(AppConstants.historySubCollection);
  }

  PeriodLockGuard get _periodLockGuard => PeriodLockGuard(firestore: firestore);

  Future<List<ApprovalHistoryEntry>> fetchHistory(
    String expenseId, {
    int limit = 10,
  }) async {
    final snap = await _historyRef(
      expenseId,
    ).orderBy('changedAt', descending: true).limit(limit).get();
    return snap.docs
        .map((doc) => ApprovalHistoryEntry.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<void> addExpense(
    ExpenseModel expense, {
    DateTime? lockedBeforeDate,
  }) async {
    try {
      await _periodLockGuard.ensureUnlockedDate(
        expense.date,
        cachedLockedBefore: lockedBeforeDate,
      );
      await _ref.add(expense.toFirestore());
    } on PeriodException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('addExpense error: ${e.code} — ${e.message}');
      if (e.code == 'permission-denied') {
        throw ExpenseException.permissionDenied();
      }
      throw ExpenseException.saveFailed();
    } catch (e) {
      debugPrint('addExpense unknown: $e');
      throw ExpenseException.saveFailed();
    }
  }

  // NEVER hard-delete technician-owned records — use archiveExpense().
  // Admin restore is available via restoreExpense().
  Future<void> archiveExpense(String id, {DateTime? lockedBeforeDate}) async {
    try {
      await _periodLockGuard.ensureUnlockedDocument(
        _ref.doc(id),
        cachedLockedBefore: lockedBeforeDate,
      );
      // Note: no app-layer approved-record check here. When inOutApprovalRequired
      // is false, all new entries are auto-approved, so blocking archive on
      // approved status would make items permanently unarchivable. Firestore rules
      // are the authoritative gate for this operation.
      await _ref.doc(id).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } on ExpenseException {
      rethrow;
    } on PeriodException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('archiveExpense error: ${e.code} — ${e.message}');
      throw ExpenseException.deleteFailed();
    } catch (e) {
      debugPrint('archiveExpense unknown: $e');
      throw ExpenseException.deleteFailed();
    }
  }

  Future<void> restoreExpense(String id) async {
    try {
      await _ref.doc(id).update({'isDeleted': false, 'deletedAt': null});
    } on FirebaseException catch (e) {
      debugPrint('restoreExpense error: ${e.code} — ${e.message}');
      throw ExpenseException.saveFailed();
    } catch (e) {
      debugPrint('restoreExpense unknown: $e');
      throw ExpenseException.saveFailed();
    }
  }

  Future<void> updateExpense(
    ExpenseModel expense, {
    DateTime? lockedBeforeDate,
  }) async {
    try {
      await _periodLockGuard.ensureUnlockedDate(
        expense.date,
        cachedLockedBefore: lockedBeforeDate,
      );
      // Note: no app-layer approved-record check here. When inOutApprovalRequired
      // is false, all new entries are auto-approved; blocking update on approved
      // status would make all edits permanently forbidden. Firestore rules are
      // the authoritative gate.
      await _ref.doc(expense.id).update(expense.toFirestore());
    } on ExpenseException {
      rethrow;
    } on PeriodException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('updateExpense error: ${e.code} — ${e.message}');
      if (e.code == 'permission-denied') {
        throw ExpenseException.permissionDenied();
      }
      throw ExpenseException.userSaveFailed();
    } catch (e) {
      debugPrint('updateExpense unknown: $e');
      throw ExpenseException.userSaveFailed();
    }
  }

  Future<void> approveExpense(String id, String adminUid) async {
    try {
      await _periodLockGuard.ensureUnlockedDocument(_ref.doc(id));
      await firestore.runTransaction((tx) async {
        final docRef = _ref.doc(id);
        final snap = await tx.get(docRef);
        final prevStatus = snap.data()?['status'] as String? ?? 'pending';
        if (prevStatus == ExpenseApprovalStatus.approved.name) {
          throw ExpenseException.approvedRecordLocked();
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
    } on ExpenseException {
      rethrow;
    } on PeriodException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('approveExpense error: ${e.code} — ${e.message}');
      throw ExpenseException.userSaveFailed();
    } catch (e) {
      debugPrint('approveExpense unknown: $e');
      throw ExpenseException.userSaveFailed();
    }
  }

  Future<void> rejectExpense(String id, String adminUid, String reason) async {
    try {
      await _periodLockGuard.ensureUnlockedDocument(_ref.doc(id));
      await firestore.runTransaction((tx) async {
        final docRef = _ref.doc(id);
        final snap = await tx.get(docRef);
        final prevStatus = snap.data()?['status'] as String? ?? 'pending';
        if (prevStatus == ExpenseApprovalStatus.approved.name) {
          throw ExpenseException.approvedRecordLocked();
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
    } on ExpenseException {
      rethrow;
    } on PeriodException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('rejectExpense error: ${e.code} — ${e.message}');
      throw ExpenseException.userSaveFailed();
    } catch (e) {
      debugPrint('rejectExpense unknown: $e');
      throw ExpenseException.userSaveFailed();
    }
  }

  Stream<List<ExpenseModel>> pendingExpenses() {
    return _ref
        .where('status', isEqualTo: 'pending')
        .orderBy('date', descending: false)
        .snapshots()
        .map(_activeExpensesFromSnapshot);
  }

  Stream<List<ExpenseModel>> allExpenses() {
    return _ref
        .orderBy('date', descending: true)
        .snapshots()
        .map(_activeExpensesFromSnapshot);
  }

  Future<List<ExpenseModel>> fetchExpenses({
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
      return snap.docs.map((d) => ExpenseModel.fromFirestore(d)).toList();
    } on FirebaseException catch (e) {
      debugPrint('fetchExpenses error: ${e.code} — ${e.message}');
      throw ExpenseException.saveFailed();
    } catch (e) {
      debugPrint('fetchExpenses unknown: $e');
      throw ExpenseException.saveFailed();
    }
  }

  /// Real-time stream of a tech's expenses, newest first.
  Stream<List<ExpenseModel>> techExpenses(String techId) {
    return _ref
        .where('techId', isEqualTo: techId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(_activeExpensesFromSnapshot);
  }

  /// Expenses for a specific month.
  Stream<List<ExpenseModel>> monthlyExpenses(String techId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return _ref
        .where('techId', isEqualTo: techId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map(_activeExpensesFromSnapshot);
  }

  Stream<List<ExpenseModel>> monthlyWorkExpenses(
    String techId,
    DateTime month,
  ) {
    return monthlyExpenses(techId, month).map(
      (items) => items
          .where((item) => item.expenseType != AppConstants.expenseTypeHome)
          .toList(),
    );
  }

  Stream<List<ExpenseModel>> monthlyHomeExpenses(
    String techId,
    DateTime month,
  ) {
    return monthlyExpenses(techId, month).map(
      (items) => items
          .where((item) => item.expenseType == AppConstants.expenseTypeHome)
          .toList(),
    );
  }
}

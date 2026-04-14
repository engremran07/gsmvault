import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';

class PeriodLockGuard {
  PeriodLockGuard({required this.firestore});

  final FirebaseFirestore firestore;

  DocumentReference<Map<String, dynamic>> get _configRef => firestore
      .collection(AppConstants.appSettingsCollection)
      .doc(AppConstants.approvalConfigDocId);

  Future<DateTime?> lockedBeforeDate() async {
    final snap = await _configRef.get();
    if (!snap.exists) return null;

    final rawValue = snap.data()?['lockedBefore'];
    return _timestampToDate(rawValue);
  }

  Future<void> ensureUnlockedDate(
    DateTime? value, {
    DateTime? cachedLockedBefore,
  }) async {
    if (value == null) return;

    final lockedBefore = cachedLockedBefore ?? await lockedBeforeDate();
    if (lockedBefore != null && value.isBefore(lockedBefore)) {
      throw PeriodException.locked();
    }
  }

  Future<void> ensureUnlockedDocument(
    DocumentReference<Map<String, dynamic>> ref, {
    String dateField = 'date',
    DateTime? cachedLockedBefore,
  }) async {
    final snap = await ref.get();
    if (!snap.exists) return;

    final date = _timestampToDate(snap.data()?[dateField]);
    await ensureUnlockedDate(date, cachedLockedBefore: cachedLockedBefore);
  }

  DateTime? _timestampToDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

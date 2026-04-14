import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';

final approvalConfigRepositoryProvider = Provider<ApprovalConfigRepository>((
  ref,
) {
  return ApprovalConfigRepository(firestore: FirebaseFirestore.instance);
});

class ApprovalConfigRepository {
  ApprovalConfigRepository({required this.firestore});

  final FirebaseFirestore firestore;

  DocumentReference<Map<String, dynamic>> get _doc => firestore
      .collection(AppConstants.appSettingsCollection)
      .doc(AppConstants.approvalConfigDocId);

  Stream<ApprovalConfig> watchConfig() {
    return _doc.snapshots().map((doc) {
      if (!doc.exists) return ApprovalConfig.defaults();
      return ApprovalConfig.fromMap(doc.data());
    });
  }

  Future<void> _mergeConfig(Map<String, dynamic> updates) async {
    try {
      await _doc.set({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception('Failed to update config: ${e.message}');
    }
  }

  Future<void> setJobApprovalRequired(bool required) async {
    await _mergeConfig({'jobApprovalRequired': required});
  }

  Future<void> setSharedJobApprovalRequired(bool required) async {
    await _mergeConfig({'sharedJobApprovalRequired': required});
  }

  Future<void> setInOutApprovalRequired(bool required) async {
    await _mergeConfig({'inOutApprovalRequired': required});
  }

  Future<void> setEnforceMinimumBuild(bool required) async {
    await _mergeConfig({'enforceMinimumBuild': required});
  }

  Future<void> setMinimumSupportedBuildNumber(int buildNumber) async {
    final sanitized = buildNumber < 1 ? 1 : buildNumber;
    await _mergeConfig({'minSupportedBuildNumber': sanitized});
  }

  Future<void> setLockedBeforeDate(DateTime? date) async {
    await _mergeConfig({
      'lockedBefore': date == null
          ? FieldValue.delete()
          : Timestamp.fromDate(date),
    });
  }
}

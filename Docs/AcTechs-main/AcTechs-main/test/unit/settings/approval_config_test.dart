import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/approval_config.dart';
import 'package:ac_techs/features/settings/data/approval_config_repository.dart';

void main() {
  group('ApprovalConfig model', () {
    test('defaults returns all approvals required', () {
      final config = ApprovalConfig.defaults();
      expect(config.jobApprovalRequired, isTrue);
      expect(config.sharedJobApprovalRequired, isTrue);
      expect(config.inOutApprovalRequired, isTrue);
      expect(config.enforceMinimumBuild, isFalse);
      expect(config.minSupportedBuildNumber, 1);
      expect(config.lockedBeforeDate, isNull);
    });

    test('fromMap with null data returns defaults', () {
      final config = ApprovalConfig.fromMap(null);
      expect(config.jobApprovalRequired, isTrue);
      expect(config.inOutApprovalRequired, isTrue);
    });

    test('fromMap with empty map returns defaults', () {
      final config = ApprovalConfig.fromMap({});
      expect(config.jobApprovalRequired, isTrue);
      expect(config.sharedJobApprovalRequired, isTrue);
    });

    test('fromMap parses boolean fields correctly', () {
      final config = ApprovalConfig.fromMap({
        'jobApprovalRequired': false,
        'sharedJobApprovalRequired': false,
        'inOutApprovalRequired': false,
        'enforceMinimumBuild': true,
        'minSupportedBuildNumber': 42,
      });
      expect(config.jobApprovalRequired, isFalse);
      expect(config.sharedJobApprovalRequired, isFalse);
      expect(config.inOutApprovalRequired, isFalse);
      expect(config.enforceMinimumBuild, isTrue);
      expect(config.minSupportedBuildNumber, 42);
    });

    test('fromMap clamps minSupportedBuildNumber below 1', () {
      final config = ApprovalConfig.fromMap({'minSupportedBuildNumber': 0});
      expect(config.minSupportedBuildNumber, 1);

      final config2 = ApprovalConfig.fromMap({'minSupportedBuildNumber': -5});
      expect(config2.minSupportedBuildNumber, 1);
    });

    test('fromMap handles non-bool values as defaults', () {
      final config = ApprovalConfig.fromMap({
        'jobApprovalRequired': 'yes', // string, not bool
        'inOutApprovalRequired': 123, // int, not bool
      });
      expect(config.jobApprovalRequired, isTrue); // defaults
      expect(config.inOutApprovalRequired, isTrue); // defaults
    });

    test('fromMap parses Timestamp lockedBefore', () {
      final now = DateTime(2025, 6, 15);
      final config = ApprovalConfig.fromMap({
        'lockedBefore': Timestamp.fromDate(now),
      });
      expect(config.lockedBeforeDate, now);
    });

    test('fromMap parses DateTime lockedBefore', () {
      final now = DateTime(2025, 6, 15);
      final config = ApprovalConfig.fromMap({'lockedBefore': now});
      expect(config.lockedBeforeDate, now);
    });

    test('copyWith preserves existing values when not overridden', () {
      final original = ApprovalConfig(
        jobApprovalRequired: false,
        sharedJobApprovalRequired: false,
        inOutApprovalRequired: false,
        enforceMinimumBuild: true,
        minSupportedBuildNumber: 10,
        lockedBeforeDate: DateTime(2025, 1, 1),
      );
      final copy = original.copyWith(jobApprovalRequired: true);
      expect(copy.jobApprovalRequired, isTrue);
      expect(copy.sharedJobApprovalRequired, isFalse); // preserved
      expect(copy.inOutApprovalRequired, isFalse); // preserved
      expect(copy.minSupportedBuildNumber, 10); // preserved
    });

    test('copyWith clearLockedBeforeDate clears date', () {
      final original = ApprovalConfig(
        jobApprovalRequired: true,
        sharedJobApprovalRequired: true,
        inOutApprovalRequired: true,
        enforceMinimumBuild: false,
        minSupportedBuildNumber: 1,
        lockedBeforeDate: DateTime(2025, 1, 1),
      );
      final copy = original.copyWith(clearLockedBeforeDate: true);
      expect(copy.lockedBeforeDate, isNull);
    });
  });

  group('ApprovalConfigRepository', () {
    late FakeFirebaseFirestore firestore;
    late ApprovalConfigRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = ApprovalConfigRepository(firestore: firestore);
    });

    test('watchConfig returns defaults when doc does not exist', () async {
      final config = await repository.watchConfig().first;
      expect(config.jobApprovalRequired, isTrue);
      expect(config.inOutApprovalRequired, isTrue);
    });

    test('setJobApprovalRequired updates the config', () async {
      await repository.setJobApprovalRequired(false);

      final doc = await firestore
          .collection(AppConstants.appSettingsCollection)
          .doc(AppConstants.approvalConfigDocId)
          .get();
      expect(doc.data()!['jobApprovalRequired'], false);
    });

    test('setInOutApprovalRequired updates the config', () async {
      await repository.setInOutApprovalRequired(false);

      final doc = await firestore
          .collection(AppConstants.appSettingsCollection)
          .doc(AppConstants.approvalConfigDocId)
          .get();
      expect(doc.data()!['inOutApprovalRequired'], false);
    });

    test('setMinimumSupportedBuildNumber clamps below 1', () async {
      await repository.setMinimumSupportedBuildNumber(0);

      final doc = await firestore
          .collection(AppConstants.appSettingsCollection)
          .doc(AppConstants.approvalConfigDocId)
          .get();
      expect(doc.data()!['minSupportedBuildNumber'], 1);
    });

    test('setLockedBeforeDate with null deletes field', () async {
      // First set a date
      await repository.setLockedBeforeDate(DateTime(2025, 1, 1));
      // Then clear it
      await repository.setLockedBeforeDate(null);

      // FakeFirebaseFirestore may or may not remove the field entirely
      // but the logical result from watchConfig should show null
      final config = await repository.watchConfig().first;
      expect(config.lockedBeforeDate, isNull);
    });

    test('watchConfig reflects changed values', () async {
      await repository.setJobApprovalRequired(false);
      await repository.setInOutApprovalRequired(false);

      final config = await repository.watchConfig().first;
      expect(config.jobApprovalRequired, isFalse);
      expect(config.inOutApprovalRequired, isFalse);
    });
  });
}

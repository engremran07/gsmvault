import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late JobRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = JobRepository(
      firestore: firestore,
      currentUid: () => 'admin-1',
    );
  });

  /// Mirrors [JobRepository._sharedAggregateDocId] for test seeding.
  String derivedDocId(String groupKey) {
    final safe = groupKey.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    final scoped =
        'shared_${safe.isEmpty ? DateTime.now().millisecondsSinceEpoch : safe}';
    return scoped.length > 140 ? scoped.substring(0, 140) : scoped;
  }

  Future<void> seedAggregate({
    required String groupKey,
    required DateTime createdAt,
    int sharedInvoiceSplitUnits = 4,
    int consumedSplitUnits = 0,
  }) async {
    await firestore
        .collection(AppConstants.sharedInstallAggregatesCollection)
        .doc(derivedDocId(groupKey))
        .set({
          'groupKey': groupKey,
          'companyId': 'c1',
          'companyName': 'Company',
          'createdBy': 'tech-1',
          'teamMemberIds': ['tech-1', 'tech-2'],
          'teamMemberNames': ['Tech One', 'Tech Two'],
          'sharedInvoiceSplitUnits': sharedInvoiceSplitUnits,
          'sharedInvoiceWindowUnits': 0,
          'sharedInvoiceFreestandingUnits': 0,
          'sharedInvoiceUninstallSplitUnits': 0,
          'sharedInvoiceUninstallWindowUnits': 0,
          'sharedInvoiceUninstallFreestandingUnits': 0,
          'sharedInvoiceBracketCount': 0,
          'sharedDeliveryTeamCount': 2,
          'sharedInvoiceDeliveryAmount': 0.0,
          'consumedSplitUnits': consumedSplitUnits,
          'consumedWindowUnits': 0,
          'consumedFreestandingUnits': 0,
          'consumedUninstallSplitUnits': 0,
          'consumedUninstallWindowUnits': 0,
          'consumedUninstallFreestandingUnits': 0,
          'consumedBracketCount': 0,
          'consumedDeliveryAmount': 0.0,
          'clientName': 'Client',
          'clientContact': '',
          'createdAt': Timestamp.fromDate(createdAt),
          'updatedAt': Timestamp.fromDate(createdAt),
          'isDeleted': false,
          'deletedAt': null,
        });
  }

  group('fetchStaleSharedAggregates', () {
    test('returns incomplete aggregates older than threshold', () async {
      final staleDate = DateTime.now().subtract(const Duration(days: 10));
      await seedAggregate(
        groupKey: 'c1-inv001',
        createdAt: staleDate,
        consumedSplitUnits: 2, // not fully consumed
      );

      final stale = await repository.fetchStaleSharedAggregates();
      expect(stale, hasLength(1));
      expect(stale.first.groupKey, 'c1-inv001');
    });

    test('excludes fully consumed aggregates', () async {
      final staleDate = DateTime.now().subtract(const Duration(days: 10));
      await seedAggregate(
        groupKey: 'c1-inv002',
        createdAt: staleDate,
        sharedInvoiceSplitUnits: 4,
        consumedSplitUnits: 4, // fully consumed
      );

      final stale = await repository.fetchStaleSharedAggregates();
      expect(stale, isEmpty);
    });

    test('excludes recent aggregates within threshold', () async {
      final recentDate = DateTime.now().subtract(const Duration(days: 2));
      await seedAggregate(
        groupKey: 'c1-inv003',
        createdAt: recentDate,
        consumedSplitUnits: 0,
      );

      final stale = await repository.fetchStaleSharedAggregates();
      expect(stale, isEmpty);
    });

    test('respects custom threshold', () async {
      final threeWeeksAgo = DateTime.now().subtract(const Duration(days: 21));
      await seedAggregate(
        groupKey: 'c1-inv004',
        createdAt: threeWeeksAgo,
        consumedSplitUnits: 1,
      );

      // 30-day threshold — 21-day-old aggregate should NOT be stale
      final stale30 = await repository.fetchStaleSharedAggregates(
        threshold: const Duration(days: 30),
      );
      expect(stale30, isEmpty);

      // 14-day threshold — 21-day-old aggregate should be stale
      final stale14 = await repository.fetchStaleSharedAggregates(
        threshold: const Duration(days: 14),
      );
      expect(stale14, hasLength(1));
    });
  });

  group('archiveStaleSharedInstall', () {
    test('soft-deletes aggregate and associated jobs', () async {
      const groupKey = 'c1-inv005';
      final staleDate = DateTime.now().subtract(const Duration(days: 10));

      await seedAggregate(groupKey: groupKey, createdAt: staleDate);

      // Seed associated jobs
      for (var i = 0; i < 2; i++) {
        await firestore.collection(AppConstants.jobsCollection).add({
          'techId': 'tech-${i + 1}',
          'sharedInstallGroupKey': groupKey,
          'isDeleted': false,
          'deletedAt': null,
          'status': 'pending',
        });
      }

      await repository.archiveStaleSharedInstall(groupKey);

      // Verify aggregate is soft-deleted
      final aggDoc = await firestore
          .collection(AppConstants.sharedInstallAggregatesCollection)
          .doc(derivedDocId(groupKey))
          .get();
      expect(aggDoc.data()!['isDeleted'], true);
      expect(aggDoc.data()!['deletedAt'], isNotNull);

      // Verify jobs are soft-deleted
      final jobDocs = await firestore
          .collection(AppConstants.jobsCollection)
          .get();
      for (final doc in jobDocs.docs) {
        expect(doc.data()['isDeleted'], true);
        expect(doc.data()['deletedAt'], isNotNull);
      }
    });

    test('does not affect jobs from other group keys', () async {
      const targetKey = 'c1-inv006';
      const otherKey = 'c1-inv007';
      final staleDate = DateTime.now().subtract(const Duration(days: 10));

      await seedAggregate(groupKey: targetKey, createdAt: staleDate);

      // Job in target group
      await firestore.collection(AppConstants.jobsCollection).add({
        'techId': 'tech-1',
        'sharedInstallGroupKey': targetKey,
        'isDeleted': false,
        'deletedAt': null,
      });

      // Job in different group
      final otherJobRef = await firestore
          .collection(AppConstants.jobsCollection)
          .add({
            'techId': 'tech-1',
            'sharedInstallGroupKey': otherKey,
            'isDeleted': false,
            'deletedAt': null,
          });

      await repository.archiveStaleSharedInstall(targetKey);

      // Other group's job should be untouched
      final otherJob = await otherJobRef.get();
      expect(otherJob.data()!['isDeleted'], false);
    });
  });
}

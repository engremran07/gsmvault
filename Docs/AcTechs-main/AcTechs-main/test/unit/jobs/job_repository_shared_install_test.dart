import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late JobRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    // Provide a stub currentUid so the conflict guard doesn't hit FirebaseAuth.instance
    repository = JobRepository(
      firestore: firestore,
      currentUid: () => 'tech-1',
    );
  });

  JobModel buildSharedJob({
    required String techId,
    required String techName,
    required String invoiceNumber,
    required int splitShare,
  }) {
    final now = DateTime(2024, 1, 10, 9);
    return JobModel(
      techId: techId,
      techName: techName,
      companyId: 'company-1',
      companyName: 'Company',
      invoiceNumber: invoiceNumber,
      clientName: 'Client',
      acUnits: [
        AcUnit(type: AppConstants.unitTypeSplitAc, quantity: splitShare),
      ],
      status: JobStatus.pending,
      expenses: 0,
      isSharedInstall: true,
      sharedInstallGroupKey: 'company-1-${invoiceNumber.toLowerCase()}',
      sharedInvoiceTotalUnits: 4,
      sharedContributionUnits: splitShare,
      sharedInvoiceSplitUnits: 4,
      sharedInvoiceWindowUnits: 0,
      sharedInvoiceFreestandingUnits: 0,
      sharedInvoiceBracketCount: 0,
      sharedDeliveryTeamCount: 0,
      sharedInvoiceDeliveryAmount: 0,
      techSplitShare: splitShare,
      date: now,
      submittedAt: now,
    );
  }

  JobModel buildSoloJob({
    required String techId,
    required String techName,
    required String invoiceNumber,
    required String companyId,
    required String companyName,
    JobStatus status = JobStatus.approved,
  }) {
    final now = DateTime(2024, 1, 10, 9);
    return JobModel(
      techId: techId,
      techName: techName,
      companyId: companyId,
      companyName: companyName,
      invoiceNumber: invoiceNumber,
      clientName: 'Client',
      acUnits: const [AcUnit(type: AppConstants.unitTypeSplitAc, quantity: 1)],
      status: status,
      expenses: 0,
      isSharedInstall: false,
      date: now,
      submittedAt: now,
    );
  }

  JobModel buildImportedJob({
    required String techId,
    required String techName,
    required String invoiceNumber,
  }) {
    final now = DateTime(2023, 12, 5, 14, 30);
    return JobModel(
      techId: techId,
      techName: techName,
      companyId: 'company-1',
      companyName: 'Company',
      invoiceNumber: invoiceNumber,
      clientName: 'Imported Client',
      acUnits: const [AcUnit(type: AppConstants.unitTypeSplitAc, quantity: 1)],
      status: JobStatus.approved,
      expenses: 0,
      date: now,
      submittedAt: now,
    );
  }

  test(
    'shared job submission creates and updates aggregate reservations',
    () async {
      await repository.submitJob(
        buildSharedJob(
          techId: 'tech-1',
          techName: 'Tech One',
          invoiceNumber: 'INV-100',
          splitShare: 2,
        ),
      );
      await repository.submitJob(
        buildSharedJob(
          techId: 'tech-2',
          techName: 'Tech Two',
          invoiceNumber: 'INV-100',
          splitShare: 1,
        ),
      );

      final aggregateSnap = await firestore
          .collection(AppConstants.sharedInstallAggregatesCollection)
          .get();

      expect(aggregateSnap.docs, hasLength(1));
      expect(aggregateSnap.docs.single.data()['consumedSplitUnits'], 3);
      expect(aggregateSnap.docs.single.data()['groupKey'], 'company-1-inv-100');
    },
  );

  test('rejecting a shared job releases only that job reservation', () async {
    await repository.submitJob(
      buildSharedJob(
        techId: 'tech-1',
        techName: 'Tech One',
        invoiceNumber: 'INV-200',
        splitShare: 2,
      ),
    );
    await repository.submitJob(
      buildSharedJob(
        techId: 'tech-2',
        techName: 'Tech Two',
        invoiceNumber: 'INV-200',
        splitShare: 1,
      ),
    );

    final jobsSnap = await firestore
        .collection(AppConstants.jobsCollection)
        .orderBy('techId')
        .get();
    final firstJobId = jobsSnap.docs.first.id;

    await repository.rejectJob(firstJobId, 'admin-1', 'Mismatch');

    final aggregateSnap = await firestore
        .collection(AppConstants.sharedInstallAggregatesCollection)
        .get();
    final jobHistorySnap = await firestore
        .collection(AppConstants.jobsCollection)
        .doc(firstJobId)
        .collection('history')
        .get();

    expect(aggregateSnap.docs.single.data()['consumedSplitUnits'], 1);
    expect(jobHistorySnap.docs, hasLength(1));
    expect(jobHistorySnap.docs.single.data()['newStatus'], 'rejected');
    expect(jobHistorySnap.docs.single.data()['reason'], 'Mismatch');
  });

  test('approving a shared job writes history entry', () async {
    await repository.submitJob(
      buildSharedJob(
        techId: 'tech-1',
        techName: 'Tech One',
        invoiceNumber: 'INV-250',
        splitShare: 1,
      ),
    );

    final jobsSnap = await firestore
        .collection(AppConstants.jobsCollection)
        .get();
    final jobId = jobsSnap.docs.single.id;

    await repository.approveJob(jobId, 'admin-1');

    final historySnap = await firestore
        .collection(AppConstants.jobsCollection)
        .doc(jobId)
        .collection('history')
        .get();

    expect(historySnap.docs, hasLength(1));
    expect(historySnap.docs.single.data()['previousStatus'], 'pending');
    expect(historySnap.docs.single.data()['newStatus'], 'approved');
  });

  test('bulkApproveJobs approves pending jobs and writes history', () async {
    await repository.submitJob(
      buildSharedJob(
        techId: 'tech-1',
        techName: 'Tech One',
        invoiceNumber: 'INV-260',
        splitShare: 1,
      ),
    );
    await repository.submitJob(
      buildSharedJob(
        techId: 'tech-2',
        techName: 'Tech Two',
        invoiceNumber: 'INV-261',
        splitShare: 1,
      ),
    );

    final jobsSnap = await firestore
        .collection(AppConstants.jobsCollection)
        .get();
    final jobIds = jobsSnap.docs.map((doc) => doc.id).toList(growable: false);

    await repository.bulkApproveJobs(jobIds, 'admin-9');

    for (final jobId in jobIds) {
      final jobSnap = await firestore
          .collection(AppConstants.jobsCollection)
          .doc(jobId)
          .get();
      final historySnap = await firestore
          .collection(AppConstants.jobsCollection)
          .doc(jobId)
          .collection('history')
          .get();

      expect(jobSnap.data()?['status'], 'approved');
      expect(jobSnap.data()?['approvedBy'], 'admin-9');
      expect(historySnap.docs, hasLength(1));
      expect(historySnap.docs.single.data()['newStatus'], 'approved');
    }
  });

  test('rejecting an approved shared job is blocked by immutability', () async {
    final jobRef = await firestore.collection(AppConstants.jobsCollection).add({
      ...buildSharedJob(
        techId: 'tech-1',
        techName: 'Tech One',
        invoiceNumber: 'INV-300',
        splitShare: 1,
      ).toFirestore(),
      'status': 'approved',
      'approvedBy': 'admin-1',
      'reviewedAt': Timestamp.fromDate(DateTime(2024, 1, 10, 10)),
    });

    await expectLater(
      () => repository.rejectJob(jobRef.id, 'admin-2', 'Late correction'),
      throwsA(isA<JobException>()),
    );
  });

  test(
    'same-company duplicate invoice is blocked across technicians',
    () async {
      await repository.submitJob(
        buildSoloJob(
          techId: 'tech-1',
          techName: 'Tech One',
          invoiceNumber: 'INV-500',
          companyId: 'company-1',
          companyName: 'Company One',
        ),
      );

      await expectLater(
        () => repository.submitJob(
          buildSoloJob(
            techId: 'tech-2',
            techName: 'Tech Two',
            invoiceNumber: 'INV-500',
            companyId: 'company-1',
            companyName: 'Company One',
          ),
        ),
        throwsA(isA<JobException>()),
      );
    },
  );

  test('cross-company duplicate solo invoice is blocked', () async {
    await repository.submitJob(
      buildSoloJob(
        techId: 'tech-1',
        techName: 'Tech One',
        invoiceNumber: 'INV-600',
        companyId: 'company-1',
        companyName: 'Company One',
      ),
    );

    await expectLater(
      () => repository.submitJob(
        buildSoloJob(
          techId: 'tech-2',
          techName: 'Tech Two',
          invoiceNumber: 'INV-600',
          companyId: 'company-2',
          companyName: 'Company Two',
        ),
      ),
      throwsA(isA<JobException>()),
    );
  });

  test('cross-company duplicate shared invoice is blocked', () async {
    await repository.submitJob(
      buildSharedJob(
        techId: 'tech-1',
        techName: 'Tech One',
        invoiceNumber: 'INV-700',
        splitShare: 1,
      ),
    );

    await expectLater(
      () => repository.submitJob(
        buildSharedJob(
          techId: 'tech-2',
          techName: 'Tech Two',
          invoiceNumber: 'INV-700',
          splitShare: 1,
        ).copyWith(
          companyId: 'company-2',
          companyName: 'Company Two',
          sharedInstallGroupKey: 'company-2-inv-700',
        ),
      ),
      throwsA(isA<JobException>()),
    );
  });

  test(
    'existing shared invoice claim allows another shared submission',
    () async {
      await firestore
          .collection(AppConstants.invoiceClaimsCollection)
          .doc('710')
          .set({
            'invoiceNumber': '710',
            'companyId': 'company-1',
            'companyName': 'Company',
            'reuseMode': 'shared',
            'activeJobCount': 1,
            'createdBy': 'tech-1',
            'createdAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
            'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
          });

      await repository.submitJob(
        buildSharedJob(
          techId: 'tech-2',
          techName: 'Tech Two',
          invoiceNumber: 'INV-710',
          splitShare: 1,
        ),
      );

      final claimSnap = await firestore
          .collection(AppConstants.invoiceClaimsCollection)
          .doc('710')
          .get();
      final jobsSnap = await firestore
          .collection(AppConstants.jobsCollection)
          .get();

      expect(claimSnap.data()?['activeJobCount'], 2);
      expect(jobsSnap.docs, hasLength(1));
    },
  );

  test(
    'existing solo invoice claim blocks resubmission without job scan',
    () async {
      await firestore
          .collection(AppConstants.invoiceClaimsCollection)
          .doc('720')
          .set({
            'invoiceNumber': '720',
            'companyId': 'company-1',
            'companyName': 'Company One',
            'reuseMode': 'solo',
            'activeJobCount': 1,
            'createdBy': 'tech-1',
            'createdAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
            'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
          });

      await expectLater(
        () => repository.submitJob(
          buildSoloJob(
            techId: 'tech-2',
            techName: 'Tech Two',
            invoiceNumber: 'INV-720',
            companyId: 'company-1',
            companyName: 'Company One',
          ),
        ),
        throwsA(isA<JobException>()),
      );
    },
  );

  test('shared installs reject unsupported cassette units', () async {
    final now = DateTime(2024, 1, 10, 9);
    final job = JobModel(
      techId: 'tech-1',
      techName: 'Tech One',
      companyId: 'company-1',
      companyName: 'Company',
      invoiceNumber: 'INV-800',
      clientName: 'Client',
      acUnits: const [
        AcUnit(type: AppConstants.unitTypeCassetteAc, quantity: 1),
      ],
      status: JobStatus.pending,
      expenses: 0,
      isSharedInstall: true,
      sharedInstallGroupKey: 'company-1-inv-800',
      sharedInvoiceTotalUnits: 1,
      sharedContributionUnits: 1,
      sharedInvoiceSplitUnits: 0,
      sharedInvoiceWindowUnits: 0,
      sharedInvoiceFreestandingUnits: 0,
      sharedInvoiceBracketCount: 0,
      sharedDeliveryTeamCount: 0,
      sharedInvoiceDeliveryAmount: 0,
      date: now,
      submittedAt: now,
    );

    await expectLater(
      () => repository.submitJob(job),
      throwsA(isA<JobException>()),
    );
  });

  test('historical import is idempotent for deterministic job ids', () async {
    final importedJob = buildImportedJob(
      techId: 'tech-import-1',
      techName: 'Import Tech',
      invoiceNumber: 'INV-900',
    );

    final firstPass = await repository.importJobs([importedJob]);
    final secondPass = await repository.importJobs([importedJob]);

    final jobsSnap = await firestore
        .collection(AppConstants.jobsCollection)
        .get();
    final claimsSnap = await firestore
        .collection(AppConstants.invoiceClaimsCollection)
        .get();

    expect(firstPass, 1);
    expect(secondPass, 0);
    expect(jobsSnap.docs, hasLength(1));
    expect(claimsSnap.docs, hasLength(1));
    expect(claimsSnap.docs.single.data()['activeJobCount'], 1);
    expect(claimsSnap.docs.single.data()['invoiceNumber'], '900');
  });

  // ── teamMemberIds contract tests ─────────────────────────────────────────

  test('teamMemberIds[0] equals the first submitting tech uid', () async {
    await repository.submitJob(
      buildSharedJob(
        techId: 'tech-1',
        techName: 'Tech One',
        invoiceNumber: 'INV-1100',
        splitShare: 1,
      ),
    );

    final aggregateSnap = await firestore
        .collection(AppConstants.sharedInstallAggregatesCollection)
        .get();

    expect(aggregateSnap.docs, hasLength(1));
    final teamMemberIds =
        aggregateSnap.docs.single.data()['teamMemberIds'] as List<dynamic>;
    expect(teamMemberIds, contains('tech-1'));
    expect(teamMemberIds.first, 'tech-1');
  });

  test('second tech contribution adds uid to teamMemberIds', () async {
    await repository.submitJob(
      buildSharedJob(
        techId: 'tech-1',
        techName: 'Tech One',
        invoiceNumber: 'INV-1200',
        splitShare: 2,
      ),
    );

    // Seed the aggregate so tech-2 is already enrolled (simulates UI adding team roster)
    final aggregateSnap = await firestore
        .collection(AppConstants.sharedInstallAggregatesCollection)
        .get();
    await firestore
        .collection(AppConstants.sharedInstallAggregatesCollection)
        .doc(aggregateSnap.docs.single.id)
        .update({
          'teamMemberIds': FieldValue.arrayUnion(['tech-2']),
        });

    final repo2 = JobRepository(
      firestore: firestore,
      currentUid: () => 'tech-2',
    );
    await repo2.submitJob(
      buildSharedJob(
        techId: 'tech-2',
        techName: 'Tech Two',
        invoiceNumber: 'INV-1200',
        splitShare: 1,
      ),
    );

    final updatedSnap = await firestore
        .collection(AppConstants.sharedInstallAggregatesCollection)
        .get();
    final teamMemberIds =
        updatedSnap.docs.single.data()['teamMemberIds'] as List<dynamic>;
    expect(teamMemberIds, containsAll(['tech-1', 'tech-2']));
  });

  test('tech not in teamMemberIds is rejected with notTeamMember', () async {
    // Pre-seed aggregate with tech-existing-0 as sole member.
    // Doc ID must match _sharedAggregateDocId('company-1-inv-1300') = 'shared_company-1-inv-1300'.
    const groupKey = 'company-1-inv-1300';
    await firestore
        .collection(AppConstants.sharedInstallAggregatesCollection)
        .doc('shared_company-1-inv-1300')
        .set({
          'groupKey': groupKey,
          'companyId': 'company-1',
          'companyName': 'Company',
          'invoiceNumber': 'INV-1300',
          'sharedInvoiceSplitUnits': 4,
          'sharedInvoiceWindowUnits': 0,
          'sharedInvoiceFreestandingUnits': 0,
          'sharedInvoiceUninstallSplitUnits': 0,
          'sharedInvoiceUninstallWindowUnits': 0,
          'sharedInvoiceUninstallFreestandingUnits': 0,
          'sharedInvoiceBracketCount': 0,
          'sharedDeliveryTeamCount': 0, // must match buildSharedJob default
          'sharedInvoiceDeliveryAmount': 0,
          'consumedSplitUnits': 1,
          'consumedWindowUnits': 0,
          'consumedFreestandingUnits': 0,
          'consumedUninstallSplitUnits': 0,
          'consumedUninstallWindowUnits': 0,
          'consumedUninstallFreestandingUnits': 0,
          'consumedBracketCount': 0,
          'consumedDeliveryAmount': 0.0,
          'teamMemberIds': ['tech-existing-0'],
          'teamMemberNames': ['Tech Existing 0'],
          'createdBy': 'tech-existing-0',
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
        });

    // tech-1 (currentUid) is NOT in teamMemberIds → should throw notTeamMember
    await expectLater(
      () => repository.submitJob(
        buildSharedJob(
          techId: 'tech-1',
          techName: 'Tech One',
          invoiceNumber: 'INV-1300',
          splitShare: 1,
        ),
      ),
      throwsA(isA<JobException>()),
    );
  });

  test(
    'legacy aggregate without teamMemberIds allows any tech to contribute',
    () async {
      const groupKey = 'company-1-inv-1400';
      // Write a "legacy" aggregate that has no teamMemberIds field.
      // Doc ID must match _sharedAggregateDocId('company-1-inv-1400') = 'shared_company-1-inv-1400'.
      await firestore
          .collection(AppConstants.sharedInstallAggregatesCollection)
          .doc('shared_company-1-inv-1400')
          .set({
            'groupKey': groupKey,
            'companyId': 'company-1',
            'companyName': 'Company',
            'invoiceNumber': 'INV-1400',
            'sharedInvoiceSplitUnits': 4,
            'sharedInvoiceWindowUnits': 0,
            'sharedInvoiceFreestandingUnits': 0,
            'sharedInvoiceUninstallSplitUnits': 0,
            'sharedInvoiceUninstallWindowUnits': 0,
            'sharedInvoiceUninstallFreestandingUnits': 0,
            'sharedInvoiceBracketCount': 0,
            'sharedDeliveryTeamCount': 0, // must match buildSharedJob default
            'sharedInvoiceDeliveryAmount': 0,
            'consumedSplitUnits': 1,
            'consumedWindowUnits': 0,
            'consumedFreestandingUnits': 0,
            'consumedUninstallSplitUnits': 0,
            'consumedUninstallWindowUnits': 0,
            'consumedUninstallFreestandingUnits': 0,
            'consumedBracketCount': 0,
            'consumedDeliveryAmount': 0.0,
            'createdBy': 'tech-other',
            'createdAt': Timestamp.fromDate(DateTime(2023, 12, 1, 9)),
            'updatedAt': Timestamp.fromDate(DateTime(2023, 12, 1, 9)),
            // intentionally NO teamMemberIds field
          });

      // tech-1 is not createdBy, but legacy aggregate skips membership check
      await repository.submitJob(
        buildSharedJob(
          techId: 'tech-1',
          techName: 'Tech One',
          invoiceNumber: 'INV-1400',
          splitShare: 1,
        ),
      );

      // Doc ID uses the 'shared_' prefix from _sharedAggregateDocId
      final updatedSnap = await firestore
          .collection(AppConstants.sharedInstallAggregatesCollection)
          .doc('shared_company-1-inv-1400')
          .get();
      expect(updatedSnap.data()?['consumedSplitUnits'], greaterThan(1));
    },
  );
}

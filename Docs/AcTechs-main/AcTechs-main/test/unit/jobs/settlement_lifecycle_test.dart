import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late JobRepository repository;

  Future<DocumentReference<Map<String, dynamic>>> seedApprovedJob({
    required String id,
    required String techId,
    String settlementStatus = 'unpaid',
    int settlementRound = 0,
    String settlementBatchId = '',
  }) async {
    final ref = firestore.collection(AppConstants.jobsCollection).doc(id);
    await ref.set({
      'techId': techId,
      'techName': 'Tech $techId',
      'companyId': 'company-1',
      'companyName': 'Company',
      'invoiceNumber': 'INV-$id',
      'clientName': 'Client',
      'acUnits': const [
        {'type': AppConstants.unitTypeSplitAc, 'quantity': 1},
      ],
      'status': JobStatus.approved.name,
      'expenses': 0,
      'date': Timestamp.fromDate(DateTime(2026, 4, 1)),
      'submittedAt': Timestamp.fromDate(DateTime(2026, 4, 1)),
      'approvedBy': 'admin-1',
      'reviewedAt': Timestamp.fromDate(DateTime(2026, 4, 1, 1)),
      'settlementStatus': settlementStatus,
      'settlementBatchId': settlementBatchId,
      'settlementRound': settlementRound,
      'settlementAmount': 100,
      'settlementPaymentMethod': 'bank_transfer',
      'settlementAdminNote': '',
      'settlementTechnicianComment': '',
      'settlementRequestedBy': 'admin-1',
      'settlementRequestedAt': Timestamp.fromDate(DateTime(2026, 4, 1, 2)),
      'settlementRespondedAt': null,
      'settlementPaidAt': Timestamp.fromDate(DateTime(2026, 4, 1, 2)),
      'settlementCorrectedAt': null,
      'isSharedInstall': false,
    });
    return ref;
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = JobRepository(
      firestore: firestore,
      currentUid: () => 'tech-1',
    );
  });

  test(
    'markJobsAsPaid writes awaiting settlement metadata transactionally',
    () async {
      final a = await seedApprovedJob(id: 'a', techId: 'tech-1');
      final b = await seedApprovedJob(id: 'b', techId: 'tech-1');

      final batchId = await repository.markJobsAsPaid(
        [a.id, b.id],
        'admin-1',
        amountPerJob: 150,
        paymentMethod: 'cash',
        adminNote: 'weekly payout',
      );

      final aSnap = await a.get();
      expect(aSnap.data()?['settlementStatus'], 'awaiting_technician');
      expect(aSnap.data()?['settlementBatchId'], batchId);
      expect(aSnap.data()?['settlementAmount'], 150);
      expect(aSnap.data()?['settlementPaymentMethod'], 'cash');

      final history = await a.collection('history').get();
      expect(history.docs, hasLength(1));
      expect(history.docs.single.data()['action'], 'mark_paid');
    },
  );

  test(
    'markJobsAsPaid throws when jobs belong to different technicians',
    () async {
      final a = await seedApprovedJob(id: 'a1', techId: 'tech-1');
      final b = await seedApprovedJob(id: 'b1', techId: 'tech-2');

      await expectLater(
        () => repository.markJobsAsPaid([a.id, b.id], 'admin-1'),
        throwsA(isA<JobException>()),
      );
    },
  );

  test(
    'confirmSettlementBatch sets confirmed and responded timestamp',
    () async {
      await seedApprovedJob(
        id: 'c1',
        techId: 'tech-1',
        settlementStatus: 'awaiting_technician',
        settlementRound: 1,
        settlementBatchId: 'pay-1',
      );

      await repository.confirmSettlementBatch('pay-1');

      final snap = await firestore
          .collection(AppConstants.jobsCollection)
          .doc('c1')
          .get();
      expect(snap.data()?['settlementStatus'], 'confirmed');
      expect(snap.data()?['settlementRespondedAt'], isA<Timestamp>());
    },
  );

  test('rejectSettlementBatch round 1 sets correction_required', () async {
    await seedApprovedJob(
      id: 'r1',
      techId: 'tech-1',
      settlementStatus: 'awaiting_technician',
      settlementRound: 1,
      settlementBatchId: 'pay-r1',
    );

    await repository.rejectSettlementBatch('pay-r1', 'wrong amount');

    final snap = await firestore
        .collection(AppConstants.jobsCollection)
        .doc('r1')
        .get();
    expect(snap.data()?['settlementStatus'], 'correction_required');
    expect(snap.data()?['settlementTechnicianComment'], 'wrong amount');
  });

  test('rejectSettlementBatch round 2 sets disputed_final', () async {
    await seedApprovedJob(
      id: 'r2',
      techId: 'tech-1',
      settlementStatus: 'awaiting_technician',
      settlementRound: 2,
      settlementBatchId: 'pay-r2',
    );

    await repository.rejectSettlementBatch('pay-r2', 'still wrong');

    final snap = await firestore
        .collection(AppConstants.jobsCollection)
        .doc('r2')
        .get();
    expect(snap.data()?['settlementStatus'], 'disputed_final');
  });

  test(
    'resubmitSettlementBatch sets awaiting_technician and round 2',
    () async {
      await seedApprovedJob(
        id: 's1',
        techId: 'tech-1',
        settlementStatus: 'correction_required',
        settlementRound: 1,
        settlementBatchId: 'pay-s1',
      );

      await repository.resubmitSettlementBatch(
        'pay-s1',
        'admin-1',
        adminNote: 'fixed',
      );

      final snap = await firestore
          .collection(AppConstants.jobsCollection)
          .doc('s1')
          .get();
      expect(snap.data()?['settlementStatus'], 'awaiting_technician');
      expect(snap.data()?['settlementRound'], 2);
    },
  );

  test(
    'resubmitSettlementBatch throws when correction cycle exceeded',
    () async {
      await seedApprovedJob(
        id: 's2',
        techId: 'tech-1',
        settlementStatus: 'correction_required',
        settlementRound: 2,
        settlementBatchId: 'pay-s2',
      );

      await expectLater(
        () => repository.resubmitSettlementBatch('pay-s2', 'admin-1'),
        throwsA(isA<JobException>()),
      );
    },
  );

  test('resolveDisputedSettlement moves disputed_final to confirmed', () async {
    await seedApprovedJob(
      id: 'd1',
      techId: 'tech-1',
      settlementStatus: 'disputed_final',
      settlementRound: 2,
      settlementBatchId: 'pay-d1',
    );

    await repository.resolveDisputedSettlement(
      'pay-d1',
      'admin-1',
      resolutionNote: 'resolved',
    );

    final snap = await firestore
        .collection(AppConstants.jobsCollection)
        .doc('d1')
        .get();
    expect(snap.data()?['settlementStatus'], 'confirmed');
    expect(snap.data()?['settlementAdminNote'], 'resolved');
  });

  test(
    'importJobs creates invoice_claim records and bumps active count',
    () async {
      final imported = await repository.importJobs([
        JobModel(
          techId: 'tech-1',
          techName: 'Tech One',
          companyId: 'company-1',
          companyName: 'Company',
          invoiceNumber: 'INV-900',
          clientName: 'Client A',
          acUnits: const [
            AcUnit(type: AppConstants.unitTypeSplitAc, quantity: 1),
          ],
          status: JobStatus.approved,
          expenses: 0,
          date: DateTime(2026, 4, 1),
          submittedAt: DateTime(2026, 4, 1),
        ),
        JobModel(
          techId: 'tech-1',
          techName: 'Tech One',
          companyId: 'company-1',
          companyName: 'Company',
          invoiceNumber: 'INV-900',
          clientName: 'Client B',
          acUnits: const [
            AcUnit(type: AppConstants.unitTypeSplitAc, quantity: 1),
          ],
          status: JobStatus.approved,
          expenses: 0,
          date: DateTime(2026, 4, 1),
          submittedAt: DateTime(2026, 4, 1),
        ),
      ]);

      expect(imported, 2);

      final claim = await firestore
          .collection(AppConstants.invoiceClaimsCollection)
          .doc('900')
          .get();
      expect(claim.exists, isTrue);
      expect(claim.data()?['activeJobCount'], 2);
    },
  );
}

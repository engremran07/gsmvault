import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/expenses/data/ac_install_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AcInstallRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = AcInstallRepository(firestore: firestore);
  });

  AcInstallModel buildInstall({
    String status = 'pending',
    String approvedBy = '',
    String adminNote = '',
  }) {
    final now = DateTime(2024, 1, 12, 8);
    return AcInstallModel(
      techId: 'tech-1',
      techName: 'Tech One',
      splitTotal: 2,
      splitShare: 1,
      note: 'Morning install',
      status: AcInstallStatus.values.firstWhere(
        (value) => value.name == status,
      ),
      approvedBy: approvedBy,
      adminNote: adminNote,
      date: now,
      createdAt: now,
    );
  }

  test('addInstall rejects invalid share values before writing', () async {
    final invalidInstall = AcInstallModel(
      techId: 'tech-1',
      techName: 'Tech One',
      splitTotal: 1,
      splitShare: 2,
      date: DateTime(2024, 1, 12, 8),
      createdAt: DateTime(2024, 1, 12, 8),
    );

    await expectLater(
      () => repository.addInstall(invalidInstall),
      throwsA(isA<AcInstallException>()),
    );

    final snap = await firestore
        .collection(AppConstants.acInstallsCollection)
        .get();
    expect(snap.docs, isEmpty);
  });

  test(
    'approveInstall writes approval history and clears stale admin notes',
    () async {
      final doc = await firestore
          .collection(AppConstants.acInstallsCollection)
          .add({
            ...buildInstall(adminNote: 'Old note').toFirestore(),
            'status': 'pending',
            'approvedBy': '',
            'adminNote': 'Old note',
            'date': Timestamp.fromDate(DateTime(2024, 1, 12, 8)),
            'createdAt': Timestamp.fromDate(DateTime(2024, 1, 12, 8)),
            'reviewedAt': null,
          });

      await repository.approveInstall(doc.id, 'admin-1');

      final updated = await doc.get();
      final history = await doc.collection('history').get();

      expect(updated.data()?['status'], 'approved');
      expect(updated.data()?['approvedBy'], 'admin-1');
      expect(updated.data()?['adminNote'], '');
      expect(history.docs, hasLength(1));
      expect(history.docs.single.data()['previousStatus'], 'pending');
      expect(history.docs.single.data()['newStatus'], 'approved');
    },
  );

  test('rejectInstall records rejection reason in history', () async {
    final doc = await firestore
        .collection(AppConstants.acInstallsCollection)
        .add({
          ...buildInstall().toFirestore(),
          'status': 'pending',
          'approvedBy': '',
          'adminNote': '',
          'date': Timestamp.fromDate(DateTime(2024, 1, 12, 8)),
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 12, 8)),
          'reviewedAt': null,
        });

    await repository.rejectInstall(doc.id, 'admin-1', 'Missing invoice match');

    final updated = await doc.get();
    final history = await repository.fetchInstallHistory(doc.id);

    expect(updated.data()?['status'], 'rejected');
    expect(updated.data()?['adminNote'], 'Missing invoice match');
    expect(history, hasLength(1));
    expect(history.single.newStatus, 'rejected');
    expect(history.single.reason, 'Missing invoice match');
  });

  test('archiveInstall rejects approved records', () async {
    final doc = await firestore
        .collection(AppConstants.acInstallsCollection)
        .add({
          ...buildInstall(
            status: 'approved',
            approvedBy: 'admin-1',
          ).toFirestore(),
          'status': 'approved',
          'approvedBy': 'admin-1',
          'adminNote': '',
          'date': Timestamp.fromDate(DateTime(2024, 1, 12, 8)),
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 12, 8)),
          'reviewedAt': Timestamp.fromDate(DateTime(2024, 1, 12, 9)),
        });

    await expectLater(
      () => repository.archiveInstall(doc.id),
      throwsA(isA<AcInstallException>()),
    );
  });
}

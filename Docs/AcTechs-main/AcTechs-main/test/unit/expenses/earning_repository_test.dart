import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/expenses/data/earning_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late EarningRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = EarningRepository(firestore: firestore);
  });

  Future<void> lockBefore(DateTime date) {
    return firestore
        .collection(AppConstants.appSettingsCollection)
        .doc(AppConstants.approvalConfigDocId)
        .set({'lockedBefore': Timestamp.fromDate(date)});
  }

  test(
    'addEarning rejects records dated before the locked period boundary',
    () async {
      await lockBefore(DateTime(2026, 4, 1));

      final earning = EarningModel(
        techId: 'tech-1',
        techName: 'Ali',
        category: 'Scrap Sale',
        amount: 250,
        date: DateTime(2026, 3, 31, 22),
      );

      await expectLater(
        () => repository.addEarning(earning),
        throwsA(isA<PeriodException>()),
      );
    },
  );

  test('archiveEarning rejects records inside the locked period', () async {
    await lockBefore(DateTime(2026, 4, 1));

    final doc = await firestore
        .collection(AppConstants.earningsCollection)
        .add({
          'techId': 'tech-1',
          'techName': 'Ali',
          'category': 'Scrap Sale',
          'amount': 250.0,
          'note': '',
          'paymentType': 'regular',
          'status': 'pending',
          'approvedBy': '',
          'adminNote': '',
          'date': Timestamp.fromDate(DateTime(2026, 3, 31, 8)),
          'createdAt': Timestamp.fromDate(DateTime(2026, 3, 31, 8)),
          'reviewedAt': null,
        });

    await expectLater(
      () => repository.archiveEarning(doc.id),
      throwsA(isA<PeriodException>()),
    );
  });

  test(
    'updateEarning allows updating approved records (Firestore rules gate, not app layer)',
    () async {
      // Previous behavior: _ensureMutableRecord blocked this at app layer.
      // New behavior: Firestore rules gate allows it when !inOutApprovalRequired;
      // unit tests (fake_cloud_firestore) do not enforce rules, so the write succeeds.
      final doc = await firestore
          .collection(AppConstants.earningsCollection)
          .add({
            'techId': 'tech-1',
            'techName': 'Ali',
            'category': 'Scrap Sale',
            'amount': 250.0,
            'note': '',
            'paymentType': 'regular',
            'status': 'approved',
            'approvedBy': 'admin-1',
            'adminNote': '',
            'date': Timestamp.fromDate(DateTime(2026, 4, 1, 8)),
            'createdAt': Timestamp.fromDate(DateTime(2026, 4, 1, 8)),
            'reviewedAt': Timestamp.fromDate(DateTime(2026, 4, 1, 9)),
          });

      final updated = EarningModel(
        id: doc.id,
        techId: 'tech-1',
        techName: 'Ali',
        category: 'Scrap Sale',
        amount: 300,
        paymentType: PaymentType.regular,
        status: EarningApprovalStatus.approved,
        approvedBy: 'admin-1',
        date: DateTime(2026, 4, 1, 8),
        createdAt: DateTime(2026, 4, 1, 8),
        reviewedAt: DateTime(2026, 4, 1, 9),
      );

      await repository.updateEarning(updated);

      final snap = await firestore
          .collection(AppConstants.earningsCollection)
          .doc(doc.id)
          .get();
      expect(snap.data()?['amount'], equals(300.0));
    },
  );
}

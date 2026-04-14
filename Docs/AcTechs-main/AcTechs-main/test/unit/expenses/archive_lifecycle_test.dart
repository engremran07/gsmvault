import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/features/expenses/data/earning_repository.dart';
import 'package:ac_techs/features/expenses/data/expense_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ExpenseRepository expenseRepo;
  late EarningRepository earningRepo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    expenseRepo = ExpenseRepository(firestore: firestore);
    earningRepo = EarningRepository(firestore: firestore);
  });

  // ─── Helper: seed a pending expense doc ───────────────────────────────────

  Future<String> seedExpense({String status = 'pending'}) async {
    final doc = await firestore
        .collection(AppConstants.expensesCollection)
        .add({
          'techId': 'tech-1',
          'techName': 'Ali',
          'category': 'Petrol',
          'amount': 100.0,
          'note': '',
          'expenseType': 'work',
          'status': status,
          'approvedBy': status == 'approved' ? 'admin-1' : '',
          'adminNote': '',
          'date': Timestamp.fromDate(DateTime(2026, 5, 1, 8)),
          'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1, 8)),
          'reviewedAt': status == 'approved'
              ? Timestamp.fromDate(DateTime(2026, 5, 1, 9))
              : null,
          'isDeleted': false,
          'deletedAt': null,
        });
    return doc.id;
  }

  // ─── Helper: seed a pending earning doc ───────────────────────────────────

  Future<String> seedEarning({String status = 'pending'}) async {
    final doc = await firestore
        .collection(AppConstants.earningsCollection)
        .add({
          'techId': 'tech-1',
          'techName': 'Ali',
          'category': 'AC Install',
          'amount': 500.0,
          'note': '',
          'paymentType': 'regular',
          'status': status,
          'approvedBy': status == 'approved' ? 'admin-1' : '',
          'adminNote': '',
          'date': Timestamp.fromDate(DateTime(2026, 5, 1, 8)),
          'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1, 8)),
          'reviewedAt': status == 'approved'
              ? Timestamp.fromDate(DateTime(2026, 5, 1, 9))
              : null,
          'isDeleted': false,
          'deletedAt': null,
        });
    return doc.id;
  }

  // ─── Expense archive / restore tests ─────────────────────────────────────

  group('ExpenseRepository — archive lifecycle', () {
    test('archiveExpense sets isDeleted=true on a pending record', () async {
      final id = await seedExpense();

      await expenseRepo.archiveExpense(id);

      final snap = await firestore
          .collection(AppConstants.expensesCollection)
          .doc(id)
          .get();
      expect(snap.data()?['isDeleted'], isTrue);
      expect(snap.data()?['deletedAt'], isNotNull);
    });

    test('restoreExpense clears isDeleted on an archived record', () async {
      final id = await seedExpense();
      await expenseRepo.archiveExpense(id);

      await expenseRepo.restoreExpense(id);

      final snap = await firestore
          .collection(AppConstants.expensesCollection)
          .doc(id)
          .get();
      expect(snap.data()?['isDeleted'], isFalse);
      expect(snap.data()?['deletedAt'], isNull);
    });

    test(
      'archiveExpense allows archiving approved records (Firestore rules gate, not app layer)',
      () async {
        // When inOutApprovalRequired is false, all new entries are auto-approved.
        // The app layer no longer blocks archive on approved status — Firestore
        // rules are the sole gate. Verify the archive succeeds in unit tests
        // (fake_cloud_firestore does not enforce security rules).
        final id = await seedExpense(status: 'approved');

        await expenseRepo.archiveExpense(id);

        final snap = await firestore
            .collection(AppConstants.expensesCollection)
            .doc(id)
            .get();
        expect(snap.data()?['isDeleted'], isTrue);
        expect(snap.data()?['deletedAt'], isNotNull);
      },
    );

    test('pendingExpenses stream excludes docs where isDeleted=true', () async {
      // Seed two pending records; archive one
      final keptId = await seedExpense();
      final archivedId = await seedExpense();
      await expenseRepo.archiveExpense(archivedId);

      final result = await expenseRepo.pendingExpenses().first;

      final ids = result.map((e) => e.id).toList();
      expect(ids, contains(keptId));
      expect(ids, isNot(contains(archivedId)));
    });

    test('techExpenses stream excludes docs where isDeleted=true', () async {
      final keptId = await seedExpense();
      final archivedId = await seedExpense();
      await expenseRepo.archiveExpense(archivedId);

      final result = await expenseRepo.techExpenses('tech-1').first;

      final ids = result.map((e) => e.id).toList();
      expect(ids, contains(keptId));
      expect(ids, isNot(contains(archivedId)));
    });
  });

  // ─── Earning archive / restore tests ─────────────────────────────────────

  group('EarningRepository — archive lifecycle', () {
    test('archiveEarning sets isDeleted=true on a pending record', () async {
      final id = await seedEarning();

      await earningRepo.archiveEarning(id);

      final snap = await firestore
          .collection(AppConstants.earningsCollection)
          .doc(id)
          .get();
      expect(snap.data()?['isDeleted'], isTrue);
      expect(snap.data()?['deletedAt'], isNotNull);
    });

    test('restoreEarning clears isDeleted on an archived record', () async {
      final id = await seedEarning();
      await earningRepo.archiveEarning(id);

      await earningRepo.restoreEarning(id);

      final snap = await firestore
          .collection(AppConstants.earningsCollection)
          .doc(id)
          .get();
      expect(snap.data()?['isDeleted'], isFalse);
      expect(snap.data()?['deletedAt'], isNull);
    });

    test(
      'archiveEarning allows archiving approved records (Firestore rules gate, not app layer)',
      () async {
        // Mirror of expense fix: approved earning archive no longer blocked
        // by app layer.
        final id = await seedEarning(status: 'approved');

        await earningRepo.archiveEarning(id);

        final snap = await firestore
            .collection(AppConstants.earningsCollection)
            .doc(id)
            .get();
        expect(snap.data()?['isDeleted'], isTrue);
        expect(snap.data()?['deletedAt'], isNotNull);
      },
    );

    test('pendingEarnings stream excludes docs where isDeleted=true', () async {
      final keptId = await seedEarning();
      final archivedId = await seedEarning();
      await earningRepo.archiveEarning(archivedId);

      final result = await earningRepo.pendingEarnings().first;

      final ids = result.map((e) => e.id).toList();
      expect(ids, contains(keptId));
      expect(ids, isNot(contains(archivedId)));
    });

    test('techEarnings stream excludes docs where isDeleted=true', () async {
      final keptId = await seedEarning();
      final archivedId = await seedEarning();
      await earningRepo.archiveEarning(archivedId);

      final result = await earningRepo.techEarnings('tech-1').first;

      final ids = result.map((e) => e.id).toList();
      expect(ids, contains(keptId));
      expect(ids, isNot(contains(archivedId)));
    });
  });
}

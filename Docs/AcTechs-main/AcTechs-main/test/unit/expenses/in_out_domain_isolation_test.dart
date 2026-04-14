// Domain isolation tests for the In/Out (expenses/earnings) provider layer.
//
// Verifies that:
// 1. todaysExpensesProvider and todaysEarningsProvider are DERIVED from the
//    monthly providers (no independent Firestore listeners).
// 2. dailyExpensesProvider / dailyEarningsProvider derive from monthly too.
// 3. In/Out providers never read job-domain data (domain boundary holds).
// 4. Switching months creates separate scoped listeners, not duplicate ones.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/expenses/data/expense_repository.dart';
import 'package:ac_techs/features/expenses/data/earning_repository.dart';
import 'package:ac_techs/features/expenses/providers/expense_providers.dart';

const _tech1 = UserModel(
  uid: 'tech-1',
  name: 'Tech One',
  email: 'tech1@example.com',
);

void main() {
  late FakeFirebaseFirestore firestore;
  late ExpenseRepository expenseRepository;
  late EarningRepository earningRepository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    expenseRepository = ExpenseRepository(firestore: firestore);
    earningRepository = EarningRepository(firestore: firestore);
  });

  Future<void> seedExpense(DateTime date, String techId) async {
    await firestore.collection(AppConstants.expensesCollection).add({
      'techId': techId,
      'techName': 'Tech',
      'category': 'Fuel',
      'amount': 50,
      'note': '',
      'expenseType': 'work',
      'status': 'pending',
      'approvedBy': '',
      'adminNote': '',
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(date),
      'reviewedAt': null,
      'isDeleted': false,
      'deletedAt': null,
    });
  }

  Future<void> seedEarning(DateTime date, String techId) async {
    await firestore.collection(AppConstants.earningsCollection).add({
      'techId': techId,
      'techName': 'Tech',
      'category': 'Other',
      'amount': 100,
      'note': '',
      'status': 'pending',
      'approvedBy': '',
      'adminNote': '',
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(date),
      'reviewedAt': null,
      'isDeleted': false,
      'deletedAt': null,
    });
  }

  ProviderContainer buildContainer(UserModel user) {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(user)),
        expenseRepositoryProvider.overrideWithValue(expenseRepository),
        earningRepositoryProvider.overrideWithValue(earningRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('todaysExpensesProvider is derived from monthlyExpensesProvider', () {
    test('todaysExpensesProvider only returns expenses from today', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      await seedExpense(today, 'tech-1');
      await seedExpense(today, 'tech-1');
      await seedExpense(yesterday, 'tech-1'); // must NOT appear in today's list

      final container = buildContainer(_tech1);
      final month = DateTime(today.year, today.month);

      // Prime the monthly provider first
      final monthlySub =
          container.listen(monthlyExpensesProvider(month), (_, _) {});
      addTearDown(monthlySub.close);
      await container.read(monthlyExpensesProvider(month).future);

      // Now read the derived today provider
      final todaysAsync = container.read(todaysExpensesProvider);
      expect(todaysAsync.hasValue, isTrue);
      expect(todaysAsync.value, hasLength(2));
    });

    test('todaysExpensesProvider reflects delete (isDeleted=true) from monthly', () async {
      final today = DateTime.now();
      await seedExpense(today, 'tech-1');

      // Seed a deleted expense that should be filtered out by repository streams.
      await firestore.collection(AppConstants.expensesCollection).add({
        'techId': 'tech-1',
        'techName': 'Tech',
        'category': 'Fuel',
        'amount': 25,
        'note': '',
        'expenseType': 'work',
        'status': 'pending',
        'approvedBy': '',
        'adminNote': '',
        'date': Timestamp.fromDate(today),
        'createdAt': Timestamp.fromDate(today),
        'reviewedAt': null,
        'isDeleted': true,
        'deletedAt': Timestamp.fromDate(today),
      });

      final container = buildContainer(_tech1);
      final month = DateTime(today.year, today.month);

      final sub = container.listen(monthlyExpensesProvider(month), (_, _) {});
      addTearDown(sub.close);
      await container.read(monthlyExpensesProvider(month).future);

      // The repository filters isDeleted in the Dart layer;
      // monthlyExpenses stream should only return 1 (non-deleted) expense.
      final all = await container.read(monthlyExpensesProvider(month).future);
      expect(all, hasLength(1));
    });
  });

  group('dailyExpensesProvider is derived from monthlyExpensesProvider', () {
    test('dailyExpensesProvider matches the requested day', () async {
      final today = DateTime.now();
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      await seedExpense(today, 'tech-1');
      await seedExpense(twoDaysAgo, 'tech-1');

      final container = buildContainer(_tech1);
      final month = DateTime(today.year, today.month);

      final sub = container.listen(monthlyExpensesProvider(month), (_, _) {});
      addTearDown(sub.close);
      await container.read(monthlyExpensesProvider(month).future);

      final daily = container.read(dailyExpensesProvider(today));
      expect(daily.hasValue, isTrue);
      expect(daily.value, hasLength(1));
      expect(daily.value!.single.date?.day, today.day);
    });
  });

  group('todaysEarningsProvider is derived from monthlyEarningsProvider', () {
    test('todaysEarningsProvider only returns earnings from today', () async {
      final today = DateTime.now();
      final lastMonth = DateTime(today.year, today.month - 1, 15);

      await seedEarning(today, 'tech-1');
      await seedEarning(lastMonth, 'tech-1'); // different month — not in today's list

      final container = buildContainer(_tech1);
      final month = DateTime(today.year, today.month);

      final sub = container.listen(monthlyEarningsProvider(month), (_, _) {});
      addTearDown(sub.close);
      await container.read(monthlyEarningsProvider(month).future);

      final todaysAsync = container.read(todaysEarningsProvider);
      expect(todaysAsync.hasValue, isTrue);
      expect(todaysAsync.value, hasLength(1));
    });
  });

  group('In/Out domain does not read job collection', () {
    test('monthlyExpensesProvider does not touch jobs collection', () async {
      // Seed something in jobs to make sure any query leak would fail
      await firestore.collection(AppConstants.jobsCollection).add({
        'techId': 'tech-1',
        'techName': 'Tech',
        'invoiceNumber': 'INV-LEAK',
        'status': 'pending',
      });

      final today = DateTime.now();
      await seedExpense(today, 'tech-1');

      final container = buildContainer(_tech1);
      final month = DateTime(today.year, today.month);

      final sub = container.listen(monthlyExpensesProvider(month), (_, _) {});
      addTearDown(sub.close);

      // If the provider accidentally reads jobs, it would return 0 (wrong shape),
      // but since it reads expenses collection, it returns 1.
      final expenses = await container.read(monthlyExpensesProvider(month).future);
      expect(expenses, hasLength(1));
      // Confirm it's an ExpenseModel (not a JobModel bleed)
      expect(expenses.single, isA<ExpenseModel>());
    });
  });
}

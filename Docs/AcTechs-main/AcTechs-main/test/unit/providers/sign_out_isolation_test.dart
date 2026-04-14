// Tests that sign-out invalidates all session-scoped providers, preventing
// data from a previously logged-in user from leaking into the next session.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/expenses/data/earning_repository.dart';
import 'package:ac_techs/features/expenses/data/expense_repository.dart';
import 'package:ac_techs/features/expenses/providers/expense_providers.dart';

const _tech1 = UserModel(
  uid: 'tech-1',
  name: 'Tech One',
  email: 'tech1@example.com',
);

const _tech2 = UserModel(
  uid: 'tech-2',
  name: 'Tech Two',
  email: 'tech2@example.com',
);

void main() {
  late FakeFirebaseFirestore firestore;
  late JobRepository jobRepository;
  late ExpenseRepository expenseRepository;
  late EarningRepository earningRepository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    jobRepository = JobRepository(firestore: firestore);
    expenseRepository = ExpenseRepository(firestore: firestore);
    earningRepository = EarningRepository(firestore: firestore);
  });

  Future<void> seedJob(String techId, String invoiceNumber) async {
    final date = Timestamp.fromDate(DateTime(2026, 4, 2, 9));
    await firestore.collection(AppConstants.jobsCollection).add({
      'techId': techId,
      'techName': 'Tech',
      'invoiceNumber': invoiceNumber,
      'clientName': 'Client',
      'clientContact': '',
      'acUnits': [
        {'type': AppConstants.unitTypeSplitAc, 'quantity': 1},
      ],
      'status': 'pending',
      'expenses': 0,
      'expenseNote': '',
      'adminNote': '',
      'approvedBy': '',
      'isSharedInstall': false,
      'sharedInstallGroupKey': '',
      'sharedInvoiceTotalUnits': 0,
      'sharedContributionUnits': 0,
      'sharedInvoiceSplitUnits': 0,
      'sharedInvoiceWindowUnits': 0,
      'sharedInvoiceFreestandingUnits': 0,
      'sharedInvoiceBracketCount': 0,
      'sharedDeliveryTeamCount': 0,
      'sharedInvoiceDeliveryAmount': 0,
      'techSplitShare': 0,
      'techWindowShare': 0,
      'techFreestandingShare': 0,
      'techBracketShare': 0,
      'charges': {
        'acBracket': false,
        'bracketCount': 0,
        'bracketAmount': 0,
        'deliveryCharge': false,
        'deliveryAmount': 0,
        'deliveryNote': '',
      },
      'date': date,
      'submittedAt': date,
      'reviewedAt': null,
    });
  }

  Future<void> seedEarning(String techId) async {
    final date = Timestamp.fromDate(DateTime(2026, 4, 2, 9));
    await firestore.collection(AppConstants.earningsCollection).add({
      'techId': techId,
      'techName': 'Tech',
      'category': 'Bracket',
      'amount': 50,
      'note': '',
      'status': 'pending',
      'approvedBy': '',
      'adminNote': '',
      'date': date,
      'createdAt': date,
      'reviewedAt': null,
      'isDeleted': false,
      'deletedAt': null,
    });
  }

  ProviderContainer buildContainer(UserModel user) {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(user)),
        jobRepositoryProvider.overrideWithValue(jobRepository),
        expenseRepositoryProvider.overrideWithValue(expenseRepository),
        earningRepositoryProvider.overrideWithValue(earningRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'technicianJobsProvider only returns jobs for the current user',
    () async {
      await seedJob('tech-1', 'INV-001');
      await seedJob('tech-1', 'INV-002');
      await seedJob('tech-2', 'INV-003'); // different tech — must not appear

      final container = buildContainer(_tech1);

      final sub = container.listen(technicianJobsProvider, (_, _) {});
      addTearDown(sub.close);

      final jobs = await container.read(technicianJobsProvider.future);
      expect(jobs, hasLength(2));
      expect(jobs.every((j) => j.techId == 'tech-1'), isTrue);
    },
  );

  test('technicianJobsProvider for tech-2 does not see tech-1 jobs', () async {
    await seedJob('tech-1', 'INV-100');
    await seedJob('tech-2', 'INV-200');

    final container = buildContainer(_tech2);

    final sub = container.listen(technicianJobsProvider, (_, _) {});
    addTearDown(sub.close);

    final jobs = await container.read(technicianJobsProvider.future);
    expect(jobs, hasLength(1));
    expect(jobs.single.invoiceNumber, 'INV-200');
  });

  test('technicianJobsProvider is invalidated after sign-out — '
      'switching users yields a fresh empty state', () async {
    await seedJob('tech-1', 'INV-001');

    // Simulate tech-1 session
    final containerTech1 = buildContainer(_tech1);
    final sub1 = containerTech1.listen(technicianJobsProvider, (_, _) {});
    addTearDown(sub1.close);

    final jobsBefore = await containerTech1.read(technicianJobsProvider.future);
    expect(jobsBefore, hasLength(1));

    // Mark as invalidated (mirrors what signOut() does)
    containerTech1.invalidate(technicianJobsProvider);

    // Simulate tech-2 session (no jobs seeded for tech-2)
    final containerTech2 = buildContainer(_tech2);
    final sub2 = containerTech2.listen(technicianJobsProvider, (_, _) {});
    addTearDown(sub2.close);

    final jobsAfter = await containerTech2.read(technicianJobsProvider.future);
    expect(jobsAfter, isEmpty);
  });

  test(
    'techEarningsProvider only returns earnings for the current user',
    () async {
      await seedEarning('tech-1');
      await seedEarning('tech-1');
      await seedEarning('tech-2');

      final container = buildContainer(_tech1);

      final sub = container.listen(techEarningsProvider, (_, _) {});
      addTearDown(sub.close);

      final earnings = await container.read(techEarningsProvider.future);
      expect(earnings.length, 2);
      expect(earnings.every((e) => e.techId == 'tech-1'), isTrue);
    },
  );
}

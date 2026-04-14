import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late JobRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = JobRepository(firestore: firestore);
  });

  Future<void> seedJob({
    required String techId,
    required String techName,
    required String invoiceNumber,
    required String unitType,
  }) {
    final date = Timestamp.fromDate(DateTime(2026, 4, 2, 9));
    return firestore.collection(AppConstants.jobsCollection).add({
      'techId': techId,
      'techName': techName,
      'invoiceNumber': invoiceNumber,
      'clientName': 'Client $invoiceNumber',
      'clientContact': '',
      'acUnits': [
        {'type': unitType, 'quantity': 1},
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

  ProviderContainer buildContainer(UserModel user) {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(user)),
        jobRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('adminJobSummaryProvider returns computed summary for admins', () async {
    await seedJob(
      techId: 'tech-1',
      techName: 'Ali',
      invoiceNumber: 'INV-001',
      unitType: AppConstants.unitTypeSplitAc,
    );
    await seedJob(
      techId: 'tech-2',
      techName: 'Bilal',
      invoiceNumber: 'INV-002',
      unitType: AppConstants.unitTypeWindowAc,
    );

    final container = buildContainer(
      const UserModel(
        uid: 'admin-1',
        name: 'Admin',
        email: 'admin@example.com',
        role: AppConstants.roleAdmin,
      ),
    );

    final currentUserSub = container.listen(currentUserProvider, (_, _) {});
    addTearDown(currentUserSub.close);
    await container.read(currentUserProvider.future);

    final summary = await container.read(adminJobSummaryProvider.future);
    expect(summary.totalJobs, 2);
    expect(summary.splitUnits, 1);
    expect(summary.windowUnits, 1);
  });

  test(
    'adminJobSummaryProvider returns empty summary for technicians',
    () async {
      final container = buildContainer(
        const UserModel(uid: 'tech-1', name: 'Tech', email: 'tech@example.com'),
      );

      final currentUserSub = container.listen(currentUserProvider, (_, _) {});
      addTearDown(currentUserSub.close);
      await container.read(currentUserProvider.future);

      final summary = await container.read(adminJobSummaryProvider.future);
      expect(summary, AdminJobSummary.empty());
    },
  );

  test(
    'techJobsByAcTypeProvider filters the technician stream by AC type',
    () async {
      await seedJob(
        techId: 'tech-1',
        techName: 'Ali',
        invoiceNumber: 'INV-001',
        unitType: AppConstants.unitTypeSplitAc,
      );
      await seedJob(
        techId: 'tech-1',
        techName: 'Ali',
        invoiceNumber: 'INV-002',
        unitType: AppConstants.unitTypeWindowAc,
      );
      await seedJob(
        techId: 'tech-2',
        techName: 'Bilal',
        invoiceNumber: 'INV-003',
        unitType: AppConstants.unitTypeSplitAc,
      );

      final container = buildContainer(
        const UserModel(uid: 'tech-1', name: 'Ali', email: 'ali@example.com'),
      );

      final currentUserSub = container.listen(currentUserProvider, (_, _) {});
      addTearDown(currentUserSub.close);
      await container.read(currentUserProvider.future);

      final jobsSub = container.listen(technicianJobsProvider, (_, _) {});
      addTearDown(jobsSub.close);

      final jobs = await container.read(technicianJobsProvider.future);
      expect(jobs, hasLength(2));

      final splitJobs = container.read(
        techJobsByAcTypeProvider(JobAcTypeFilter.split),
      );

      expect(splitJobs, hasLength(1));
      expect(splitJobs.single.invoiceNumber, 'INV-001');
    },
  );
}

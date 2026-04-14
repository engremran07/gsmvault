import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = UserRepository(firestore: firestore);
  });

  Future<void> seedCompany({
    required String id,
    required String name,
    required String prefix,
  }) {
    return firestore.collection(AppConstants.companiesCollection).doc(id).set({
      'name': name,
      'invoicePrefix': prefix,
      'isActive': true,
    });
  }

  Future<void> seedJob({
    required String id,
    required String techId,
    required String techName,
    required String companyId,
    required String companyName,
    required String invoiceNumber,
    required String status,
    required bool isSharedInstall,
    String sharedInstallGroupKey = '',
    int splitQty = 0,
    int sharedInvoiceSplitUnits = 0,
    int sharedContributionUnits = 0,
  }) {
    return firestore.collection(AppConstants.jobsCollection).doc(id).set({
      'techId': techId,
      'techName': techName,
      'companyId': companyId,
      'companyName': companyName,
      'invoiceNumber': invoiceNumber,
      'clientName': 'Client $id',
      'clientContact': '',
      'acUnits': splitQty <= 0
          ? const []
          : [
              {'type': AppConstants.unitTypeSplitAc, 'quantity': splitQty},
            ],
      'status': status,
      'expenses': 0,
      'expenseNote': '',
      'adminNote': '',
      'importMeta': const <String, dynamic>{},
      'approvedBy': status == 'approved' ? 'admin-1' : '',
      'isSharedInstall': isSharedInstall,
      'sharedInstallGroupKey': sharedInstallGroupKey,
      'sharedInvoiceTotalUnits': sharedInvoiceSplitUnits,
      'sharedContributionUnits': sharedContributionUnits,
      'sharedInvoiceSplitUnits': sharedInvoiceSplitUnits,
      'sharedInvoiceWindowUnits': 0,
      'sharedInvoiceFreestandingUnits': 0,
      'sharedInvoiceUninstallSplitUnits': 0,
      'sharedInvoiceUninstallWindowUnits': 0,
      'sharedInvoiceUninstallFreestandingUnits': 0,
      'sharedInvoiceBracketCount': 0,
      'sharedDeliveryTeamCount': 0,
      'sharedInvoiceDeliveryAmount': 0,
      'techSplitShare': splitQty,
      'techWindowShare': 0,
      'techFreestandingShare': 0,
      'techUninstallSplitShare': 0,
      'techUninstallWindowShare': 0,
      'techUninstallFreestandingShare': 0,
      'techBracketShare': 0,
      'charges': {
        'acBracket': false,
        'bracketCount': 0,
        'bracketAmount': 0,
        'deliveryCharge': false,
        'deliveryAmount': 0,
        'deliveryNote': '',
      },
      'date': DateTime(2025, 1, 1),
      'submittedAt': DateTime(2025, 1, 1),
      'reviewedAt': DateTime(2025, 1, 1),
    });
  }

  test(
    'normalizes stored invoices and rebuilds claims and aggregates',
    () async {
      await seedCompany(id: 'company-1', name: 'Company One', prefix: 'CO');
      await seedJob(
        id: 'solo-1',
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company One',
        invoiceNumber: 'CO-100',
        status: 'approved',
        isSharedInstall: false,
      );
      await seedJob(
        id: 'shared-1',
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company One',
        invoiceNumber: 'CO-200',
        status: 'approved',
        isSharedInstall: true,
        sharedInstallGroupKey: 'company-1-co-200',
        splitQty: 1,
        sharedInvoiceSplitUnits: 2,
        sharedContributionUnits: 1,
      );
      await seedJob(
        id: 'shared-2',
        techId: 'tech-2',
        techName: 'Tech Two',
        companyId: 'company-1',
        companyName: 'Company One',
        invoiceNumber: 'CO-200',
        status: 'pending',
        isSharedInstall: true,
        sharedInstallGroupKey: 'company-1-co-200',
        splitQty: 1,
        sharedInvoiceSplitUnits: 2,
        sharedContributionUnits: 1,
      );

      await firestore
          .collection(AppConstants.invoiceClaimsCollection)
          .doc('co_100')
          .set({'invoiceNumber': 'CO-100'});
      await firestore
          .collection(AppConstants.sharedInstallAggregatesCollection)
          .doc('shared_company_1_co_200')
          .set({'groupKey': 'company-1-co-200'});

      final result = await repository.normalizeStoredInvoicePrefixes();

      expect(result.scannedJobs, 3);
      expect(result.updatedJobs, 3);
      expect(result.conflictedInvoices, 0);
      expect(result.rebuiltInvoiceClaims, 2);
      expect(result.rebuiltSharedAggregates, 1);

      final soloJob = await firestore
          .collection(AppConstants.jobsCollection)
          .doc('solo-1')
          .get();
      expect(soloJob.data()?['invoiceNumber'], '100');

      final sharedJob = await firestore
          .collection(AppConstants.jobsCollection)
          .doc('shared-1')
          .get();
      expect(sharedJob.data()?['invoiceNumber'], '200');
      expect(sharedJob.data()?['sharedInstallGroupKey'], 'company-1-200');

      final oldClaim = await firestore
          .collection(AppConstants.invoiceClaimsCollection)
          .doc('co_100')
          .get();
      expect(oldClaim.exists, isFalse);

      final soloClaim = await firestore
          .collection(AppConstants.invoiceClaimsCollection)
          .doc('100')
          .get();
      expect(soloClaim.exists, isTrue);
      expect(soloClaim.data()?['activeJobCount'], 1);

      final sharedClaim = await firestore
          .collection(AppConstants.invoiceClaimsCollection)
          .doc('200')
          .get();
      expect(sharedClaim.exists, isTrue);
      expect(sharedClaim.data()?['reuseMode'], 'shared');
      expect(sharedClaim.data()?['activeJobCount'], 2);

      final aggregate = await firestore
          .collection(AppConstants.sharedInstallAggregatesCollection)
          .doc('shared_company-1-200')
          .get();
      expect(aggregate.exists, isTrue);
      expect(aggregate.data()?['groupKey'], 'company-1-200');
      expect(aggregate.data()?['consumedSplitUnits'], 2);
    },
  );

  test('flags cross-company conflicts after prefix normalization', () async {
    await seedCompany(id: 'company-1', name: 'Company One', prefix: 'A');
    await seedCompany(id: 'company-2', name: 'Company Two', prefix: 'B');
    await seedJob(
      id: 'job-1',
      techId: 'tech-1',
      techName: 'Tech One',
      companyId: 'company-1',
      companyName: 'Company One',
      invoiceNumber: 'A-900',
      status: 'approved',
      isSharedInstall: false,
    );
    await seedJob(
      id: 'job-2',
      techId: 'tech-2',
      techName: 'Tech Two',
      companyId: 'company-2',
      companyName: 'Company Two',
      invoiceNumber: 'B-900',
      status: 'pending',
      isSharedInstall: false,
    );

    final result = await repository.normalizeStoredInvoicePrefixes();

    expect(result.conflictedInvoices, 1);
    expect(result.rebuiltInvoiceClaims, 0);

    final first = await firestore
        .collection(AppConstants.jobsCollection)
        .doc('job-1')
        .get();
    final second = await firestore
        .collection(AppConstants.jobsCollection)
        .doc('job-2')
        .get();

    expect(first.data()?['invoiceNumber'], '900');
    expect(second.data()?['invoiceNumber'], '900');
    expect(first.data()?['importMeta']['invoiceConflict'], true);
    expect(second.data()?['importMeta']['invoiceConflict'], true);

    final claim = await firestore
        .collection(AppConstants.invoiceClaimsCollection)
        .doc('900')
        .get();
    expect(claim.exists, isFalse);
  });
}

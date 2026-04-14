import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = UserRepository(
      firestore: firestore,
      flushPreflight: () async {},
    );
  });

  Future<void> seedJob({
    required String id,
    required String techId,
    required String invoiceNumber,
    required int splitUnits,
    required bool isSharedInstall,
  }) async {
    await firestore.collection(AppConstants.jobsCollection).doc(id).set({
      'techId': techId,
      'techName': techId,
      'companyId': 'company-1',
      'companyName': 'Company',
      'invoiceNumber': invoiceNumber,
      'clientName': 'Client',
      'clientContact': '',
      'acUnits': [
        {'type': AppConstants.unitTypeSplitAc, 'quantity': splitUnits},
      ],
      'status': 'pending',
      'expenses': 0,
      'expenseNote': '',
      'adminNote': '',
      'approvedBy': '',
      'isSharedInstall': isSharedInstall,
      'sharedInstallGroupKey': isSharedInstall
          ? 'company-1-$invoiceNumber'
          : '',
      'sharedInvoiceTotalUnits': isSharedInstall ? 2 : 0,
      'sharedContributionUnits': isSharedInstall ? splitUnits : 0,
      'sharedInvoiceSplitUnits': isSharedInstall ? 2 : 0,
      'sharedInvoiceWindowUnits': 0,
      'sharedInvoiceFreestandingUnits': 0,
      'sharedInvoiceUninstallSplitUnits': 0,
      'sharedInvoiceUninstallWindowUnits': 0,
      'sharedInvoiceUninstallFreestandingUnits': 0,
      'sharedInvoiceBracketCount': 0,
      'sharedDeliveryTeamCount': 0,
      'sharedInvoiceDeliveryAmount': 0,
      'techSplitShare': isSharedInstall ? splitUnits : 0,
      'techWindowShare': 0,
      'techFreestandingShare': 0,
      'techUninstallSplitShare': 0,
      'techUninstallWindowShare': 0,
      'techUninstallFreestandingShare': 0,
      'techBracketShare': 0,
      'charges': null,
      'date': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
      'submittedAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
    });
  }

  test(
    'flushDatabase deletes history subcollections before parent docs',
    () async {
      final jobRef = firestore
          .collection(AppConstants.jobsCollection)
          .doc('job-1');
      await jobRef.set({
        'techId': 'tech-1',
        'techName': 'Tech One',
        'companyId': 'company-1',
        'companyName': 'Company',
        'invoiceNumber': '100',
        'clientName': 'Client',
        'acUnits': [
          {'type': AppConstants.unitTypeSplitAc, 'quantity': 1},
        ],
        'status': 'pending',
        'expenses': 0,
        'date': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
        'submittedAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
      });
      await jobRef.collection('history').doc('event-1').set({
        'changedBy': 'admin-1',
        'changedAt': Timestamp.fromDate(DateTime(2024, 1, 10, 10)),
        'previousStatus': 'pending',
        'newStatus': 'approved',
      });

      final expenseRef = firestore
          .collection(AppConstants.expensesCollection)
          .doc('expense-1');
      await expenseRef.set({
        'techId': 'tech-1',
        'techName': 'Tech One',
        'category': 'Fuel',
        'amount': 50,
        'note': '',
        'expenseType': 'work',
        'status': 'pending',
        'approvedBy': '',
        'adminNote': '',
        'date': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
        'reviewedAt': null,
      });
      await expenseRef.collection('history').doc('event-1').set({
        'changedBy': 'admin-1',
        'changedAt': Timestamp.fromDate(DateTime(2024, 1, 10, 10)),
        'previousStatus': 'pending',
        'newStatus': 'approved',
      });

      await repository.flushDatabase();

      expect((await jobRef.get()).exists, isFalse);
      expect((await expenseRef.get()).exists, isFalse);
      expect((await jobRef.collection('history').get()).docs, isEmpty);
      expect((await expenseRef.collection('history').get()).docs, isEmpty);
    },
  );

  test(
    'flushDatabase deletes flat collections without probing history',
    () async {
      await firestore
          .collection(AppConstants.sharedInstallAggregatesCollection)
          .doc('aggregate-1')
          .set({
            'groupKey': 'company-1-100',
            'sharedInvoiceSplitUnits': 1,
            'sharedInvoiceWindowUnits': 0,
            'sharedInvoiceFreestandingUnits': 0,
            'sharedInvoiceUninstallSplitUnits': 0,
            'sharedInvoiceUninstallWindowUnits': 0,
            'sharedInvoiceUninstallFreestandingUnits': 0,
            'sharedInvoiceBracketCount': 0,
            'sharedDeliveryTeamCount': 0,
            'sharedInvoiceDeliveryAmount': 0,
            'consumedSplitUnits': 1,
            'consumedWindowUnits': 0,
            'consumedFreestandingUnits': 0,
            'consumedUninstallSplitUnits': 0,
            'consumedUninstallWindowUnits': 0,
            'consumedUninstallFreestandingUnits': 0,
            'consumedBracketCount': 0,
            'consumedDeliveryAmount': 0,
            'teamMemberIds': ['tech-1'],
            'teamMemberNames': ['Tech One'],
            'createdBy': 'tech-1',
            'createdAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
            'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
          });
      await firestore
          .collection(AppConstants.invoiceClaimsCollection)
          .doc('100')
          .set({
            'invoiceNumber': '100',
            'companyId': 'company-1',
            'companyName': 'Company',
            'reuseMode': 'solo',
            'activeJobCount': 1,
            'createdBy': 'tech-1',
            'createdAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
            'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
          });
      await firestore
          .collection(AppConstants.companiesCollection)
          .doc('company-1')
          .set({
            'name': 'Company',
            'invoicePrefix': 'CMP',
            'isActive': true,
            'logoBase64': '',
            'createdAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
          });

      await repository.flushDatabase();

      expect(
        (await firestore
                .collection(AppConstants.sharedInstallAggregatesCollection)
                .get())
            .docs,
        isEmpty,
      );
      expect(
        (await firestore.collection(AppConstants.invoiceClaimsCollection).get())
            .docs,
        isEmpty,
      );
      expect(
        (await firestore.collection(AppConstants.companiesCollection).get())
            .docs,
        isEmpty,
      );
    },
  );

  test(
    'flushTechnicianData rebuilds affected claim and shared aggregate',
    () async {
      await seedJob(
        id: 'job-1',
        techId: 'tech-1',
        invoiceNumber: '100',
        splitUnits: 1,
        isSharedInstall: true,
      );
      await seedJob(
        id: 'job-2',
        techId: 'tech-2',
        invoiceNumber: '100',
        splitUnits: 1,
        isSharedInstall: true,
      );

      await firestore
          .collection(AppConstants.invoiceClaimsCollection)
          .doc('100')
          .set({
            'invoiceNumber': '100',
            'companyId': 'company-1',
            'companyName': 'Company',
            'reuseMode': 'shared',
            'activeJobCount': 2,
            'createdBy': 'tech-1',
            'createdAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
            'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
          });

      await firestore
          .collection(AppConstants.sharedInstallAggregatesCollection)
          .doc('shared_company-1-100')
          .set({
            'groupKey': 'company-1-100',
            'sharedInvoiceSplitUnits': 2,
            'sharedInvoiceWindowUnits': 0,
            'sharedInvoiceFreestandingUnits': 0,
            'sharedInvoiceUninstallSplitUnits': 0,
            'sharedInvoiceUninstallWindowUnits': 0,
            'sharedInvoiceUninstallFreestandingUnits': 0,
            'sharedInvoiceBracketCount': 0,
            'sharedDeliveryTeamCount': 0,
            'sharedInvoiceDeliveryAmount': 0,
            'consumedSplitUnits': 2,
            'consumedWindowUnits': 0,
            'consumedFreestandingUnits': 0,
            'consumedUninstallSplitUnits': 0,
            'consumedUninstallWindowUnits': 0,
            'consumedUninstallFreestandingUnits': 0,
            'consumedBracketCount': 0,
            'consumedDeliveryAmount': 0,
            'createdBy': 'tech-1',
            'createdAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
            'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 10, 9)),
          });

      await repository.flushTechnicianData('tech-1');

      final remainingJobs = await firestore
          .collection(AppConstants.jobsCollection)
          .get();
      final claimSnap = await firestore
          .collection(AppConstants.invoiceClaimsCollection)
          .doc('100')
          .get();
      final aggregateSnap = await firestore
          .collection(AppConstants.sharedInstallAggregatesCollection)
          .doc('shared_company-1-100')
          .get();

      expect(remainingJobs.docs, hasLength(1));
      expect(remainingJobs.docs.single.data()['techId'], 'tech-2');
      expect(claimSnap.data()?['activeJobCount'], 1);
      expect(aggregateSnap.data()?['consumedSplitUnits'], 1);
    },
  );
}

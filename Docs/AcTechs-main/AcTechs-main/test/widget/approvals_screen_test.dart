import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/admin/presentation/approvals_screen.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/expenses/data/ac_install_repository.dart';
import 'package:ac_techs/features/expenses/providers/ac_install_providers.dart';
import 'package:ac_techs/features/expenses/providers/expense_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'approvals screen renders pending AC installs and opens review actions',
    (tester) async {
      final firestore = FakeFirebaseFirestore();
      final repository = AcInstallRepository(firestore: firestore);
      await firestore
          .collection(AppConstants.acInstallsCollection)
          .doc('install-1')
          .set({
            'techId': 'tech-1',
            'techName': 'Tech One',
            'splitTotal': 2,
            'splitShare': 1,
            'windowTotal': 0,
            'windowShare': 0,
            'freestandingTotal': 0,
            'freestandingShare': 0,
            'note': 'Pending install',
            'status': 'pending',
            'approvedBy': '',
            'adminNote': '',
            'date': Timestamp.fromDate(DateTime(2024, 1, 12, 8)),
            'createdAt': Timestamp.fromDate(DateTime(2024, 1, 12, 8)),
            'reviewedAt': null,
          });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => Stream.value(
                const UserModel(
                  uid: 'admin-1',
                  name: 'Admin',
                  email: 'admin@example.com',
                  role: 'admin',
                ),
              ),
            ),
            acInstallRepositoryProvider.overrideWithValue(repository),
            pendingAcInstallsProvider.overrideWith(
              (ref) =>
                  ref.watch(acInstallRepositoryProvider).watchPendingInstalls(),
            ),
            pendingApprovalsProvider.overrideWith(
              (ref) => Stream.value(const <JobModel>[]),
            ),
            approvedSharedInstallsProvider.overrideWith(
              (ref) => Stream.value(const <JobModel>[]),
            ),
            pendingEarningsProvider.overrideWith(
              (ref) => Stream.value(const <EarningModel>[]),
            ),
            pendingExpensesProvider.overrideWith(
              (ref) => Stream.value(const <ExpenseModel>[]),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en'), Locale('ur'), Locale('ar')],
            home: ApprovalsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AC Installations'), findsOneWidget);
      expect(find.text('Tech One'), findsOneWidget);
      expect(find.text('Pending install'), findsOneWidget);

      expect(find.widgetWithText(FilledButton, 'Approve'), findsWidgets);
      expect(find.widgetWithText(OutlinedButton, 'Reject'), findsWidgets);
    },
  );
}

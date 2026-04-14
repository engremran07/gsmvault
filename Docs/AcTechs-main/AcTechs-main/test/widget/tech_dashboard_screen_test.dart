import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/technician_job_summary.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/jobs/providers/shared_install_providers.dart';
import 'package:ac_techs/features/technician/presentation/tech_dashboard_screen.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

void main() {
  const technician = UserModel(
    uid: 'tech-1',
    name: 'Tech One',
    email: 'tech@example.com',
  );

  const summary = TechnicianJobSummary(
    totalJobs: 12,
    pendingJobs: 3,
    approvedJobs: 7,
    rejectedJobs: 2,
    sharedJobs: 1,
    totalUnits: 18,
    splitUnits: 6,
    windowUnits: 4,
    freestandingUnits: 2,
    bracketCount: 5,
    uninstallTotal: 3,
  );

  Future<GoRouter> pumpDashboard(
    WidgetTester tester, {
    MediaQueryData? mediaQuery,
  }) async {
    final router = GoRouter(
      initialLocation: '/tech',
      routes: [
        GoRoute(
          path: '/tech',
          builder: (context, state) => const TechDashboardScreen(),
        ),
        GoRoute(
          path: '/tech/settings',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Settings Route'))),
        ),
        GoRoute(
          path: '/tech/history',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('History Route'))),
        ),
        GoRoute(
          path: '/tech/jobs/filter/:type',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Filter Route'))),
        ),
        GoRoute(
          path: '/tech/submit',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Submit Route'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(technician)),
          todaysJobsProvider.overrideWith(
            (ref) => const AsyncData(<JobModel>[]),
          ),
          technicianJobSummaryProvider.overrideWith(
            (ref) => const AsyncData(summary),
          ),
          technicianSettlementInboxProvider.overrideWith(
            (ref) => Stream.value(const <JobModel>[]),
          ),
          pendingSharedInstallAggregatesProvider.overrideWith(
            (ref) => Stream.value(const <SharedInstallAggregate>[]),
          ),
        ],
        child: MediaQuery(
          data: mediaQuery ?? const MediaQueryData(size: Size(390, 844)),
          child: MaterialApp.router(
            routerConfig: router,
            theme: ArcticTheme.darkThemeForLocale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ur'), Locale('ar')],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    addTearDown(router.dispose);
    return router;
  }

  testWidgets('bracket and uninstall summary cards open history', (
    tester,
  ) async {
    final router = await pumpDashboard(tester);

    await tester.tap(find.text('Outdoor Bracket'));
    await tester.pumpAndSettle();
    expect(find.text('Filter Route'), findsOneWidget);

    router.go('/tech');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Uninstalls'));
    await tester.pumpAndSettle();
    expect(find.text('Filter Route'), findsOneWidget);
  });

  testWidgets('new job FAB stays readable and opens submit route', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      mediaQuery: const MediaQueryData(
        size: Size(320, 640),
        textScaler: TextScaler.linear(1.35),
      ),
    );

    expect(find.text('New Job'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Submit Route'), findsOneWidget);
  });
}

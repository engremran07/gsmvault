import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/auth/presentation/login_screen.dart';
import 'package:ac_techs/features/auth/presentation/splash_screen.dart';
import 'package:ac_techs/features/technician/presentation/tech_shell.dart';
import 'package:ac_techs/features/technician/presentation/tech_dashboard_screen.dart';
import 'package:ac_techs/features/technician/presentation/submit_job_screen.dart';
import 'package:ac_techs/features/technician/presentation/job_history_screen.dart';
import 'package:ac_techs/features/technician/presentation/job_details_screen.dart';
import 'package:ac_techs/features/jobs/presentation/job_type_filter_screen.dart';
import 'package:ac_techs/features/technician/presentation/tech_profile_screen.dart';
import 'package:ac_techs/features/technician/presentation/reports_hub_screen.dart';
import 'package:ac_techs/features/technician/presentation/settlement_inbox_screen.dart';
import 'package:ac_techs/features/admin/presentation/admin_shell.dart';
import 'package:ac_techs/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:ac_techs/features/admin/presentation/approvals_screen.dart';
import 'package:ac_techs/features/admin/presentation/analytics_screen.dart';
import 'package:ac_techs/features/admin/presentation/invoice_settlements_screen.dart';
import 'package:ac_techs/features/admin/presentation/invoice_reconciliation_screen.dart';
import 'package:ac_techs/features/admin/presentation/companies_screen.dart';
import 'package:ac_techs/features/admin/presentation/team_screen.dart';
import 'package:ac_techs/features/admin/presentation/flush_database_screen.dart';
import 'package:ac_techs/features/admin/presentation/historical_import_screen.dart';
import 'package:ac_techs/features/settings/presentation/settings_screen.dart';
import 'package:ac_techs/features/settings/providers/approval_config_provider.dart';
import 'package:ac_techs/features/expenses/presentation/daily_in_out_screen.dart';
import 'package:ac_techs/features/expenses/presentation/ac_installations_screen.dart';
import 'package:ac_techs/features/expenses/presentation/monthly_summary_screen.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';

final _routerKey = GlobalKey<NavigatorState>();

String? resolveAppRedirect({
  required String matchedLocation,
  required bool isAuthLoading,
  required bool isLoggedIn,
  required AsyncValue<UserModel?> currentUser,
  required ApprovalConfig? approvalConfig,
}) {
  final isSplashRoute = matchedLocation == '/splash';
  final isLoginRoute = matchedLocation == '/login';
  final user = currentUser.asData?.value;

  if (isAuthLoading) {
    return isSplashRoute ? null : '/splash';
  }

  if (!isLoggedIn) {
    return isLoginRoute ? null : '/login';
  }

  // Reauthentication and profile refreshes can briefly put the user profile
  // stream into a loading state even though the auth session is still valid.
  // Preserve the current protected route during that transient reload instead
  // of bouncing the user through splash and back to the dashboard.
  if (currentUser.isLoading) {
    return null;
  }

  if (currentUser.hasError || user == null) {
    return isLoginRoute ? null : '/login';
  }

  if (!user.isActive) {
    return '/login';
  }

  if (isSplashRoute || isLoginRoute) {
    return user.isAdmin ? '/admin' : '/tech';
  }

  final isAdminRoute = matchedLocation.startsWith('/admin');
  final isTechRoute = matchedLocation.startsWith('/tech');
  if (user.isAdmin && isTechRoute) return '/admin';
  if (!user.isAdmin && isAdminRoute) return '/tech';

  return null;
}

/// A `CustomTransitionPage` that fades and slides up slightly — used for all
/// full-screen route pushes so the app feels snappy and polished.
CustomTransitionPage<T> _slideFadePage<T>({
  required LocalKey pageKey,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeTween = CurveTween(curve: Curves.easeOut);
      final slideTween = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  // Use a refreshListenable to trigger redirect without recreating GoRouter
  final notifier = ValueNotifier<int>(0);
  Timer? refreshDebounce;

  void triggerRefresh() {
    notifier.value++;
  }

  void queueRefresh() {
    refreshDebounce?.cancel();
    refreshDebounce = Timer(const Duration(milliseconds: 80), triggerRefresh);
  }

  ref.listen(authStateProvider, (_, _) => queueRefresh());
  ref.listen(currentUserProvider, (_, _) => queueRefresh());
  ref.listen(approvalConfigProvider, (_, _) => queueRefresh());

  ref.onDispose(() {
    refreshDebounce?.cancel();
    notifier.dispose();
  });

  return GoRouter(
    navigatorKey: _routerKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.error?.toString() ?? 'Navigation error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final currentUser = ref.read(currentUserProvider);
      final approvalConfig = ref.read(approvalConfigProvider).asData?.value;

      return resolveAppRedirect(
        matchedLocation: state.matchedLocation,
        isAuthLoading: authState.isLoading,
        isLoggedIn: authState.value != null,
        currentUser: currentUser,
        approvalConfig: approvalConfig,
      );
    },
    routes: [
      // ✅ Splash Screen (shown on every app launch)
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) {
          return MaterialPage(child: SplashScreen(onComplete: () {}));
        },
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _slideFadePage(pageKey: state.pageKey, child: const LoginScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => TechShell(child: child),
        routes: [
          GoRoute(
            path: '/tech',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const TechDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/tech/submit',
            pageBuilder: (context, state) {
              final initialJob = state.extra is JobModel
                  ? state.extra as JobModel
                  : null;
              final initialAggregate = state.extra is SharedInstallAggregate
                  ? state.extra as SharedInstallAggregate
                  : null;
              return _slideFadePage(
                pageKey: state.pageKey,
                child: SubmitJobScreen(
                  initialJob: initialJob,
                  initialAggregate: initialAggregate,
                ),
              );
            },
          ),
          GoRoute(
            path: '/tech/inout',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: DailyInOutScreen(
                selectedDate: state.extra is DateTime
                    ? state.extra as DateTime
                    : null,
              ),
            ),
          ),
          GoRoute(
            path: '/tech/ac-installs',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const AcInstallationsScreen(),
            ),
          ),
          GoRoute(
            path: '/tech/summary',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: MonthlySummaryScreen(
                initialMonth: state.extra is DateTime
                    ? state.extra as DateTime
                    : null,
              ),
            ),
          ),
          GoRoute(
            path: '/tech/history',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const JobHistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/tech/settlements',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const SettlementInboxScreen(),
            ),
          ),
          GoRoute(
            path: '/tech/job/:jobId',
            pageBuilder: (context, state) {
              final initialJob = state.extra is JobModel
                  ? state.extra as JobModel
                  : null;
              final jobId = state.pathParameters['jobId'] ?? '';
              return _slideFadePage(
                pageKey: state.pageKey,
                child: JobDetailsScreen(jobId: jobId, initialJob: initialJob),
              );
            },
          ),
          GoRoute(
            path: '/tech/jobs/filter/:type',
            pageBuilder: (context, state) {
              final typeRaw = state.pathParameters['type'] ?? '';
              final filter =
                  jobAcTypeFilterFromPath(typeRaw) ?? JobAcTypeFilter.split;
              return _slideFadePage(
                pageKey: state.pageKey,
                child: JobTypeFilterScreen(filter: filter, isAdminScope: false),
              );
            },
          ),
          GoRoute(
            path: '/tech/profile',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const TechProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/tech/reports',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const ReportsHubScreen(),
            ),
          ),
          GoRoute(
            path: '/tech/settings',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/approvals',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const ApprovalsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settlements',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const InvoiceSettlementsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/reconcile',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const InvoiceReconciliationScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/analytics',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/team',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const TeamScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/companies',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const CompaniesScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/import',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const HistoricalImportScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/flush',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const FlushDatabaseScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/jobs/filter/:type',
            pageBuilder: (context, state) {
              final typeRaw = state.pathParameters['type'] ?? '';
              final filter =
                  jobAcTypeFilterFromPath(typeRaw) ?? JobAcTypeFilter.split;
              return _slideFadePage(
                pageKey: state.pageKey,
                child: JobTypeFilterScreen(filter: filter, isAdminScope: true),
              );
            },
          ),
          GoRoute(
            path: '/admin/job/:jobId',
            pageBuilder: (context, state) {
              final initialJob = state.extra is JobModel
                  ? state.extra as JobModel
                  : null;
              final jobId = state.pathParameters['jobId'] ?? '';
              return _slideFadePage(
                pageKey: state.pageKey,
                child: JobDetailsScreen(jobId: jobId, initialJob: initialJob),
              );
            },
          ),
        ],
      ),
    ],
  );
});

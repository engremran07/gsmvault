import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/auth/data/auth_repository.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/admin/providers/admin_providers.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';
import 'package:ac_techs/features/settings/data/approval_config_repository.dart';
import 'package:ac_techs/features/settings/data/app_branding_repository.dart';
import 'package:ac_techs/features/settings/providers/approval_config_provider.dart';
import 'package:ac_techs/features/settings/providers/app_branding_provider.dart';
import 'package:ac_techs/features/expenses/providers/expense_providers.dart';
import 'package:ac_techs/features/expenses/data/expense_repository.dart';
import 'package:ac_techs/features/expenses/data/earning_repository.dart';
import 'package:ac_techs/features/expenses/data/ac_install_repository.dart';
import 'package:ac_techs/features/expenses/providers/ac_install_providers.dart';
import 'package:ac_techs/core/providers/app_build_provider.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(authRepositoryProvider).userStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (e, st) =>
        Stream.error(e, st), // propagate — don't swallow to silent null
  );
});

final signInProvider = AsyncNotifierProvider<SignInNotifier, void>(
  SignInNotifier.new,
);

class SignInNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<UserModel> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .signIn(email, password);
      state = const AsyncData(null);
      return user;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    // Add any new session-scoped data providers here so sign-out fully clears
    // the previous user's cached listeners before the next login.
    ref.invalidate(technicianJobsProvider);
    ref.invalidate(todaysJobsProvider);
    ref.invalidate(pendingApprovalsProvider);
    ref.invalidate(adminSettlementCandidatesProvider);
    ref.invalidate(adminSettlementHistoryProvider);
    ref.invalidate(settlementSummaryProvider);
    ref.invalidate(technicianSettlementInboxProvider);
    ref.invalidate(allTechniciansProvider);
    ref.invalidate(allUsersProvider);
    ref.invalidate(allCompaniesProvider);
    ref.invalidate(activeCompaniesProvider);
    ref.invalidate(techExpensesProvider);
    ref.invalidate(todaysExpensesProvider);
    ref.invalidate(monthlyExpensesProvider);
    ref.invalidate(techEarningsProvider);
    ref.invalidate(todaysEarningsProvider);
    ref.invalidate(monthlyEarningsProvider);
    ref.invalidate(pendingExpensesProvider);
    ref.invalidate(pendingEarningsProvider);
    ref.invalidate(dailyExpensesProvider);
    ref.invalidate(dailyEarningsProvider);
    ref.invalidate(pendingAcInstallsProvider);
    ref.invalidate(approvalConfigProvider);
    ref.invalidate(appBrandingProvider);
    ref.invalidate(appPackageInfoProvider);
    ref.invalidate(appBuildNumberProvider);
    ref.invalidate(appVersionLabelProvider);
    ref.invalidate(currentUserProvider);

    // 2. Sign out from Firebase Auth
    await ref.read(authRepositoryProvider).signOut();

    // 3. Invalidate repository providers so next login gets fresh Firestore instances
    ref.invalidate(jobRepositoryProvider);
    ref.invalidate(userRepositoryProvider);
    ref.invalidate(authRepositoryProvider);
    ref.invalidate(expenseRepositoryProvider);
    ref.invalidate(earningRepositoryProvider);
    ref.invalidate(acInstallRepositoryProvider);
    ref.invalidate(approvalConfigRepositoryProvider);
    ref.invalidate(appBrandingRepositoryProvider);
    ref.invalidate(authStateProvider);
  }
}

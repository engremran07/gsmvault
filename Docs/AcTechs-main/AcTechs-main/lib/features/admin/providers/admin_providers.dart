import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/expenses/providers/expense_providers.dart';
import 'package:ac_techs/features/expenses/providers/ac_install_providers.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';

class FlushProgressState {
  const FlushProgressState({
    required this.phase,
    required this.step,
    required this.totalSteps,
  });

  static const idle = FlushProgressState(
    phase: FlushOperationPhase.idle,
    step: 0,
    totalSteps: 0,
  );

  final FlushOperationPhase phase;
  final int step;
  final int totalSteps;

  bool get isRunning =>
      phase != FlushOperationPhase.idle &&
      phase != FlushOperationPhase.completed;

  double? get progressValue => totalSteps > 0 ? step / totalSteps : null;
}

final allTechniciansProvider = StreamProvider.autoDispose<List<UserModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(userRepositoryProvider).allTechnicians();
});

/// All active technicians, without an admin guard.
/// Used by the shared install team selector dropdown so technicians can pick
/// their teammates. Safe because [firestore.rules] restricts the users list
/// to `isActiveUser() || isAdmin()` only — closed employee system.
final activeTechniciansForTeamProvider =
    StreamProvider.autoDispose<List<UserModel>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref.watch(userRepositoryProvider).allTechnicians();
    });

final allUsersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(userRepositoryProvider).allUsers();
});

final flushDatabaseProvider =
    AsyncNotifierProvider<FlushDatabaseNotifier, FlushProgressState>(
      FlushDatabaseNotifier.new,
    );

class FlushDatabaseNotifier extends AsyncNotifier<FlushProgressState> {
  @override
  FutureOr<FlushProgressState> build() => FlushProgressState.idle;

  List<FlushOperationPhase> _phasePlan({
    required bool isTechnicianScope,
    required bool deleteNonAdminUsers,
  }) {
    if (isTechnicianScope) {
      return const [
        FlushOperationPhase.verifyingPassword,
        FlushOperationPhase.checkingConnection,
        FlushOperationPhase.scanningAffectedData,
        FlushOperationPhase.deletingOperationalData,
        FlushOperationPhase.rebuildingDerivedData,
        FlushOperationPhase.clearingLocalCache,
        FlushOperationPhase.refreshingAppData,
        FlushOperationPhase.completed,
      ];
    }

    return [
      FlushOperationPhase.verifyingPassword,
      FlushOperationPhase.checkingConnection,
      FlushOperationPhase.deletingOperationalData,
      FlushOperationPhase.deletingDerivedData,
      FlushOperationPhase.deletingCompanies,
      if (deleteNonAdminUsers) FlushOperationPhase.archivingUsers,
      FlushOperationPhase.clearingLocalCache,
      FlushOperationPhase.refreshingAppData,
      FlushOperationPhase.completed,
    ];
  }

  void _setPhase(
    FlushOperationPhase phase, {
    required bool isTechnicianScope,
    required bool deleteNonAdminUsers,
  }) {
    final plan = _phasePlan(
      isTechnicianScope: isTechnicianScope,
      deleteNonAdminUsers: deleteNonAdminUsers,
    );
    final stepIndex = plan.indexOf(phase);
    state = AsyncData(
      FlushProgressState(
        phase: phase,
        step: stepIndex < 0 ? 0 : stepIndex + 1,
        totalSteps: plan.length,
      ),
    );
  }

  /// Verifies the admin password then flushes the database.
  Future<void> flush(
    String password, {
    required bool deleteNonAdminUsers,
    String? targetTechnicianId,
  }) async {
    final technicianId = targetTechnicianId?.trim();
    final isTechnicianScope = technicianId != null && technicianId.isNotEmpty;

    try {
      final repo = ref.read(userRepositoryProvider);
      _setPhase(
        FlushOperationPhase.verifyingPassword,
        isTechnicianScope: isTechnicianScope,
        deleteNonAdminUsers: deleteNonAdminUsers,
      );
      await repo.verifyAdminPassword(password);
      if (isTechnicianScope) {
        await repo.flushTechnicianData(
          technicianId,
          onProgress: (phase) => _setPhase(
            phase,
            isTechnicianScope: true,
            deleteNonAdminUsers: deleteNonAdminUsers,
          ),
        );
      } else {
        await repo.flushDatabase(
          deleteNonAdminUsers: deleteNonAdminUsers,
          onProgress: (phase) => _setPhase(
            phase,
            isTechnicianScope: false,
            deleteNonAdminUsers: deleteNonAdminUsers,
          ),
        );
      }

      _setPhase(
        FlushOperationPhase.refreshingAppData,
        isTechnicianScope: isTechnicianScope,
        deleteNonAdminUsers: deleteNonAdminUsers,
      );

      // Invalidate all data providers so screens show fresh (empty) state.
      // StreamProviders auto-update, but FutureProviders need manual invalidation.
      ref.invalidate(adminJobSummaryProvider);
      ref.invalidate(adminSettlementCandidatesProvider);
      ref.invalidate(adminSettlementHistoryProvider);
      ref.invalidate(settlementSummaryProvider);
      ref.invalidate(technicianJobsProvider);
      ref.invalidate(todaysJobsProvider);
      ref.invalidate(pendingApprovalsProvider);
      ref.invalidate(techExpensesProvider);
      ref.invalidate(todaysExpensesProvider);
      ref.invalidate(techEarningsProvider);
      ref.invalidate(todaysEarningsProvider);
      ref.invalidate(monthlyExpensesProvider);
      ref.invalidate(monthlyEarningsProvider);
      ref.invalidate(pendingExpensesProvider);
      ref.invalidate(pendingEarningsProvider);
      ref.invalidate(allCompaniesProvider);
      ref.invalidate(activeCompaniesProvider);
      ref.invalidate(allTechniciansProvider);
      ref.invalidate(allUsersProvider);
      ref.invalidate(technicianSettlementInboxProvider);
      ref.invalidate(pendingAcInstallsProvider);

      _setPhase(
        FlushOperationPhase.completed,
        isTechnicianScope: isTechnicianScope,
        deleteNonAdminUsers: deleteNonAdminUsers,
      );
    } catch (e) {
      state = const AsyncData(FlushProgressState.idle);
      rethrow;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/technician_job_summary.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

enum JobAcTypeFilter { split, window, freestanding, bracket, uninstall }

class AdminJobsQuery {
  const AdminJobsQuery({this.start, this.end, this.techId});

  final DateTime? start;
  final DateTime? end;
  final String? techId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminJobsQuery &&
        other.start == start &&
        other.end == end &&
        other.techId == techId;
  }

  @override
  int get hashCode => Object.hash(start, end, techId);
}

class SharedInstallerNamesQuery {
  SharedInstallerNamesQuery._(this.groupKeys);

  factory SharedInstallerNamesQuery.fromKeys(Iterable<String> rawKeys) {
    final keys =
        rawKeys
            .map((key) => key.trim())
            .where((key) => key.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    return SharedInstallerNamesQuery._(keys);
  }

  factory SharedInstallerNamesQuery.fromJobs(Iterable<JobModel> jobs) {
    return SharedInstallerNamesQuery.fromKeys(
      jobs
          .where((job) => job.isSharedInstall)
          .map((job) => job.sharedInstallGroupKey),
    );
  }

  final List<String> groupKeys;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SharedInstallerNamesQuery) return false;
    if (groupKeys.length != other.groupKeys.length) return false;
    for (var i = 0; i < groupKeys.length; i++) {
      if (groupKeys[i] != other.groupKeys[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(groupKeys);
}

String jobAcTypeFilterToPath(JobAcTypeFilter filter) {
  switch (filter) {
    case JobAcTypeFilter.split:
      return 'split';
    case JobAcTypeFilter.window:
      return 'window';
    case JobAcTypeFilter.freestanding:
      return 'freestanding';
    case JobAcTypeFilter.bracket:
      return 'bracket';
    case JobAcTypeFilter.uninstall:
      return 'uninstall';
  }
}

JobAcTypeFilter? jobAcTypeFilterFromPath(String raw) {
  switch (raw.toLowerCase()) {
    case 'split':
      return JobAcTypeFilter.split;
    case 'window':
      return JobAcTypeFilter.window;
    case 'freestanding':
      return JobAcTypeFilter.freestanding;
    case 'bracket':
      return JobAcTypeFilter.bracket;
    case 'uninstall':
      return JobAcTypeFilter.uninstall;
    default:
      return null;
  }
}

String _unitTypeForFilter(JobAcTypeFilter filter) {
  switch (filter) {
    case JobAcTypeFilter.split:
      return 'Split AC';
    case JobAcTypeFilter.window:
      return 'Window AC';
    case JobAcTypeFilter.freestanding:
      return 'Freestanding AC';
    case JobAcTypeFilter.bracket:
    case JobAcTypeFilter.uninstall:
      return '';
  }
}

List<JobModel> _jobsByType(List<JobModel> jobs, JobAcTypeFilter filter) {
  switch (filter) {
    case JobAcTypeFilter.bracket:
      return jobs
          .where((job) => job.effectiveBracketCount > 0)
          .toList(growable: false);
    case JobAcTypeFilter.uninstall:
      return jobs
          .where(
            (job) => job.acUnits.any(
              (unit) => unit.type.startsWith('Uninstall') && unit.quantity > 0,
            ),
          )
          .toList(growable: false);
    default:
      final unitType = _unitTypeForFilter(filter);
      return jobs
          .where(
            (job) => job.acUnits.any(
              (unit) => unit.type == unitType && unit.quantity > 0,
            ),
          )
          .toList(growable: false);
  }
}

final technicianJobsProvider = StreamProvider.autoDispose<List<JobModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(jobRepositoryProvider).technicianJobs(user.uid);
});

final todaysJobsProvider = Provider.autoDispose<AsyncValue<List<JobModel>>>((
  ref,
) {
  // Derived from technicianJobsProvider — no extra Firestore listener on jobs/.
  final today = DateTime.now();
  return ref
      .watch(technicianJobsProvider)
      .whenData(
        (jobs) => jobs
            .where(
              (j) =>
                  j.date?.year == today.year &&
                  j.date?.month == today.month &&
                  j.date?.day == today.day,
            )
            .toList(growable: false),
      );
});

final pendingApprovalsProvider = StreamProvider.autoDispose<List<JobModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(jobRepositoryProvider).pendingApprovals();
});

final approvedSharedInstallsProvider =
    StreamProvider.autoDispose<List<JobModel>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null || !user.isAdmin) return Stream.value([]);
      return ref.watch(jobRepositoryProvider).approvedSharedInstalls();
    });

final adminSettlementCandidatesProvider =
    FutureProvider.autoDispose<List<JobModel>>((ref) async {
      final user = ref.watch(currentUserProvider).value;
      if (user == null || !user.isAdmin) return const <JobModel>[];
      return ref.watch(jobRepositoryProvider).fetchSettlementCandidates();
    });

final adminSettlementHistoryProvider =
    FutureProvider.autoDispose<List<JobModel>>((ref) async {
      final user = ref.watch(currentUserProvider).value;
      if (user == null || !user.isAdmin) return const <JobModel>[];
      return ref.watch(jobRepositoryProvider).fetchSettlementHistory();
    });

final settlementSummaryProvider =
    FutureProvider.autoDispose<
      ({
        int unpaidCount,
        double unpaidAmount,
        int pendingConfirmCount,
        int confirmedCount,
        int disputedCount,
      })
    >((ref) async {
      final user = ref.watch(currentUserProvider).value;
      if (user == null || !user.isAdmin) {
        return (
          unpaidCount: 0,
          unpaidAmount: 0.0,
          pendingConfirmCount: 0,
          confirmedCount: 0,
          disputedCount: 0,
        );
      }

      return ref.watch(jobRepositoryProvider).fetchSettlementSummary();
    });

final technicianSettlementInboxProvider =
    StreamProvider.autoDispose<List<JobModel>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref
          .watch(jobRepositoryProvider)
          .technicianSettlementInbox(user.uid);
    });

final settlementBatchJobsProvider = StreamProvider.autoDispose
    .family<List<JobModel>, String>((ref, batchId) {
      if (batchId.trim().isEmpty) {
        return Stream.value(const <JobModel>[]);
      }
      return ref.watch(jobRepositoryProvider).settlementBatchJobs(batchId);
    });

final adminJobSummaryProvider = FutureProvider.autoDispose<AdminJobSummary>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) {
    return Future.value(AdminJobSummary.empty());
  }
  return ref.watch(jobRepositoryProvider).fetchAdminJobSummary();
});

final adminScopedJobSummaryProvider = FutureProvider.autoDispose
    .family<AdminJobSummary, AdminJobsQuery>((ref, query) async {
      final user = ref.watch(currentUserProvider).value;
      if (user == null || !user.isAdmin) {
        return AdminJobSummary.empty();
      }
      final jobs = await ref.watch(filteredAdminJobsProvider(query).future);
      return AdminJobSummary.fromJobs(jobs);
    });

final filteredAdminJobsProvider = FutureProvider.autoDispose
    .family<List<JobModel>, AdminJobsQuery>((ref, query) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null || !user.isAdmin) return Future.value(const []);
      return ref
          .watch(jobRepositoryProvider)
          .jobsForAdminFilter(
            start: query.start,
            end: query.end,
            techId: query.techId,
          );
    });

final sharedInstallerNamesProvider = FutureProvider.autoDispose
    .family<Map<String, List<String>>, SharedInstallerNamesQuery>((
      ref,
      query,
    ) async {
      if (query.groupKeys.isEmpty) {
        return const <String, List<String>>{};
      }
      return ref
          .watch(jobRepositoryProvider)
          .fetchSharedInstallerNamesByGroup(query.groupKeys);
    });

final techJobsByAcTypeProvider = Provider.autoDispose
    .family<List<JobModel>, JobAcTypeFilter>((ref, filter) {
      final jobs =
          ref.watch(technicianJobsProvider).value ?? const <JobModel>[];
      return _jobsByType(jobs, filter);
    });

final technicianJobSummaryProvider =
    Provider.autoDispose<AsyncValue<TechnicianJobSummary>>((ref) {
      return ref
          .watch(technicianJobsProvider)
          .whenData(TechnicianJobSummary.fromJobs);
    });

/// Monthly jobs for the logged-in tech.
final monthlyJobsProvider = StreamProvider.autoDispose
    .family<List<JobModel>, DateTime>((ref, month) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref.watch(jobRepositoryProvider).monthlyJobs(user.uid, month);
    });

final monthlyTechnicianJobSummaryProvider = Provider.autoDispose
    .family<AsyncValue<TechnicianJobSummary>, DateTime>((ref, month) {
      return ref
          .watch(monthlyJobsProvider(month))
          .whenData(TechnicianJobSummary.fromJobs);
    });

/// Shared install aggregates older than 7 days that are not fully consumed.
/// Admin-only; used on the dashboard for stale install notification.
final staleSharedAggregatesProvider =
    FutureProvider.autoDispose<List<SharedInstallAggregate>>((ref) {
      return ref.watch(jobRepositoryProvider).fetchStaleSharedAggregates();
    });

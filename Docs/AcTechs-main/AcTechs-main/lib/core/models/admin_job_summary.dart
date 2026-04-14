import 'dart:collection';

import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/job_model.dart';

class AdminTechnicianJobTotal {
  const AdminTechnicianJobTotal({
    required this.techId,
    required this.techName,
    required this.jobCount,
  });

  final String techId;
  final String techName;
  final int jobCount;

  String get displayName => techName.trim().isEmpty ? techId : techName;
}

class AdminJobSummary {
  const AdminJobSummary({
    required this.totalJobs,
    required this.pendingJobs,
    required this.approvedJobs,
    required this.rejectedJobs,
    required this.totalExpenses,
    required this.splitUnits,
    required this.windowUnits,
    required this.freestandingUnits,
    required this.invoiceAwareUnitTotal,
    required this.sharedJobsCount,
    required this.sharedInvoiceCount,
    required this.sharedInvoiceUnits,
    required this.sharedInvoiceBrackets,
    required this.uninstallOldUnits,
    required this.uninstallSplitUnits,
    required this.uninstallWindowUnits,
    required this.uninstallStandingUnits,
    required this.technicianJobCounts,
  });

  final int totalJobs;
  final int pendingJobs;
  final int approvedJobs;
  final int rejectedJobs;
  final double totalExpenses;
  final int splitUnits;
  final int windowUnits;
  final int freestandingUnits;
  final int invoiceAwareUnitTotal;
  final int sharedJobsCount;
  final int sharedInvoiceCount;
  final int sharedInvoiceUnits;
  final int sharedInvoiceBrackets;
  final int uninstallOldUnits;
  final int uninstallSplitUnits;
  final int uninstallWindowUnits;
  final int uninstallStandingUnits;
  final List<AdminTechnicianJobTotal> technicianJobCounts;

  int get uninstallTotal =>
      uninstallOldUnits +
      uninstallSplitUnits +
      uninstallWindowUnits +
      uninstallStandingUnits;

  int get technicianCount => technicianJobCounts.length;

  Map<String, int> get technicianJobsMap {
    return UnmodifiableMapView({
      for (final item in technicianJobCounts) item.techId: item.jobCount,
    });
  }

  factory AdminJobSummary.empty() {
    return const AdminJobSummary(
      totalJobs: 0,
      pendingJobs: 0,
      approvedJobs: 0,
      rejectedJobs: 0,
      totalExpenses: 0,
      splitUnits: 0,
      windowUnits: 0,
      freestandingUnits: 0,
      invoiceAwareUnitTotal: 0,
      sharedJobsCount: 0,
      sharedInvoiceCount: 0,
      sharedInvoiceUnits: 0,
      sharedInvoiceBrackets: 0,
      uninstallOldUnits: 0,
      uninstallSplitUnits: 0,
      uninstallWindowUnits: 0,
      uninstallStandingUnits: 0,
      technicianJobCounts: <AdminTechnicianJobTotal>[],
    );
  }

  factory AdminJobSummary.fromJobs(Iterable<JobModel> jobs) {
    var totalJobs = 0;
    var pendingJobs = 0;
    var approvedJobs = 0;
    var rejectedJobs = 0;
    var totalExpenses = 0.0;
    var splitUnits = 0;
    var windowUnits = 0;
    var freestandingUnits = 0;
    var invoiceAwareUnitTotal = 0;
    var sharedJobsCount = 0;
    var sharedInvoiceCount = 0;
    var sharedInvoiceUnits = 0;
    var sharedInvoiceBrackets = 0;
    var uninstallOldUnits = 0;
    var uninstallSplitUnits = 0;
    var uninstallWindowUnits = 0;
    var uninstallStandingUnits = 0;

    final seenSharedGroups = <String>{};
    final technicianJobs = <String, ({String techName, int jobCount})>{};

    for (final job in jobs) {
      totalJobs += 1;
      totalExpenses += job.expenses;

      switch (job.status) {
        case JobStatus.pending:
          pendingJobs += 1;
        case JobStatus.approved:
          approvedJobs += 1;
        case JobStatus.rejected:
          rejectedJobs += 1;
      }

      final existing = technicianJobs[job.techId];
      technicianJobs[job.techId] = (
        techName: job.techName.trim().isEmpty ? job.techId : job.techName,
        jobCount: (existing?.jobCount ?? 0) + 1,
      );

      if (job.status == JobStatus.rejected) {
        continue;
      }

      splitUnits += job.unitsForType(AppConstants.unitTypeSplitAc);
      windowUnits += job.unitsForType(AppConstants.unitTypeWindowAc);
      freestandingUnits += job.unitsForType(
        AppConstants.unitTypeFreestandingAc,
      );
      uninstallOldUnits += job.unitsForType(AppConstants.unitTypeUninstallOld);
      uninstallSplitUnits += job.unitsForType(
        AppConstants.unitTypeUninstallSplit,
      );
      uninstallWindowUnits += job.unitsForType(
        AppConstants.unitTypeUninstallWindow,
      );
      uninstallStandingUnits += job.unitsForType(
        AppConstants.unitTypeUninstallFreestanding,
      );

      if (job.isSharedInstall && job.sharedInstallGroupKey.isNotEmpty) {
        sharedJobsCount += 1;
        if (seenSharedGroups.add(job.sharedInstallGroupKey)) {
          sharedInvoiceCount += 1;
          sharedInvoiceUnits += job.sharedInvoiceTotalUnits;
          sharedInvoiceBrackets += job.sharedInvoiceBracketCount;
          invoiceAwareUnitTotal += job.sharedInvoiceTotalUnits;
        }
        continue;
      }

      invoiceAwareUnitTotal += job.totalUnits;
    }

    final technicianJobCounts =
        technicianJobs.entries
            .map(
              (entry) => AdminTechnicianJobTotal(
                techId: entry.key,
                techName: entry.value.techName,
                jobCount: entry.value.jobCount,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final byCount = b.jobCount.compareTo(a.jobCount);
            return byCount != 0
                ? byCount
                : a.displayName.compareTo(b.displayName);
          });

    return AdminJobSummary(
      totalJobs: totalJobs,
      pendingJobs: pendingJobs,
      approvedJobs: approvedJobs,
      rejectedJobs: rejectedJobs,
      totalExpenses: totalExpenses,
      splitUnits: splitUnits,
      windowUnits: windowUnits,
      freestandingUnits: freestandingUnits,
      invoiceAwareUnitTotal: invoiceAwareUnitTotal,
      sharedJobsCount: sharedJobsCount,
      sharedInvoiceCount: sharedInvoiceCount,
      sharedInvoiceUnits: sharedInvoiceUnits,
      sharedInvoiceBrackets: sharedInvoiceBrackets,
      uninstallOldUnits: uninstallOldUnits,
      uninstallSplitUnits: uninstallSplitUnits,
      uninstallWindowUnits: uninstallWindowUnits,
      uninstallStandingUnits: uninstallStandingUnits,
      technicianJobCounts: technicianJobCounts,
    );
  }
}

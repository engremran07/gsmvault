import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/job_model.dart';

class TechnicianJobSummary {
  const TechnicianJobSummary({
    required this.totalJobs,
    required this.pendingJobs,
    required this.approvedJobs,
    required this.rejectedJobs,
    required this.sharedJobs,
    required this.totalUnits,
    required this.splitUnits,
    required this.windowUnits,
    required this.freestandingUnits,
    required this.bracketCount,
    required this.uninstallTotal,
  });

  final int totalJobs;
  final int pendingJobs;
  final int approvedJobs;
  final int rejectedJobs;
  final int sharedJobs;
  final int totalUnits;
  final int splitUnits;
  final int windowUnits;
  final int freestandingUnits;
  final int bracketCount;
  final int uninstallTotal;

  factory TechnicianJobSummary.empty() {
    return const TechnicianJobSummary(
      totalJobs: 0,
      pendingJobs: 0,
      approvedJobs: 0,
      rejectedJobs: 0,
      sharedJobs: 0,
      totalUnits: 0,
      splitUnits: 0,
      windowUnits: 0,
      freestandingUnits: 0,
      bracketCount: 0,
      uninstallTotal: 0,
    );
  }

  factory TechnicianJobSummary.fromJobs(Iterable<JobModel> jobs) {
    var totalJobs = 0;
    var pendingJobs = 0;
    var approvedJobs = 0;
    var rejectedJobs = 0;
    var sharedJobs = 0;
    var totalUnits = 0;
    var splitUnits = 0;
    var windowUnits = 0;
    var freestandingUnits = 0;
    var bracketCount = 0;
    var uninstallTotal = 0;

    for (final job in jobs) {
      totalJobs += 1;
      totalUnits += job.totalUnits;
      bracketCount += job.effectiveBracketCount;

      switch (job.status) {
        case JobStatus.pending:
          pendingJobs += 1;
        case JobStatus.approved:
          approvedJobs += 1;
        case JobStatus.rejected:
          rejectedJobs += 1;
      }

      if (job.isSharedInstall) {
        sharedJobs += 1;
      }

      splitUnits += job.unitsForType(AppConstants.unitTypeSplitAc);
      windowUnits += job.unitsForType(AppConstants.unitTypeWindowAc);
      freestandingUnits += job.unitsForType(
        AppConstants.unitTypeFreestandingAc,
      );
      uninstallTotal +=
          job.unitsForType(AppConstants.unitTypeUninstallOld) +
          job.unitsForType(AppConstants.unitTypeUninstallSplit) +
          job.unitsForType(AppConstants.unitTypeUninstallWindow) +
          job.unitsForType(AppConstants.unitTypeUninstallFreestanding);
    }

    return TechnicianJobSummary(
      totalJobs: totalJobs,
      pendingJobs: pendingJobs,
      approvedJobs: approvedJobs,
      rejectedJobs: rejectedJobs,
      sharedJobs: sharedJobs,
      totalUnits: totalUnits,
      splitUnits: splitUnits,
      windowUnits: windowUnits,
      freestandingUnits: freestandingUnits,
      bracketCount: bracketCount,
      uninstallTotal: uninstallTotal,
    );
  }
}

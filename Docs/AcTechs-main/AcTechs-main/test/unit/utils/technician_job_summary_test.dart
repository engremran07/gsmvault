import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/job_model.dart';
import 'package:ac_techs/core/utils/technician_job_summary.dart';

void main() {
  JobModel buildJob({
    required String invoiceNumber,
    JobStatus status = JobStatus.pending,
    bool isSharedInstall = false,
    int splitUnits = 0,
    int windowUnits = 0,
    int freestandingUnits = 0,
    int uninstallOldUnits = 0,
    int uninstallSplitUnits = 0,
    int uninstallWindowUnits = 0,
    int uninstallStandingUnits = 0,
    bool bracket = false,
  }) {
    return JobModel(
      techId: 'tech-1',
      techName: 'Ahsan',
      invoiceNumber: invoiceNumber,
      clientName: 'Client',
      status: status,
      isSharedInstall: isSharedInstall,
      charges: bracket
          ? const InvoiceCharges(acBracket: true, bracketAmount: 150)
          : null,
      acUnits: [
        if (splitUnits > 0)
          AcUnit(type: AppConstants.unitTypeSplitAc, quantity: splitUnits),
        if (windowUnits > 0)
          AcUnit(type: AppConstants.unitTypeWindowAc, quantity: windowUnits),
        if (freestandingUnits > 0)
          AcUnit(
            type: AppConstants.unitTypeFreestandingAc,
            quantity: freestandingUnits,
          ),
        if (uninstallOldUnits > 0)
          AcUnit(
            type: AppConstants.unitTypeUninstallOld,
            quantity: uninstallOldUnits,
          ),
        if (uninstallSplitUnits > 0)
          AcUnit(
            type: AppConstants.unitTypeUninstallSplit,
            quantity: uninstallSplitUnits,
          ),
        if (uninstallWindowUnits > 0)
          AcUnit(
            type: AppConstants.unitTypeUninstallWindow,
            quantity: uninstallWindowUnits,
          ),
        if (uninstallStandingUnits > 0)
          AcUnit(
            type: AppConstants.unitTypeUninstallFreestanding,
            quantity: uninstallStandingUnits,
          ),
      ],
    );
  }

  group('TechnicianJobSummary', () {
    test('builds consistent technician totals from jobs', () {
      final summary = TechnicianJobSummary.fromJobs([
        buildJob(
          invoiceNumber: 'INV-1',
          status: JobStatus.pending,
          splitUnits: 2,
          uninstallSplitUnits: 1,
          bracket: true,
        ),
        buildJob(
          invoiceNumber: 'INV-2',
          status: JobStatus.approved,
          isSharedInstall: true,
          windowUnits: 1,
          freestandingUnits: 1,
        ),
        buildJob(
          invoiceNumber: 'INV-3',
          status: JobStatus.rejected,
          uninstallOldUnits: 2,
        ),
      ]);

      expect(summary.totalJobs, 3);
      expect(summary.pendingJobs, 1);
      expect(summary.approvedJobs, 1);
      expect(summary.rejectedJobs, 1);
      expect(summary.sharedJobs, 1);
      expect(summary.totalUnits, 7);
      expect(summary.splitUnits, 2);
      expect(summary.windowUnits, 1);
      expect(summary.freestandingUnits, 1);
      expect(summary.bracketCount, 1);
      expect(summary.uninstallTotal, 3);
    });

    test('returns empty summary for empty input', () {
      final summary = TechnicianJobSummary.fromJobs(const <JobModel>[]);

      expect(summary.totalJobs, 0);
      expect(summary.totalUnits, 0);
      expect(summary.uninstallTotal, 0);
    });
  });
}

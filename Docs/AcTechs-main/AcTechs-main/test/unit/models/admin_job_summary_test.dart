import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/admin_job_summary.dart';
import 'package:ac_techs/core/models/job_model.dart';

void main() {
  JobModel buildJob({
    required String techId,
    required String techName,
    required String invoiceNumber,
    String groupKey = '',
    int splitUnits = 1,
    JobStatus status = JobStatus.pending,
  }) {
    return JobModel(
      techId: techId,
      techName: techName,
      invoiceNumber: invoiceNumber,
      clientName: 'Client',
      status: status,
      isSharedInstall: groupKey.isNotEmpty,
      sharedInstallGroupKey: groupKey,
      sharedInvoiceTotalUnits: groupKey.isNotEmpty ? 3 : 0,
      sharedInvoiceSplitUnits: groupKey.isNotEmpty ? 3 : 0,
      acUnits: [AcUnit(type: 'Split AC', quantity: splitUnits)],
    );
  }

  test('keys technician map by stable technician id', () {
    final summary = AdminJobSummary.fromJobs([
      buildJob(techId: 'tech-1', techName: 'Alex', invoiceNumber: 'INV-1'),
      buildJob(techId: 'tech-2', techName: 'Alex', invoiceNumber: 'INV-2'),
    ]);

    expect(summary.technicianJobsMap['tech-1'], 1);
    expect(summary.technicianJobsMap['tech-2'], 1);
  });

  test(
    'counts shared invoices once even when multiple technicians contribute',
    () {
      final summary = AdminJobSummary.fromJobs([
        buildJob(
          techId: 'tech-1',
          techName: 'Ali',
          invoiceNumber: 'INV-10',
          groupKey: 'group-10',
        ),
        buildJob(
          techId: 'tech-2',
          techName: 'Bilal',
          invoiceNumber: 'INV-10',
          groupKey: 'group-10',
        ),
      ]);

      expect(summary.sharedJobsCount, 2);
      expect(summary.sharedInvoiceCount, 1);
      expect(summary.invoiceAwareUnitTotal, 3);
    },
  );

  test('rejected jobs are excluded from unit and shared invoice totals', () {
    final summary = AdminJobSummary.fromJobs([
      buildJob(
        techId: 'tech-1',
        techName: 'Ali',
        invoiceNumber: 'INV-20',
        splitUnits: 2,
        status: JobStatus.approved,
      ),
      buildJob(
        techId: 'tech-2',
        techName: 'Bilal',
        invoiceNumber: 'INV-21',
        groupKey: 'group-21',
        status: JobStatus.rejected,
      ),
    ]);

    expect(summary.totalJobs, 2);
    expect(summary.rejectedJobs, 1);
    expect(summary.splitUnits, 2);
    expect(summary.sharedJobsCount, 0);
    expect(summary.sharedInvoiceCount, 0);
    expect(summary.invoiceAwareUnitTotal, 2);
  });
}

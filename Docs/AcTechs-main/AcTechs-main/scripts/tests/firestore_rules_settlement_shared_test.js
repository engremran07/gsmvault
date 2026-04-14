const fs = require('fs');
const path = require('path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const projectId = 'demo-actechs-rules-test-settlement-shared';
const rules = fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8');

async function seedDoc(context, docPath, data) {
  await context.firestore().doc(docPath).set(data);
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });

  try {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await seedDoc(context, 'users/admin-1', {
        name: 'Admin',
        email: 'admin@example.com',
        role: 'admin',
        isActive: true,
      });
      await seedDoc(context, 'users/tech-1', {
        name: 'Tech One',
        email: 'tech1@example.com',
        role: 'technician',
        isActive: true,
      });
      await seedDoc(context, 'users/tech-2', {
        name: 'Tech Two',
        email: 'tech2@example.com',
        role: 'technician',
        isActive: true,
      });
      await seedDoc(context, 'app_settings/approval_config', {
        inOutApprovalRequired: true,
        jobApprovalRequired: true,
        sharedJobApprovalRequired: true,
      });

      await seedDoc(context, 'jobs/job-settle-1', {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company One',
        invoiceNumber: 'INV-800',
        clientName: 'Client',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'approved',
        expenses: 0,
        date: new Date('2026-04-01T08:00:00Z'),
        submittedAt: new Date('2026-04-01T08:00:00Z'),
        approvedBy: 'admin-1',
        reviewedAt: new Date('2026-04-01T09:00:00Z'),
        adminNote: '',
        settlementStatus: 'awaiting_technician',
        settlementBatchId: 'pay_batch_1',
        settlementRound: 1,
        settlementAdminNote: 'confirm payment',
        settlementTechnicianComment: '',
        settlementRequestedBy: 'admin-1',
        settlementRequestedAt: new Date('2026-04-01T10:00:00Z'),
        settlementRespondedAt: null,
        settlementCorrectedAt: null,
      });

      await seedDoc(context, 'jobs/job-settle-2', {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company One',
        invoiceNumber: 'INV-801',
        clientName: 'Client',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'approved',
        expenses: 0,
        date: new Date('2026-04-01T08:00:00Z'),
        submittedAt: new Date('2026-04-01T08:00:00Z'),
        approvedBy: 'admin-1',
        reviewedAt: new Date('2026-04-01T09:00:00Z'),
        adminNote: '',
        settlementStatus: 'correction_required',
        settlementBatchId: 'pay_batch_2',
        settlementRound: 1,
        settlementAdminNote: 'correct amount',
        settlementTechnicianComment: 'wrong amount',
        settlementRequestedBy: 'admin-1',
        settlementRequestedAt: new Date('2026-04-01T10:00:00Z'),
        settlementRespondedAt: new Date('2026-04-01T11:00:00Z'),
        settlementCorrectedAt: null,
      });

      // REG-011: job on a locked-period date — tech must still be able to respond
      await seedDoc(context, 'jobs/job-settle-locked', {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company One',
        invoiceNumber: 'INV-802',
        clientName: 'Client',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'approved',
        expenses: 0,
        date: new Date('2025-12-01T08:00:00Z'), // December 2025 — will be locked below
        submittedAt: new Date('2025-12-01T08:00:00Z'),
        approvedBy: 'admin-1',
        reviewedAt: new Date('2025-12-01T09:00:00Z'),
        adminNote: '',
        settlementStatus: 'awaiting_technician',
        settlementBatchId: 'pay_batch_locked',
        settlementRound: 1,
        settlementAdminNote: 'locked period payment',
        settlementTechnicianComment: '',
        settlementRequestedBy: 'admin-1',
        settlementRequestedAt: new Date('2025-12-02T10:00:00Z'),
        settlementRespondedAt: null,
        settlementCorrectedAt: null,
      });
      // Lock all dates before 2026-01-01 (covers the December job above)
      await context.firestore().doc('app_settings/approval_config').update({
        lockedBefore: new Date('2026-01-01T00:00:00Z'),
      });

      await seedDoc(context, 'shared_install_aggregates/group-safe', {
        groupKey: 'group-safe',
        sharedInvoiceSplitUnits: 2,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 0,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 0,
        sharedInvoiceDeliveryAmount: 0,
        consumedSplitUnits: 1,
        consumedWindowUnits: 0,
        consumedFreestandingUnits: 0,
        consumedUninstallSplitUnits: 0,
        consumedUninstallWindowUnits: 0,
        consumedUninstallFreestandingUnits: 0,
        consumedBracketCount: 0,
        consumedDeliveryAmount: 0,
        createdBy: 'tech-1',
        createdAt: new Date('2026-04-01T08:00:00Z'),
        updatedAt: new Date('2026-04-01T08:00:00Z'),
        teamMemberIds: ['tech-1'],
        teamMemberNames: ['Tech One'],
      });
    });

    const tech1 = testEnv.authenticatedContext('tech-1');
    const tech2 = testEnv.authenticatedContext('tech-2');
    const admin = testEnv.authenticatedContext('admin-1');

    await assertSucceeds(
      tech1.firestore().doc('jobs/job-settle-1').update({
        settlementStatus: 'confirmed',
        settlementBatchId: 'pay_batch_1',
        settlementRound: 1,
        settlementAdminNote: 'confirm payment',
        settlementTechnicianComment: '',
        settlementRequestedBy: 'admin-1',
        settlementRequestedAt: new Date('2026-04-01T10:00:00Z'),
        settlementRespondedAt: new Date('2026-04-01T11:10:00Z'),
        settlementCorrectedAt: null,
      }),
    );

    await assertFails(
      tech1.firestore().doc('jobs/job-settle-1').update({
        settlementStatus: 'unpaid',
        settlementBatchId: 'pay_batch_1',
        settlementRound: 1,
        settlementAdminNote: 'confirm payment',
        settlementTechnicianComment: '',
        settlementRequestedBy: 'admin-1',
        settlementRequestedAt: new Date('2026-04-01T10:00:00Z'),
        settlementRespondedAt: new Date('2026-04-01T11:20:00Z'),
        settlementCorrectedAt: null,
      }),
    );

    await assertFails(
      tech1.firestore().doc('jobs/job-settle-1').update({
        settlementStatus: 'confirmed',
        settlementBatchId: 'pay_batch_1',
        settlementRound: 1,
        settlementAdminNote: 'tampered by tech',
        settlementTechnicianComment: '',
        settlementRequestedBy: 'admin-1',
        settlementRequestedAt: new Date('2026-04-01T10:00:00Z'),
        settlementRespondedAt: new Date('2026-04-01T11:10:00Z'),
        settlementCorrectedAt: null,
      }),
    );

    await assertFails(
      tech2.firestore().doc('jobs/job-settle-1').update({
        settlementStatus: 'confirmed',
        settlementBatchId: 'pay_batch_1',
        settlementRound: 1,
        settlementAdminNote: 'confirm payment',
        settlementTechnicianComment: '',
        settlementRequestedBy: 'admin-1',
        settlementRequestedAt: new Date('2026-04-01T10:00:00Z'),
        settlementRespondedAt: new Date('2026-04-01T11:15:00Z'),
        settlementCorrectedAt: null,
      }),
    );

    await assertSucceeds(
      admin.firestore().doc('jobs/job-settle-2').update({
        settlementStatus: 'awaiting_technician',
        settlementBatchId: 'pay_batch_2',
        settlementRound: 2,
        settlementAdminNote: 'resubmitted',
        settlementTechnicianComment: 'wrong amount',
        settlementRequestedBy: 'admin-1',
        settlementRequestedAt: new Date('2026-04-01T12:00:00Z'),
        settlementRespondedAt: null,
        settlementCorrectedAt: new Date('2026-04-01T12:00:00Z'),
      }),
    );

    await assertFails(
      admin.firestore().doc('jobs/job-settle-1').update({
        settlementStatus: 'awaiting_technician',
        settlementBatchId: 'pay_batch_1',
        settlementRound: 2,
        settlementAdminNote: 'reopen after confirm',
        settlementTechnicianComment: '',
        settlementRequestedBy: 'admin-1',
        settlementRequestedAt: new Date('2026-04-01T12:00:00Z'),
        settlementRespondedAt: null,
        settlementCorrectedAt: new Date('2026-04-01T12:00:00Z'),
      }),
    );

    // REG-011 regression: tech can confirm settlement on a date-locked period job
    // dateIsUnlocked() must NOT block settlement responses (only data edits)
    await assertSucceeds(
      tech1.firestore().doc('jobs/job-settle-locked').update({
        settlementStatus: 'confirmed',
        settlementBatchId: 'pay_batch_locked',
        settlementRound: 1,
        settlementAdminNote: 'locked period payment',
        settlementTechnicianComment: '',
        settlementRequestedBy: 'admin-1',
        settlementRequestedAt: new Date('2025-12-02T10:00:00Z'),
        settlementRespondedAt: new Date('2026-01-05T11:00:00Z'),
        settlementCorrectedAt: null,
      }),
    );

    await assertFails(
      tech1.firestore().doc('shared_install_aggregates/group-safe').update({
        groupKey: 'group-safe',
        sharedInvoiceSplitUnits: 2,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 0,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 0,
        sharedInvoiceDeliveryAmount: 0,
        consumedSplitUnits: 3,
        consumedWindowUnits: 0,
        consumedFreestandingUnits: 0,
        consumedUninstallSplitUnits: 0,
        consumedUninstallWindowUnits: 0,
        consumedUninstallFreestandingUnits: 0,
        consumedBracketCount: 0,
        consumedDeliveryAmount: 0,
        createdBy: 'tech-1',
        createdAt: new Date('2026-04-01T08:00:00Z'),
        updatedAt: new Date('2026-04-01T09:00:00Z'),
        teamMemberIds: ['tech-1'],
        teamMemberNames: ['Tech One'],
      }),
    );

    await assertSucceeds(
      tech1.firestore().doc('shared_install_aggregates/group-safe').update({
        groupKey: 'group-safe',
        sharedInvoiceSplitUnits: 2,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 0,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 0,
        sharedInvoiceDeliveryAmount: 0,
        consumedSplitUnits: 2,
        consumedWindowUnits: 0,
        consumedFreestandingUnits: 0,
        consumedUninstallSplitUnits: 0,
        consumedUninstallWindowUnits: 0,
        consumedUninstallFreestandingUnits: 0,
        consumedBracketCount: 0,
        consumedDeliveryAmount: 0,
        createdBy: 'tech-1',
        createdAt: new Date('2026-04-01T08:00:00Z'),
        updatedAt: new Date('2026-04-01T09:05:00Z'),
        teamMemberIds: ['tech-1'],
        teamMemberNames: ['Tech One'],
      }),
    );
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

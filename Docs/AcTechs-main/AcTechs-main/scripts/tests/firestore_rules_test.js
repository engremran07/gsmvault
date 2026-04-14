const fs = require('fs');
const path = require('path');
const assert = require('assert');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const projectId = 'demo-actechs-rules-test';
const rules = fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8');

async function seedDoc(context, docPath, data) {
  await context.firestore().doc(docPath).set(data);
}

function normalizeInvoice(invoiceNumber) {
  const trimmed = (invoiceNumber || '').trim();
  const upper = trimmed.toUpperCase();
  if (upper.startsWith('INV-') || upper.startsWith('INV ')) {
    return trimmed.substring(4).trim();
  }
  return trimmed;
}

function invoiceClaimDocId(invoiceNumber) {
  return normalizeInvoice(invoiceNumber).toLowerCase();
}

async function createJobWithClaim(context, job) {
  const batch = context.firestore().batch();
  const invoiceNumber = normalizeInvoice(job.invoiceNumber);
  const claimRef = context.firestore().doc(
    `invoice_claims/${invoiceClaimDocId(invoiceNumber)}`,
  );
  const jobRef = context.firestore().collection('jobs').doc();
  const existingClaim = await claimRef.get();
  const now = job.submittedAt;
  const persistedJob = {
    ...job,
    invoiceNumber,
  };

  if (!existingClaim.exists) {
    batch.set(claimRef, {
      invoiceNumber,
      companyId: job.companyId,
      companyName: job.companyName,
      reuseMode: job.isSharedInstall ? 'shared' : 'solo',
      activeJobCount: 1,
      createdBy: job.techId,
      createdAt: now,
      updatedAt: now,
    });
  } else {
    const claim = existingClaim.data();
    batch.update(claimRef, {
      invoiceNumber,
      companyId: claim.companyId,
      companyName: claim.companyName,
      reuseMode: claim.reuseMode,
      activeJobCount: (claim.activeJobCount || 0) + 1,
      createdBy: claim.createdBy,
      createdAt: claim.createdAt,
      updatedAt: now,
    });
  }

  batch.set(jobRef, persistedJob);
  await batch.commit();
}

function sharedAggregateDocId(groupKey) {
  return `shared_${groupKey.replace(/[^a-z0-9_-]/g, '_')}`;
}

async function createSharedJobWithClaimAndAggregate(context, job) {
  const batch = context.firestore().batch();
  const invoiceNumber = normalizeInvoice(job.invoiceNumber);
  const claimRef = context.firestore().doc(
    `invoice_claims/${invoiceClaimDocId(invoiceNumber)}`,
  );
  const aggregateRef = context.firestore().doc(
    `shared_install_aggregates/${sharedAggregateDocId(job.sharedInstallGroupKey)}`,
  );
  const jobRef = context.firestore().collection('jobs').doc();
  const existingClaim = await claimRef.get();
  const existingAggregate = await aggregateRef.get();
  const now = job.submittedAt;
  const persistedJob = {
    ...job,
    invoiceNumber,
  };

  if (!existingClaim.exists) {
    batch.set(claimRef, {
      invoiceNumber,
      companyId: job.companyId,
      companyName: job.companyName,
      reuseMode: 'shared',
      activeJobCount: 1,
      createdBy: job.techId,
      createdAt: now,
      updatedAt: now,
    });
  } else {
    const claim = existingClaim.data();
    batch.update(claimRef, {
      invoiceNumber,
      companyId: claim.companyId,
      companyName: claim.companyName,
      reuseMode: claim.reuseMode,
      activeJobCount: (claim.activeJobCount || 0) + 1,
      createdBy: claim.createdBy,
      createdAt: claim.createdAt,
      updatedAt: now,
    });
  }

  const splitContribution = job.techSplitShare || 0;
  const windowContribution = job.techWindowShare || 0;
  const freestandingContribution = job.techFreestandingShare || 0;
  const uninstallSplitContribution = job.techUninstallSplitShare || 0;
  const uninstallWindowContribution = job.techUninstallWindowShare || 0;
  const uninstallFreestandingContribution = job.techUninstallFreestandingShare || 0;
  const bracketContribution = job.techBracketShare || 0;
  const deliveryContribution = (job.charges && job.charges.deliveryAmount) || 0;

  if (!existingAggregate.exists) {
    batch.set(aggregateRef, {
      groupKey: job.sharedInstallGroupKey,
      sharedInvoiceSplitUnits: job.sharedInvoiceSplitUnits,
      sharedInvoiceWindowUnits: job.sharedInvoiceWindowUnits,
      sharedInvoiceFreestandingUnits: job.sharedInvoiceFreestandingUnits,
      sharedInvoiceUninstallSplitUnits: job.sharedInvoiceUninstallSplitUnits,
      sharedInvoiceUninstallWindowUnits: job.sharedInvoiceUninstallWindowUnits,
      sharedInvoiceUninstallFreestandingUnits: job.sharedInvoiceUninstallFreestandingUnits,
      sharedInvoiceBracketCount: job.sharedInvoiceBracketCount,
      sharedDeliveryTeamCount: job.sharedDeliveryTeamCount,
      sharedInvoiceDeliveryAmount: job.sharedInvoiceDeliveryAmount,
      consumedSplitUnits: splitContribution,
      consumedWindowUnits: windowContribution,
      consumedFreestandingUnits: freestandingContribution,
      consumedUninstallSplitUnits: uninstallSplitContribution,
      consumedUninstallWindowUnits: uninstallWindowContribution,
      consumedUninstallFreestandingUnits: uninstallFreestandingContribution,
      consumedBracketCount: bracketContribution,
      consumedDeliveryAmount: deliveryContribution,
      createdBy: job.techId,
      createdAt: now,
      updatedAt: now,
      teamMemberIds: [job.techId],
      teamMemberNames: [job.techName],
    });
  } else {
    const aggregate = existingAggregate.data();
    batch.update(aggregateRef, {
      groupKey: aggregate.groupKey,
      sharedInvoiceSplitUnits: aggregate.sharedInvoiceSplitUnits,
      sharedInvoiceWindowUnits: aggregate.sharedInvoiceWindowUnits,
      sharedInvoiceFreestandingUnits: aggregate.sharedInvoiceFreestandingUnits,
      sharedInvoiceUninstallSplitUnits: aggregate.sharedInvoiceUninstallSplitUnits,
      sharedInvoiceUninstallWindowUnits: aggregate.sharedInvoiceUninstallWindowUnits,
      sharedInvoiceUninstallFreestandingUnits: aggregate.sharedInvoiceUninstallFreestandingUnits,
      sharedInvoiceBracketCount: aggregate.sharedInvoiceBracketCount,
      sharedDeliveryTeamCount: aggregate.sharedDeliveryTeamCount,
      sharedInvoiceDeliveryAmount: aggregate.sharedInvoiceDeliveryAmount,
      consumedSplitUnits: (aggregate.consumedSplitUnits || 0) + splitContribution,
      consumedWindowUnits: (aggregate.consumedWindowUnits || 0) + windowContribution,
      consumedFreestandingUnits: (aggregate.consumedFreestandingUnits || 0) + freestandingContribution,
      consumedUninstallSplitUnits: (aggregate.consumedUninstallSplitUnits || 0) + uninstallSplitContribution,
      consumedUninstallWindowUnits: (aggregate.consumedUninstallWindowUnits || 0) + uninstallWindowContribution,
      consumedUninstallFreestandingUnits: (aggregate.consumedUninstallFreestandingUnits || 0) + uninstallFreestandingContribution,
      consumedBracketCount: (aggregate.consumedBracketCount || 0) + bracketContribution,
      consumedDeliveryAmount: (aggregate.consumedDeliveryAmount || 0) + deliveryContribution,
      createdBy: aggregate.createdBy,
      createdAt: aggregate.createdAt,
      updatedAt: now,
      teamMemberIds: aggregate.teamMemberIds || [aggregate.createdBy],
      teamMemberNames: aggregate.teamMemberNames || [job.techName],
    });
  }

  batch.set(jobRef, persistedJob);
  await batch.commit();
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
      await seedDoc(context, 'users/admin-2', {
        name: 'Inactive Admin',
        email: 'admin2@example.com',
        role: 'admin',
        isActive: false,
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
        isActive: false,
      });
      await seedDoc(context, 'app_settings/approval_config', {
        inOutApprovalRequired: true,
        jobApprovalRequired: true,
        sharedJobApprovalRequired: true,
        enforceMinimumBuild: false,
        minSupportedBuildNumber: 1,
      });
      await seedDoc(context, 'ac_installs/install-1', {
        techId: 'tech-1',
        techName: 'Tech One',
        splitTotal: 2,
        splitShare: 1,
        windowTotal: 0,
        windowShare: 0,
        freestandingTotal: 0,
        freestandingShare: 0,
        note: 'Pending install',
        status: 'pending',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T08:00:00Z'),
        createdAt: new Date('2024-01-12T08:00:00Z'),
        reviewedAt: null,
      });
    });

    const activeTech = testEnv.authenticatedContext('tech-1');
    const activeTechWithUpdatedEmail = testEnv.authenticatedContext('tech-1', {
      email: 'tech1+new@example.com',
    });
    const inactiveTech = testEnv.authenticatedContext('tech-2');
    const admin = testEnv.authenticatedContext('admin-1');
    const inactiveAdmin = testEnv.authenticatedContext('admin-2');

    await assertSucceeds(
      activeTech.firestore().collection('ac_installs').add({
        techId: 'tech-1',
        techName: 'Tech One',
        splitTotal: 3,
        splitShare: 2,
        windowTotal: 0,
        windowShare: 0,
        freestandingTotal: 0,
        freestandingShare: 0,
        note: 'Fresh install',
        status: 'pending',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T09:00:00Z'),
        createdAt: new Date('2024-01-12T09:00:00Z'),
        reviewedAt: null,
      }),
    );

    await assertFails(
      inactiveTech.firestore().collection('ac_installs').add({
        techId: 'tech-2',
        techName: 'Tech Two',
        splitTotal: 1,
        splitShare: 1,
        windowTotal: 0,
        windowShare: 0,
        freestandingTotal: 0,
        freestandingShare: 0,
        note: 'Blocked install',
        status: 'pending',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T09:00:00Z'),
        createdAt: new Date('2024-01-12T09:00:00Z'),
        reviewedAt: null,
      }),
    );

    await assertFails(
      activeTech.firestore().doc('ac_installs/install-1').update({
        status: 'approved',
        approvedBy: 'tech-1',
        adminNote: 'self approved',
        reviewedAt: new Date('2024-01-12T10:00:00Z'),
      }),
    );

    await assertSucceeds(
      activeTech.firestore().doc('users/tech-1').update({
        name: 'Tech One Updated',
      }),
    );

    await assertSucceeds(
      activeTech.firestore().doc('users/tech-1').update({
        language: 'ur',
      }),
    );

    await assertSucceeds(
      activeTech.firestore().doc('users/tech-1').update({
        themeMode: 'light',
      }),
    );

    await assertSucceeds(
      activeTechWithUpdatedEmail.firestore().doc('users/tech-1').update({
        email: 'tech1+new@example.com',
        emailLower: 'tech1+new@example.com',
      }),
    );

    await assertFails(
      activeTech.firestore().doc('users/tech-1').update({
        email: 'other@example.com',
      }),
    );

    await assertFails(
      activeTech.firestore().doc('users/tech-1').update({
        themeMode: 'neon',
      }),
    );

    await assertFails(activeTech.firestore().doc('users/tech-1').delete());

    await assertFails(inactiveAdmin.firestore().collection('users').get());

    await assertSucceeds(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-350',
        clientName: 'Solo Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: false,
        charges: null,
        date: new Date('2024-01-12T08:30:00Z'),
        submittedAt: new Date('2024-01-12T08:30:00Z'),
      }),
    );

    await assertSucceeds(
      activeTech.firestore().collection('expenses').add({
        techId: 'tech-1',
        techName: 'Tech One',
        category: 'Fuel',
        amount: 25,
        note: '',
        expenseType: 'work',
        status: 'pending',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T08:40:00Z'),
        createdAt: new Date('2024-01-12T08:40:00Z'),
        reviewedAt: null,
      }),
    );

    await assertSucceeds(
      activeTech.firestore().collection('earnings').add({
        techId: 'tech-1',
        techName: 'Tech One',
        category: 'Other',
        amount: 25,
        note: '',
        paymentType: 'regular',
        status: 'pending',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T08:41:00Z'),
        createdAt: new Date('2024-01-12T08:41:00Z'),
        reviewedAt: null,
      }),
    );

    await assertSucceeds(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-ABC350',
        clientName: 'Alpha Invoice Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: false,
        charges: null,
        date: new Date('2024-01-12T08:31:00Z'),
        submittedAt: new Date('2024-01-12T08:31:00Z'),
      }),
    );

    await assertSucceeds(
      createJobWithClaim(admin, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-351',
        clientName: 'Imported Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'approved',
        expenses: 0,
        expenseNote: 'Historical import',
        adminNote: 'Imported by admin',
        approvedBy: 'admin-1',
        isSharedInstall: false,
        charges: null,
        date: new Date('2024-01-11T08:30:00Z'),
        submittedAt: new Date('2024-01-11T08:30:00Z'),
      }),
    );

    await assertSucceeds(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-400',
        clientName: 'Client',
        clientContact: '',
        acUnits: [
          { type: 'Split AC', quantity: 1 },
          { type: 'Uninstallation Split', quantity: 1 },
        ],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: true,
        sharedInstallGroupKey: 'company-1-inv-400',
        sharedInvoiceTotalUnits: 3,
        sharedContributionUnits: 2,
        sharedInvoiceSplitUnits: 2,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 1,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 0,
        sharedInvoiceDeliveryAmount: 0,
        techSplitShare: 1,
        techWindowShare: 0,
        techFreestandingShare: 0,
        techUninstallSplitShare: 1,
        techUninstallWindowShare: 0,
        techUninstallFreestandingShare: 0,
        techBracketShare: 0,
        charges: null,
        date: new Date('2024-01-12T09:00:00Z'),
        submittedAt: new Date('2024-01-12T09:00:00Z'),
      }),
    );

    await assertSucceeds(
      createSharedJobWithClaimAndAggregate(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-402',
        clientName: 'Second Shared Client',
        clientContact: '',
        acUnits: [{ type: 'Window AC', quantity: 1 }],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: true,
        sharedInstallGroupKey: 'company-1-inv-402',
        sharedInvoiceTotalUnits: 2,
        sharedContributionUnits: 1,
        sharedInvoiceSplitUnits: 1,
        sharedInvoiceWindowUnits: 1,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 0,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 0,
        sharedInvoiceDeliveryAmount: 0,
        techSplitShare: 1,
        techWindowShare: 0,
        techFreestandingShare: 0,
        techUninstallSplitShare: 0,
        techUninstallWindowShare: 0,
        techUninstallFreestandingShare: 0,
        techBracketShare: 0,
        charges: null,
        date: new Date('2024-01-12T09:02:00Z'),
        submittedAt: new Date('2024-01-12T09:02:00Z'),
      }),
    );

    await assertSucceeds(
      createSharedJobWithClaimAndAggregate(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-402',
        clientName: 'Third Shared Client',
        clientContact: '',
        acUnits: [{ type: 'Window AC', quantity: 1 }],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: true,
        sharedInstallGroupKey: 'company-1-inv-402',
        sharedInvoiceTotalUnits: 2,
        sharedContributionUnits: 1,
        sharedInvoiceSplitUnits: 1,
        sharedInvoiceWindowUnits: 1,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 0,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 0,
        sharedInvoiceDeliveryAmount: 0,
        techSplitShare: 0,
        techWindowShare: 1,
        techFreestandingShare: 0,
        techUninstallSplitShare: 0,
        techUninstallWindowShare: 0,
        techUninstallFreestandingShare: 0,
        techBracketShare: 0,
        charges: null,
        date: new Date('2024-01-12T09:03:00Z'),
        submittedAt: new Date('2024-01-12T09:03:00Z'),
      }),
    );

    await assertFails(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-401',
        clientName: 'Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: true,
        sharedInstallGroupKey: 'company-1-inv-401',
        sharedInvoiceTotalUnits: 1,
        sharedContributionUnits: 1,
        sharedInvoiceSplitUnits: 1,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 0,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 2,
        sharedInvoiceDeliveryAmount: 1000001,
        techSplitShare: 1,
        techWindowShare: 0,
        techFreestandingShare: 0,
        techUninstallSplitShare: 0,
        techUninstallWindowShare: 0,
        techUninstallFreestandingShare: 0,
        techBracketShare: 0,
        charges: null,
        date: new Date('2024-01-12T09:05:00Z'),
        submittedAt: new Date('2024-01-12T09:05:00Z'),
      }),
    );

    await assertFails(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-2',
        companyName: 'Other Company',
        invoiceNumber: 'INV-350',
        clientName: 'Cross Company Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: false,
        charges: null,
        date: new Date('2024-01-12T08:45:00Z'),
        submittedAt: new Date('2024-01-12T08:45:00Z'),
      }),
    );

    await assertFails(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-2',
        companyName: 'Other Company',
        invoiceNumber: 'INV-400',
        clientName: 'Cross Company Shared Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: true,
        sharedInstallGroupKey: 'company-2-inv-400',
        sharedInvoiceTotalUnits: 1,
        sharedContributionUnits: 1,
        sharedInvoiceSplitUnits: 1,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 0,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 0,
        sharedInvoiceDeliveryAmount: 0,
        techSplitShare: 1,
        techWindowShare: 0,
        techFreestandingShare: 0,
        techUninstallSplitShare: 0,
        techUninstallWindowShare: 0,
        techUninstallFreestandingShare: 0,
        techBracketShare: 0,
        charges: null,
        date: new Date('2024-01-12T09:01:00Z'),
        submittedAt: new Date('2024-01-12T09:01:00Z'),
      }),
    );

    await assertSucceeds(
      activeTech.firestore().doc('shared_install_aggregates/group-1').set({
        groupKey: 'group-1',
        sharedInvoiceSplitUnits: 2,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 1,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 0,
        sharedInvoiceDeliveryAmount: 0,
        consumedSplitUnits: 1,
        consumedWindowUnits: 0,
        consumedFreestandingUnits: 0,
        consumedUninstallSplitUnits: 1,
        consumedUninstallWindowUnits: 0,
        consumedUninstallFreestandingUnits: 0,
        consumedBracketCount: 0,
        consumedDeliveryAmount: 0,
        createdBy: 'tech-1',
        createdAt: new Date('2024-01-12T09:00:00Z'),
        updatedAt: new Date('2024-01-12T09:00:00Z'),
        teamMemberIds: ['tech-1'],
        teamMemberNames: ['Tech One'],
      }),
    );

    await assertSucceeds(
      activeTech.firestore().doc('shared_install_aggregates/group-1').update({
        groupKey: 'group-1',
        sharedInvoiceSplitUnits: 2,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 1,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 0,
        sharedInvoiceDeliveryAmount: 0,
        consumedSplitUnits: 2,
        consumedWindowUnits: 0,
        consumedFreestandingUnits: 0,
        consumedUninstallSplitUnits: 1,
        consumedUninstallWindowUnits: 0,
        consumedUninstallFreestandingUnits: 0,
        consumedBracketCount: 0,
        consumedDeliveryAmount: 0,
        createdBy: 'tech-1',
        createdAt: new Date('2024-01-12T09:00:00Z'),
        updatedAt: new Date('2024-01-12T09:05:00Z'),
        teamMemberIds: ['tech-1'],
        teamMemberNames: ['Tech One'],
      }),
    );

    await assertFails(
      activeTech.firestore().doc('shared_install_aggregates/group-1').update({
        groupKey: 'group-1',
        sharedInvoiceSplitUnits: 2,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 1,
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
        createdAt: new Date('2024-01-12T09:00:00Z'),
        updatedAt: new Date('2024-01-12T09:06:00Z'),
        teamMemberIds: ['tech-1'],
        teamMemberNames: ['Tech One'],
      }),
    );

    await assertFails(activeTech.firestore().doc('ac_installs/install-1').delete());

    await assertSucceeds(
      admin.firestore().doc('ac_installs/install-1').update({
        status: 'approved',
        approvedBy: 'admin-1',
        adminNote: '',
        reviewedAt: new Date('2024-01-12T10:00:00Z'),
      }),
    );

    await assertSucceeds(
      admin.firestore().doc('ac_installs/install-1/history/event-1').set({
        changedBy: 'admin-1',
        changedAt: new Date('2024-01-12T10:00:00Z'),
        previousStatus: 'pending',
        newStatus: 'approved',
      }),
    );

    await testEnv.withSecurityRulesDisabled(async (context) => {
      await seedDoc(context, 'app_settings/approval_config', {
        inOutApprovalRequired: false,
        jobApprovalRequired: true,
        sharedJobApprovalRequired: true,
        enforceMinimumBuild: false,
        minSupportedBuildNumber: 1,
      });
    });

    await assertFails(
      activeTech.firestore().collection('expenses').add({
        techId: 'tech-1',
        techName: 'Tech One',
        category: 'Fuel',
        amount: 25,
        note: '',
        expenseType: 'work',
        status: 'approved',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T09:00:00Z'),
        createdAt: new Date('2024-01-12T09:00:00Z'),
        reviewedAt: null,
      }),
    );

    await assertFails(
      activeTech.firestore().collection('earnings').add({
        techId: 'tech-1',
        techName: 'Tech One',
        category: 'Other',
        amount: 25,
        note: '',
        paymentType: 'cash',
        status: 'approved',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T09:00:00Z'),
        createdAt: new Date('2024-01-12T09:00:00Z'),
        reviewedAt: null,
      }),
    );

    await assertSucceeds(
      activeTech.firestore().collection('expenses').add({
        techId: 'tech-1',
        techName: 'Tech One',
        category: 'Fuel',
        amount: 25,
        note: '',
        expenseType: 'work',
        status: 'approved',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T09:00:00Z'),
        createdAt: new Date('2024-01-12T09:00:00Z'),
        reviewedAt: new Date('2024-01-12T09:05:00Z'),
      }),
    );

    await assertSucceeds(
      activeTech.firestore().collection('earnings').add({
        techId: 'tech-1',
        techName: 'Tech One',
        category: 'Other',
        amount: 25,
        note: '',
        paymentType: 'cash',
        status: 'approved',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-01-12T09:00:00Z'),
        createdAt: new Date('2024-01-12T09:00:00Z'),
        reviewedAt: new Date('2024-01-12T09:05:00Z'),
      }),
    );

    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('app_settings/approval_config').delete();
    });

    await assertFails(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-999',
        clientName: 'Fail Closed Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'approved',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: false,
        charges: null,
        date: new Date('2024-01-12T09:30:00Z'),
        submittedAt: new Date('2024-01-12T09:30:00Z'),
      }),
    );

    await assertSucceeds(
      createJobWithClaim(activeTech, {
        techId: 'tech-1',
        techName: 'Tech One',
        companyId: 'company-1',
        companyName: 'Company',
        invoiceNumber: 'INV-1000',
        clientName: 'Pending Client',
        clientContact: '',
        acUnits: [{ type: 'Split AC', quantity: 1 }],
        status: 'pending',
        expenses: 0,
        expenseNote: '',
        adminNote: '',
        approvedBy: '',
        isSharedInstall: false,
        charges: null,
        date: new Date('2024-01-12T09:35:00Z'),
        submittedAt: new Date('2024-01-12T09:35:00Z'),
      }),
    );

    const historyDoc = await admin
      .firestore()
      .doc('ac_installs/install-1/history/event-1')
      .get();
    assert.strictEqual(historyDoc.data().newStatus, 'approved');

    // ── Cross-User Isolation Tests ─────────────────────────────────────────
    // Tech-2 (active but different tech) seeded for cross-user tests
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await seedDoc(context, 'users/tech-3', {
        name: 'Tech Three',
        email: 'tech3@example.com',
        role: 'technician',
        isActive: true,
      });
      await seedDoc(context, 'expenses/expense-tech1', {
        techId: 'tech-1',
        techName: 'Tech One',
        category: 'Fuel',
        amount: 100,
        note: 'Tech 1 expense',
        expenseType: 'work',
        status: 'pending',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-02-01T08:00:00Z'),
        createdAt: new Date('2024-02-01T08:00:00Z'),
        reviewedAt: null,
        isDeleted: false,
        deletedAt: null,
      });
      await seedDoc(context, 'earnings/earning-tech1', {
        techId: 'tech-1',
        techName: 'Tech One',
        category: 'Other',
        amount: 50,
        note: 'Tech 1 earning',
        status: 'pending',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-02-01T08:00:00Z'),
        createdAt: new Date('2024-02-01T08:00:00Z'),
        reviewedAt: null,
        isDeleted: false,
        deletedAt: null,
      });
      // Seed a dedicated aggregate for the H-03 membership check
      await seedDoc(context, 'shared_install_aggregates/iso-group-1', {
        groupKey: 'iso-group-1',
        companyId: '',
        companyName: '',
        clientName: '',
        clientContact: '',
        sharedInvoiceSplitUnits: 2,
        sharedInvoiceWindowUnits: 0,
        sharedInvoiceFreestandingUnits: 0,
        sharedInvoiceUninstallSplitUnits: 0,
        sharedInvoiceUninstallWindowUnits: 0,
        sharedInvoiceUninstallFreestandingUnits: 0,
        sharedInvoiceBracketCount: 0,
        sharedDeliveryTeamCount: 1,
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
        createdAt: new Date('2024-01-12T09:00:00Z'),
        updatedAt: new Date('2024-01-12T09:00:00Z'),
        teamMemberIds: ['tech-1'],
        teamMemberNames: ['Tech One'],
      });
    });

    const tech3Context = testEnv.authenticatedContext('tech-3');

    // Tech-3 CANNOT read Tech-1's expense
    await assertFails(
      tech3Context.firestore().doc('expenses/expense-tech1').get(),
    );

    // Tech-3 CANNOT read Tech-1's earning
    await assertFails(
      tech3Context.firestore().doc('earnings/earning-tech1').get(),
    );

    // Tech-3 CANNOT update Tech-1's expense
    await assertFails(
      tech3Context.firestore().doc('expenses/expense-tech1').update({
        amount: 999,
        note: 'tampered',
        isDeleted: true,
        deletedAt: new Date(),
      }),
    );

    // Tech-3 CANNOT update Tech-1's earning
    await assertFails(
      tech3Context.firestore().doc('earnings/earning-tech1').update({
        amount: 999,
        isDeleted: true,
        deletedAt: new Date(),
      }),
    );

    // Tech-3 CANNOT create an expense on behalf of Tech-1
    await assertFails(
      tech3Context.firestore().collection('expenses').add({
        techId: 'tech-1',
        techName: 'Tech One',
        category: 'Fuel',
        amount: 1,
        note: 'spoofed',
        expenseType: 'work',
        status: 'pending',
        approvedBy: '',
        adminNote: '',
        date: new Date('2024-02-01T09:00:00Z'),
        createdAt: new Date('2024-02-01T09:00:00Z'),
        reviewedAt: null,
      }),
    );

    // Tech-3 CANNOT update another tech's profile
    await assertFails(
      tech3Context.firestore().doc('users/tech-1').update({ name: 'Hacked' }),
    );

    // Tech-1 CANNOT read Tech-3's user document (cross-tech profile read)
    await assertFails(
      activeTech.firestore().doc('users/tech-3').get(),
    );

    // Admin CAN read any tech's expense
    await assertSucceeds(
      admin.firestore().doc('expenses/expense-tech1').get(),
    );

    // Admin CAN read any tech's earning
    await assertSucceeds(
      admin.firestore().doc('earnings/earning-tech1').get(),
    );

    // Tech-1 CAN get their own aggregate by known groupKey
    await assertSucceeds(
      activeTech.firestore().doc('shared_install_aggregates/iso-group-1').get(),
    );

    // Tech-3 CAN get a known aggregate by ID (low risk — requires guessing the id)
    // but CANNOT list/query aggregates they are not a member of (H-03 fix).
    // The list rule checks teamMemberIds per-document — tech-3 is not in iso-group-1.
    await assertFails(
      tech3Context.firestore()
        .collection('shared_install_aggregates')
        .where('groupKey', '==', 'iso-group-1')
        .get(),
    );

    // Tech-1 CAN list aggregates where they are a team member
    await assertSucceeds(
      activeTech.firestore()
        .collection('shared_install_aggregates')
        .where('teamMemberIds', 'array-contains', 'tech-1')
        .get(),
    );

    // Admin CAN list all aggregates without restriction
    await assertSucceeds(
      admin.firestore().collection('shared_install_aggregates').get(),
    );
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
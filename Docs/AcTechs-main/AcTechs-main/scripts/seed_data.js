/**
 * AC Techs — Firestore Seed-Data Script
 * Populates all collections with realistic test records so that PDF
 * reports can be generated and verified immediately after setup.
 *
 * Prerequisites:
 *   1. Run setup_users.js first to create auth users & Firestore user docs.
 *   2. Generate a service-account key and save it as scripts/service-account.json
 *      https://console.firebase.google.com/project/actechs-d415e/settings/serviceaccounts/adminsdk
 *
 * Usage:
 *   cd scripts
 *   node seed_data.js [--clear]   # --clear wipes existing data before seeding
 */

const admin = require('firebase-admin');
const path = require('path');

const serviceAccountPath = path.join(__dirname, 'service-account.json');
try {
  const serviceAccount = require(serviceAccountPath);
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: 'actechs-d415e',
    });
  }
} catch {
  console.error('❌  Missing service-account.json – see script header for instructions.');
  process.exit(1);
}

const db = admin.firestore();
const ts = admin.firestore.Timestamp;

// ── Helpers ────────────────────────────────────────────────────────────────────

/** Return a Timestamp for N days ago from now. */
const daysAgo = (n) => ts.fromDate(new Date(Date.now() - n * 86_400_000));

/** Random integer in [min, max]. */
const rand = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

/** Pick a random element from an array. */
const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];

/** Batch-write up to 500 documents. */
async function batchWrite(collection, docs) {
  const batches = [];
  const BATCH_SIZE = 500; // Firestore maximum operations per batch
  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    docs.slice(i, i + BATCH_SIZE).forEach(({ id, data }) => {
      const ref = id ? db.collection(collection).doc(id) : db.collection(collection).doc();
      batch.set(ref, data, { merge: true });
    });
    batches.push(batch.commit());
  }
  await Promise.all(batches);
  console.log(`  ✅  Wrote ${docs.length} docs → ${collection}`);
}

/** Delete all documents in a collection (top-level only, small collections). */
async function clearCollection(collection) {
  const snap = await db.collection(collection).get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
  console.log(`  🗑   Cleared ${snap.size} docs from ${collection}`);
}

// ── Lookup existing users ──────────────────────────────────────────────────────

async function loadUsers() {
  const snap = await db.collection('users').get();
  const admins = [];
  const techs = [];
  snap.forEach((d) => {
    const u = { id: d.id, ...d.data() };
    if (u.role === 'admin') admins.push(u);
    else techs.push(u);
  });
  if (!techs.length) {
    console.error('❌  No technician users found. Run setup_users.js first.');
    process.exit(1);
  }
  return { admins, techs };
}

// ── Seed data definitions ──────────────────────────────────────────────────────

const COMPANY_ROWS = [
  { name: 'Al-Noor Trading Co.', invoicePrefix: 'ANT', isActive: true },
  { name: 'Gulf Cool Systems LLC', invoicePrefix: 'GCS', isActive: true },
  { name: 'Saudi Comfort Group', invoicePrefix: 'SCG', isActive: true },
  { name: 'Riyadh Ice & Air', invoicePrefix: 'RIA', isActive: false },
];

const AC_TYPES = [
  'Split AC',
  'Window AC',
  'Freestanding AC',
  'Cassette AC',
  'Uninstallation (Old AC)',
  'Uninstallation Split',
  'Uninstallation Window',
  'Uninstallation Freestanding',
];

const CLIENT_NAMES = [
  'Abdullah Bin Saad',
  'Faisal Al-Harbi',
  'Mohammed Al-Otaibi',
  'Khalid Hassan',
  'Saeed Al-Qahtani',
  'Nasser Al-Dosari',
  'Ibrahim Al-Mutairi',
  'Yousuf Bin Rashid',
  'عمر بن خالد',
  'محمد علي',
  'احمد فهد',
  'فیصل خان',
  'محمد نعیم',
  'احمد رضا',
];

const EXPENSE_CATEGORIES = [
  'Food', 'Petrol', 'Pipes', 'Tools', 'Tape',
  'Insulation', 'Gas', 'Other Consumables', 'Other',
];

const HOME_CATEGORIES = [
  'Bread/Roti', 'Meat', 'Tea', 'Sugar', 'Vegetables',
  'Cooking Oil', 'Milk', 'Other Groceries',
];

const EARNING_CATEGORIES = [
  'Installed Bracket', 'Installed Extra Pipe', 'Old AC Removal',
  'Old AC Installation', 'Sold Old AC', 'Sold Scrap', 'Other',
];

// ── Build seed documents ───────────────────────────────────────────────────────

async function buildCompanies() {
  return COMPANY_ROWS.map((c, i) => ({
    id: `company_${i + 1}`,
    data: { ...c, createdAt: daysAgo(rand(30, 180)) },
  }));
}

async function buildJobs(techs, adminUser, companyIds) {
  const statuses = ['pending', 'approved', 'approved', 'approved', 'rejected'];
  const docs = [];

  for (let i = 0; i < 25; i++) {
    const tech = pick(techs);
    const status = pick(statuses);
    const dayOffset = rand(0, 60);
    const companyId = pick(companyIds);
    const companyRow = COMPANY_ROWS[companyIds.indexOf(companyId)] ?? COMPANY_ROWS[0];
    const invoiceNum = `${companyRow.invoicePrefix}-${String(1000 + i).padStart(4, '0')}`;

    const splitQty = rand(0, 4);
    const windowQty = rand(0, 3);
    const freestandingQty = rand(0, 3);
    const cassetteQty = rand(0, 2);
    const uninstallOldQty = rand(0, 2);
    const uninstallSplitQty = rand(0, 3);
    const uninstallWindowQty = rand(0, 2);
    const uninstallFreestandingQty = rand(0, 2);

    const acUnits = [];
    if (splitQty > 0) acUnits.push({ type: 'Split AC', quantity: splitQty });
    if (windowQty > 0) acUnits.push({ type: 'Window AC', quantity: windowQty });
    if (freestandingQty > 0) {
      acUnits.push({ type: 'Freestanding AC', quantity: freestandingQty });
    }
    if (cassetteQty > 0) acUnits.push({ type: 'Cassette AC', quantity: cassetteQty });
    if (uninstallOldQty > 0) {
      acUnits.push({ type: 'Uninstallation (Old AC)', quantity: uninstallOldQty });
    }
    if (uninstallSplitQty > 0) {
      acUnits.push({ type: 'Uninstallation Split', quantity: uninstallSplitQty });
    }
    if (uninstallWindowQty > 0) {
      acUnits.push({ type: 'Uninstallation Window', quantity: uninstallWindowQty });
    }
    if (uninstallFreestandingQty > 0) {
      acUnits.push({ type: 'Uninstallation Freestanding', quantity: uninstallFreestandingQty });
    }
    if (!acUnits.length) {
      acUnits.push({ type: 'Split AC', quantity: 1 });
    }

    const bracketBase = splitQty + freestandingQty;
    const bracketCount = Math.max(0, bracketBase + rand(-1, 1));
    const deliveryAmount = Math.random() > 0.45 ? rand(20, 150) : 0;
    const deliveryNote = deliveryAmount > 0
      ? pick(['remote location', 'roof access', 'cash paid by customer', 'urgent transport'])
      : '';

    const charges = {
      acBracket: bracketCount > 0,
      bracketCount,
      bracketAmount: 0,
      deliveryCharge: deliveryAmount > 0,
      deliveryAmount,
      deliveryNote,
    };

    docs.push({
      data: {
        techId: tech.id,
        techName: tech.name,
        companyId,
        companyName: companyRow.name,
        invoiceNumber: invoiceNum,
        clientName: pick(CLIENT_NAMES),
        clientContact: `+966 5${rand(10, 99)} ${rand(100, 999)} ${rand(1000, 9999)}`,
        acUnits,
        status,
        expenses: rand(0, 300),
        expenseNote: Math.random() > 0.5 ? pick(['petrol + tools', 'client requested duct fix', 'extra pipe work']) : '',
        adminNote: status === 'rejected' ? 'Incomplete information' : status === 'approved' ? 'Verified OK' : '',
        approvedBy: status !== 'pending' && adminUser ? adminUser.name : '',
        charges,
        date: daysAgo(dayOffset),
        submittedAt: daysAgo(dayOffset),
        reviewedAt: status !== 'pending' ? daysAgo(dayOffset - 1) : null,
      },
    });
  }
  return docs;
}

async function buildExpenses(techs) {
  const docs = [];
  for (const tech of techs) {
    // 15 work expenses spread over last 30 days
    for (let i = 0; i < 15; i++) {
      docs.push({
        data: {
          techId: tech.id,
          techName: tech.name,
          category: pick(EXPENSE_CATEGORIES),
          amount: rand(20, 500),
          note: Math.random() > 0.6 ? 'daily supplies' : '',
          expenseType: 'work',
          date: daysAgo(rand(0, 30)),
          createdAt: daysAgo(rand(0, 30)),
        },
      });
    }
    // 10 home expenses
    for (let i = 0; i < 10; i++) {
      docs.push({
        data: {
          techId: tech.id,
          techName: tech.name,
          category: pick(HOME_CATEGORIES),
          amount: rand(10, 200),
          note: '',
          expenseType: 'home',
          date: daysAgo(rand(0, 30)),
          createdAt: daysAgo(rand(0, 30)),
        },
      });
    }
  }
  return docs;
}

async function buildEarnings(techs) {
  const docs = [];
  for (const tech of techs) {
    for (let i = 0; i < 12; i++) {
      docs.push({
        data: {
          techId: tech.id,
          techName: tech.name,
          category: pick(EARNING_CATEGORIES),
          amount: rand(100, 1500),
          note: Math.random() > 0.7 ? 'cash payment' : '',
          date: daysAgo(rand(0, 30)),
          createdAt: daysAgo(rand(0, 30)),
        },
      });
    }
  }
  return docs;
}

// ── Main ───────────────────────────────────────────────────────────────────────

async function main() {
  const shouldClear = process.argv.includes('--clear');
  console.log('\n🌱  AC Techs — Seed Data Script');
  console.log('─'.repeat(44));

  const { admins, techs } = await loadUsers();
  const adminUser = admins[0] ?? null;
  console.log(`  👤  Found ${techs.length} technician(s), ${admins.length} admin(s)`);

  if (shouldClear) {
    console.log('\n🗑   Clearing existing data…');
    await Promise.all([
      clearCollection('companies'),
      clearCollection('jobs'),
      clearCollection('expenses'),
      clearCollection('earnings'),
    ]);
  }

  // ── Companies ──
  console.log('\n🏢  Seeding companies…');
  const companyDocs = await buildCompanies();
  await batchWrite('companies', companyDocs);
  const companyIds = companyDocs.map((d) => d.id);

  // ── Jobs ──
  console.log('\n📋  Seeding jobs…');
  const jobDocs = await buildJobs(techs, adminUser, companyIds);
  await batchWrite('jobs', jobDocs);

  // ── Expenses ──
  console.log('\n💸  Seeding expenses…');
  const expenseDocs = await buildExpenses(techs);
  await batchWrite('expenses', expenseDocs);

  // ── Earnings ──
  console.log('\n💰  Seeding earnings…');
  const earningDocs = await buildEarnings(techs);
  await batchWrite('earnings', earningDocs);

  console.log('\n✅  Seed complete!');
  console.log(`    Companies : ${companyDocs.length}`);
  console.log(`    Jobs      : ${jobDocs.length}`);
  console.log(`    Expenses  : ${expenseDocs.length}`);
  console.log(`    Earnings  : ${earningDocs.length}`);
  console.log('\n    Open the app → export PDF to verify report layouts.\n');
  process.exit(0);
}

main().catch((e) => {
  console.error('❌  Seed failed:', e.message);
  process.exit(1);
});

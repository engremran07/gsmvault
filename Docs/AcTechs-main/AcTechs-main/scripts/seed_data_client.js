const { initializeApp } = require('firebase/app');
const {
  getAuth,
  signInWithEmailAndPassword,
} = require('firebase/auth');
const {
  getFirestore,
  collection,
  doc,
  getDocs,
  writeBatch,
  query,
  where,
  Timestamp,
} = require('firebase/firestore');
const { getFirebaseWebConfig, requireEnv } = require('./firebase_client_env');

const app = initializeApp(getFirebaseWebConfig());
const auth = getAuth(app);
const db = getFirestore(app);

const ADMIN_EMAIL = requireEnv('ACTECHS_ADMIN_EMAIL');
const ADMIN_PASSWORD = requireEnv('ACTECHS_ADMIN_PASSWORD');

const DAY_MS = 24 * 60 * 60 * 1000;
const daysAgo = (n) => Timestamp.fromDate(new Date(Date.now() - n * DAY_MS));
const rand = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];

const companies = [
  { id: 'company_1', name: 'Al Amoudi', invoicePrefix: 'AMD', isActive: true },
  { id: 'company_2', name: 'Gulf Cooling', invoicePrefix: 'GCF', isActive: true },
  { id: 'company_3', name: 'شركة الراحة', invoicePrefix: 'RHA', isActive: true },
  { id: 'company_4', name: 'اکمل ٹریڈرز', invoicePrefix: 'AKM', isActive: true },
];

const clientNames = [
  'Abdullah Bin Saad',
  'Faisal Al-Harbi',
  'Mohammed Al-Otaibi',
  'عمر بن خالد',
  'محمد علي',
  'فیصل خان',
  'احمد رضا',
];

const earningCats = [
  'Installed Bracket',
  'Installed Extra Pipe',
  'Old AC Removal',
  'Old AC Installation',
  'Sold Old AC',
  'Sold Scrap',
  'Other',
];

const workCats = [
  'Food',
  'Petrol',
  'Pipes',
  'Tools',
  'Tape',
  'Insulation',
  'Gas',
  'Other Consumables',
  'Other',
];

const homeCats = [
  'Bread/Roti',
  'Meat',
  'Tea',
  'Sugar',
  'Vegetables',
  'Cooking Oil',
  'Milk',
  'Other Groceries',
];

async function clearCollection(name) {
  const snap = await getDocs(collection(db, name));
  if (snap.empty) return;
  let batch = writeBatch(db);
  let count = 0;
  for (const d of snap.docs) {
    batch.delete(d.ref);
    count++;
    if (count % 450 === 0) {
      await batch.commit();
      batch = writeBatch(db);
    }
  }
  await batch.commit();
  console.log(`Cleared ${count} docs from ${name}`);
}

function buildJob(tech, idx) {
  const company = pick(companies);
  const splitQty = rand(0, 4);
  const windowQty = rand(0, 3);
  const freeQty = rand(0, 3);
  const uninstallOldQty = rand(0, 2);
  const uninstallSplitQty = rand(0, 3);
  const uninstallWindowQty = rand(0, 2);
  const uninstallFreeQty = rand(0, 2);

  const acUnits = [];
  if (splitQty > 0) acUnits.push({ type: 'Split AC', quantity: splitQty });
  if (windowQty > 0) acUnits.push({ type: 'Window AC', quantity: windowQty });
  if (freeQty > 0) acUnits.push({ type: 'Freestanding AC', quantity: freeQty });
  if (uninstallOldQty > 0) {
    acUnits.push({ type: 'Uninstallation (Old AC)', quantity: uninstallOldQty });
  }
  if (uninstallSplitQty > 0) {
    acUnits.push({ type: 'Uninstallation Split', quantity: uninstallSplitQty });
  }
  if (uninstallWindowQty > 0) {
    acUnits.push({ type: 'Uninstallation Window', quantity: uninstallWindowQty });
  }
  if (uninstallFreeQty > 0) {
    acUnits.push({ type: 'Uninstallation Freestanding', quantity: uninstallFreeQty });
  }
  if (!acUnits.length) acUnits.push({ type: 'Split AC', quantity: 1 });

  const bracketCount = Math.max(0, splitQty + freeQty + rand(-1, 1));
  const deliveryAmount = rand(0, 1) === 0 ? 0 : rand(20, 180);
  const status = pick(['pending', 'approved', 'approved', 'rejected']);
  const dayOffset = rand(0, 45);

  return {
    techId: tech.id,
    techName: tech.name,
    companyId: company.id,
    companyName: company.name,
    invoiceNumber: `${company.invoicePrefix}-${String(2401000000 + idx)}`,
    clientName: pick(clientNames),
    clientContact: `5${rand(10, 99)}${rand(1000000, 9999999)}`,
    acUnits,
    status,
    expenses: rand(0, 400),
    expenseNote: pick([
      '',
      'petrol + tools',
      'extra pipe work',
      'موقع بعيد',
      'اضافی پائپ ورک',
    ]),
    adminNote: status === 'rejected' ? pick(['Incomplete info', 'Need correct invoice']) : '',
    approvedBy: status === 'approved' ? 'Admin User' : '',
    importMeta: {
      source: 'seed_data_client',
      localeTag: pick(['en', 'ur', 'ar']),
    },
    charges: {
      acBracket: bracketCount > 0,
      bracketCount,
      bracketAmount: 0,
      deliveryCharge: deliveryAmount > 0,
      deliveryAmount,
      deliveryNote: deliveryAmount > 0 ? pick(['remote location', 'roof access', 'cash paid by customer']) : '',
    },
    date: daysAgo(dayOffset),
    submittedAt: daysAgo(dayOffset),
    reviewedAt: status === 'pending' ? null : daysAgo(Math.max(0, dayOffset - 1)),
  };
}

async function seed() {
  await signInWithEmailAndPassword(auth, ADMIN_EMAIL, ADMIN_PASSWORD);
  console.log(`Signed in as ${ADMIN_EMAIL}`);

  const usersSnap = await getDocs(query(collection(db, 'users'), where('role', '==', 'technician')));
  const techs = usersSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
  if (!techs.length) {
    throw new Error('No technician users found in users collection.');
  }

  await Promise.all([
    clearCollection('companies'),
    clearCollection('jobs'),
    clearCollection('expenses'),
    clearCollection('earnings'),
  ]);

  let batch = writeBatch(db);
  let opCount = 0;
  const commitIfNeeded = async () => {
    if (opCount >= 420) {
      await batch.commit();
      batch = writeBatch(db);
      opCount = 0;
    }
  };

  for (const company of companies) {
    batch.set(doc(db, 'companies', company.id), {
      ...company,
      createdAt: daysAgo(rand(10, 120)),
    }, { merge: true });
    opCount++;
    await commitIfNeeded();
  }

  let jobIndex = 1;
  for (const tech of techs) {
    // Ensure language coverage in user docs for visual tests.
    const forcedLang = tech.name?.toString().toLowerCase().includes('omar')
      ? 'ar'
      : tech.name?.toString().toLowerCase().includes('ahmad')
      ? 'ur'
      : 'en';
    batch.set(doc(db, 'users', tech.id), { language: forcedLang }, { merge: true });
    opCount++;

    for (let i = 0; i < 22; i++) {
      batch.set(doc(collection(db, 'jobs')), buildJob(tech, jobIndex++));
      opCount++;
      await commitIfNeeded();
    }

    for (let i = 0; i < 22; i++) {
      batch.set(doc(collection(db, 'expenses')), {
        techId: tech.id,
        techName: tech.name,
        category: pick(workCats),
        amount: rand(20, 600),
        note: pick(['', 'daily supplies', 'diesel', 'سروس اخراجات']),
        expenseType: 'work',
        date: daysAgo(rand(0, 35)),
        createdAt: daysAgo(rand(0, 35)),
      });
      opCount++;
      await commitIfNeeded();
    }

    for (let i = 0; i < 16; i++) {
      batch.set(doc(collection(db, 'expenses')), {
        techId: tech.id,
        techName: tech.name,
        category: pick(homeCats),
        amount: rand(10, 250),
        note: pick(['', 'family', 'گھر']),
        expenseType: 'home',
        date: daysAgo(rand(0, 35)),
        createdAt: daysAgo(rand(0, 35)),
      });
      opCount++;
      await commitIfNeeded();
    }

    for (let i = 0; i < 20; i++) {
      batch.set(doc(collection(db, 'earnings')), {
        techId: tech.id,
        techName: tech.name,
        category: pick(earningCats),
        amount: rand(80, 2200),
        note: pick(['', 'cash payment', 'customer transfer', 'نقد']),
        date: daysAgo(rand(0, 35)),
        createdAt: daysAgo(rand(0, 35)),
      });
      opCount++;
      await commitIfNeeded();
    }
  }

  await batch.commit();
  console.log('Seed complete: companies, jobs, expenses, earnings, and user languages updated.');
}

seed().catch((err) => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});

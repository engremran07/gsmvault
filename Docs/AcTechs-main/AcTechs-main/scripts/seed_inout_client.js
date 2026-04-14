const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
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

const ADMIN_EMAIL = requireEnv('ACTECHS_ADMIN_EMAIL');
const ADMIN_PASSWORD = requireEnv('ACTECHS_ADMIN_PASSWORD');

const app = initializeApp(getFirebaseWebConfig());
const auth = getAuth(app);
const db = getFirestore(app);

const DAY_MS = 24 * 60 * 60 * 1000;
const daysAgo = (n) => Timestamp.fromDate(new Date(Date.now() - n * DAY_MS));
const rand = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];

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
  'Rice',
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
    if (count % 420 === 0) {
      await batch.commit();
      batch = writeBatch(db);
    }
  }
  await batch.commit();
  console.log(`Cleared ${count} docs from ${name}`);
}

async function main() {
  await signInWithEmailAndPassword(auth, ADMIN_EMAIL, ADMIN_PASSWORD);
  console.log(`Signed in as ${ADMIN_EMAIL}`);

  const usersSnap = await getDocs(query(collection(db, 'users'), where('role', '==', 'technician')));
  const techs = usersSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
  if (!techs.length) {
    throw new Error('No technician users found.');
  }

  await Promise.all([clearCollection('earnings'), clearCollection('expenses')]);

  const langs = ['en', 'ur', 'ar'];
  let batch = writeBatch(db);
  let opCount = 0;
  let languageIndex = 0;

  const flush = async () => {
    if (opCount >= 420) {
      await batch.commit();
      batch = writeBatch(db);
      opCount = 0;
    }
  };

  for (const tech of techs) {
    batch.set(doc(db, 'users', tech.id), { language: langs[languageIndex % langs.length] }, { merge: true });
    languageIndex++;
    opCount++;
    await flush();

    // 28 earnings + 32 expenses to cover rich report scenarios.
    for (let i = 0; i < 28; i++) {
      batch.set(doc(collection(db, 'earnings')), {
        techId: tech.id,
        techName: tech.name,
        category: pick(earningCats),
        amount: rand(100, 2200),
        note: pick(['', 'cash payment', 'bank transfer', 'نقد', 'آج کی سیل']),
        date: daysAgo(rand(0, 40)),
        createdAt: daysAgo(rand(0, 40)),
      });
      opCount++;
      await flush();
    }

    for (let i = 0; i < 20; i++) {
      batch.set(doc(collection(db, 'expenses')), {
        techId: tech.id,
        techName: tech.name,
        category: pick(workCats),
        amount: rand(20, 700),
        note: pick(['', 'daily supplies', 'diesel', 'موقع خرچہ', 'سفر']),
        expenseType: 'work',
        date: daysAgo(rand(0, 40)),
        createdAt: daysAgo(rand(0, 40)),
      });
      opCount++;
      await flush();
    }

    for (let i = 0; i < 12; i++) {
      batch.set(doc(collection(db, 'expenses')), {
        techId: tech.id,
        techName: tech.name,
        category: pick(homeCats),
        amount: rand(10, 250),
        note: pick(['', 'family', 'گھر']),
        expenseType: 'home',
        date: daysAgo(rand(0, 40)),
        createdAt: daysAgo(rand(0, 40)),
      });
      opCount++;
      await flush();
    }
  }

  await batch.commit();
  console.log('In/Out seed complete. Wrote multilingual earnings/expenses only.');
}

main().catch((err) => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});

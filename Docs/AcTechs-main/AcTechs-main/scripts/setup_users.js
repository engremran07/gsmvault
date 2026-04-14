/**
 * AC Techs — Firebase Setup Script
 * Creates admin and technician users in Firebase Auth + Firestore.
 * 
 * Prerequisites:
 *   1. Enable Email/Password auth in Firebase Console:
 *      https://console.firebase.google.com/project/actechs-d415e/authentication/providers
 *   2. Generate a service account key:
 *      https://console.firebase.google.com/project/actechs-d415e/settings/serviceaccounts/adminsdk
 *      → Generate new private key → Save as scripts/service-account.json
 * 
 * Usage:
 *   cd scripts
 *   node setup_users.js
 */

const admin = require('firebase-admin');
const path = require('path');

const serviceAccountPath = path.join(__dirname, 'service-account.json');

try {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'actechs-d415e',
  });
} catch (e) {
  console.error('❌ Missing service-account.json!');
  console.error('   Download from: https://console.firebase.google.com/project/actechs-d415e/settings/serviceaccounts/adminsdk');
  console.error('   Save as: scripts/service-account.json');
  process.exit(1);
}

const auth = admin.auth();
const db = admin.firestore();

const users = [
  {
    email: 'admin@actechs.pk',
    password: 'Admin@123',
    displayName: 'Admin User',
    role: 'admin',
    language: 'en',
  },
  {
    email: 'tech1@actechs.pk',
    password: 'Tech1@123',
    displayName: 'Ahmad Khan',
    role: 'technician',
    language: 'ur',
  },
  {
    email: 'tech2@actechs.pk',
    password: 'Tech2@123',
    displayName: 'Ali Raza',
    role: 'technician',
    language: 'en',
  },
  {
    email: 'tech3@actechs.pk',
    password: 'Tech3@123',
    displayName: 'Omar Al-Farouq',
    role: 'technician',
    language: 'ar',
  },
];

async function createUser(userData) {
  try {
    // Check if user already exists
    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(userData.email);
      console.log(`  ⚡ User ${userData.email} already exists (${userRecord.uid})`);
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        userRecord = await auth.createUser({
          email: userData.email,
          password: userData.password,
          displayName: userData.displayName,
          emailVerified: true,
        });
        console.log(`  ✅ Created auth user: ${userData.email} (${userRecord.uid})`);
      } else {
        throw e;
      }
    }

    // Create/update Firestore user document
    const userDoc = {
      uid: userRecord.uid,
      name: userData.displayName,
      email: userData.email,
      role: userData.role,
      isActive: true,
      language: userData.language,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('users').doc(userRecord.uid).set(userDoc, { merge: true });
    console.log(`  ✅ Firestore doc created for ${userData.email} (role: ${userData.role})`);

    return userRecord;
  } catch (error) {
    console.error(`  ❌ Failed for ${userData.email}:`, error.message);
    return null;
  }
}

async function main() {
  console.log('\n🚀 AC Techs — Firebase User Setup\n');
  console.log('Creating users...\n');

  for (const user of users) {
    console.log(`📧 ${user.email} (${user.role}):`);
    await createUser(user);
    console.log('');
  }

  console.log('✅ Setup complete!\n');
  console.log('Login credentials:');
  console.log('  Admin:  admin@actechs.pk / Admin@123');
  console.log('  Tech 1: tech1@actechs.pk / Tech1@123');
  console.log('  Tech 2: tech2@actechs.pk / Tech2@123');
  console.log('  Tech 3: tech3@actechs.pk / Tech3@123');
  console.log('');

  process.exit(0);
}

main().catch(console.error);

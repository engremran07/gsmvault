const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.join(__dirname, '.env') });

function requireEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(
      `Missing required environment variable ${name}. Copy scripts/.env.example to scripts/.env and fill in the real values.`,
    );
  }
  return value;
}

function getFirebaseWebConfig() {
  return {
    apiKey: requireEnv('ACTECHS_FIREBASE_API_KEY'),
    authDomain: requireEnv('ACTECHS_FIREBASE_AUTH_DOMAIN'),
    projectId: requireEnv('ACTECHS_FIREBASE_PROJECT_ID'),
    storageBucket: requireEnv('ACTECHS_FIREBASE_STORAGE_BUCKET'),
    messagingSenderId: requireEnv('ACTECHS_FIREBASE_MESSAGING_SENDER_ID'),
    appId: requireEnv('ACTECHS_FIREBASE_APP_ID'),
  };
}

module.exports = {
  getFirebaseWebConfig,
  requireEnv,
};
const admin = require('firebase-admin');
const dotenv = require('dotenv');

dotenv.config();

/**
 * PRODUCTION-GRADE FIREBASE INITIALIZATION
 * 1. Environment variable support (FIREBASE_SERVICE_ACCOUNT)
 * 2. Singleton pattern to prevent multiple initialization errors
 * 3. Local fallback for development
 */

let firebaseApp;

if (!admin.apps.length) {
  // PRODUCTION: ENV BASED (Safest for VPS/Cloud)
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('Firebase Admin initialized via Environment Variable');
    } catch (error) {
      console.error('CRITICAL: Failed to parse FIREBASE_SERVICE_ACCOUNT env var');
      process.exit(1);
    }
  }
  // LOCAL DEVELOPMENT FALLBACK
  else {
    try {
      const serviceAccount = require('../serviceAccountKey.json');
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('Firebase Admin initialized via local serviceAccountKey.json');
    } catch (error) {
      console.warn('WARNING: Missing FIREBASE_SERVICE_ACCOUNT and serviceAccountKey.json');
      console.warn('Backend will fail on authenticated requests.');
    }
  }
} else {
  firebaseApp = admin.app();
}

const db = admin.firestore();
const auth = admin.auth();

module.exports = {
  admin,
  db,
  auth,
  firebaseApp,
};

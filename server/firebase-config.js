const admin = require('firebase-admin');
const dotenv = require('dotenv');

dotenv.config();

// You need to download your service account key from Firebase Console
// Project Settings > Service Accounts > Generate new private key
// Then save it as serviceAccountKey.json in the server directory
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  // databaseURL: "https://your-project-id.firebaseio.com" // If using Realtime Database
});

const db = admin.firestore();
const auth = admin.auth();

module.exports = { admin, db, auth };

const { db } = require('../config/firebase-config');

async function inspectProperty() {
  const propertyId = 'lZobmZj74sp2chajMAWA';
  const doc = await db.collection('properties').doc(propertyId).get();
  if (doc.exists) {
    console.log(`Property [${propertyId}]:`);
    console.log(JSON.stringify(doc.data(), null, 2));
  } else {
    console.log(`Property [${propertyId}] not found.`);
  }
}

inspectProperty().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});

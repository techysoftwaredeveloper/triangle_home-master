const { db } = require('../config/firebase-config');

async function inspectImages() {
  const propertiesSnap = await db.collection('properties').get();
  propertiesSnap.forEach(doc => {
    const data = doc.data();
    console.log(`Property [${doc.id}] ${data.name || data.title || 'Unnamed'}:`);
    console.log(`  images:`, data.images);
    console.log(`  image_urls:`, data.image_urls);
    console.log(`  image:`, data.image);
  });
}

inspectImages().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});

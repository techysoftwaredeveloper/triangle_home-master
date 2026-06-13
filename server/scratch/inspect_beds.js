const { db } = require('../config/firebase-config');

async function inspect() {
  const propertyId = 'lZobmZj74sp2chajMAWA';
  console.log(`Inspecting beds for property: ${propertyId}`);

  // Fetch flat beds
  const flatBedsSnap = await db.collection('beds')
      .where('propertyId', '==', propertyId)
      .get();
  
  console.log(`\nFlat beds count: ${flatBedsSnap.size}`);
  flatBedsSnap.forEach(doc => {
    console.log(`Bed ID: ${doc.id}`);
    console.log(`  Data:`, doc.data());
  });

  // Fetch property subcollection beds
  const propBedsSnap = await db.collection('properties')
      .doc(propertyId)
      .collection('beds')
      .get();
  
  console.log(`\nProperty subcollection beds count: ${propBedsSnap.size}`);
  propBedsSnap.forEach(doc => {
    console.log(`Bed ID: ${doc.id}`);
    console.log(`  Data:`, doc.data());
  });

  // Fetch room nested subcollection beds
  const roomsSnap = await db.collection('properties')
      .doc(propertyId)
      .collection('rooms')
      .get();
  
  console.log(`\nRooms count: ${roomsSnap.size}`);
  for (const roomDoc of roomsSnap.docs) {
    console.log(`Room: ${roomDoc.id} (${roomDoc.data().roomNumber})`);
    const nestedBedsSnap = await roomDoc.ref.collection('beds').get();
    console.log(`  Nested beds count: ${nestedBedsSnap.size}`);
    nestedBedsSnap.forEach(doc => {
      console.log(`  Bed ID: ${doc.id}`);
      console.log(`    Data:`, doc.data());
    });
  }
}

inspect().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});

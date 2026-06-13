const { db } = require('../config/firebase-config');

async function inspectRooms() {
  const propertyId = 'lZobmZj74sp2chajMAWA';
  console.log(`Inspecting rooms for property: ${propertyId}`);

  // Fetch flat rooms
  const flatRoomsSnap = await db.collection('rooms')
      .where('propertyId', '==', propertyId)
      .get();
  
  console.log(`\nFlat rooms count: ${flatRoomsSnap.size}`);
  flatRoomsSnap.forEach(doc => {
    console.log(`Room ID: ${doc.id}`);
    console.log(`  Data:`, doc.data());
  });

  // Fetch nested rooms
  const propRoomsSnap = await db.collection('properties')
      .doc(propertyId)
      .collection('rooms')
      .get();
  
  console.log(`\nNested rooms count: ${propRoomsSnap.size}`);
  propRoomsSnap.forEach(doc => {
    console.log(`Room ID: ${doc.id}`);
    console.log(`  Data:`, doc.data());
  });
}

inspectRooms().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});

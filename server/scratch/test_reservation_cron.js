const { db, admin } = require('../config/firebase-config');
const { performReconciliation } = require('../controllers/propertyController');

async function runTest() {
  const propertyId = 'lZobmZj74sp2chajMAWA';
  const roomId = 'ywLS63qg1htmulBWpvSC'; // Single room
  const bedId = 'RiD38CKNStVlv4iaXG9P'; // F2-R1-B1
  const userId = 'test_user_123';

  console.log('--- Mocking Expired Bed Reservation ---');

  // 1. Mark bed as reserved in all 3 collections
  const expiryPast = new Date(Date.now() - 3600 * 1000); // 1 hour ago
  const expiryTimestamp = admin.firestore.Timestamp.fromDate(expiryPast);

  const flatBedRef = db.collection('beds').doc(bedId);
  const propBedRef = db.collection('properties').doc(propertyId).collection('beds').doc(bedId);
  const roomBedRef = db.collection('properties').doc(propertyId).collection('rooms').doc(roomId).collection('beds').doc(bedId);

  const mockReserved = {
    status: 'reserved',
    reservedBy: userId,
    reservationExpiresAt: expiryTimestamp,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };

  const batch = db.batch();
  batch.update(flatBedRef, mockReserved);
  batch.update(propBedRef, mockReserved);
  batch.update(roomBedRef, mockReserved);

  // 2. Add active but expired reservation document
  const reservationRef = db.collection('bed_reservations').doc();
  batch.set(reservationRef, {
    propertyId,
    roomId,
    bedId,
    userId,
    status: 'active',
    expiresAt: expiryTimestamp,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  await batch.commit();
  console.log(`Created expired reservation: ${reservationRef.id}`);

  // Reconcile once to set stats with the reserved bed
  console.log('Reconciling initial reserved state...');
  let stats = await performReconciliation(propertyId);
  console.log(`Initial Reconciled Stats -> Available: ${stats.availableBeds}, Reserved: ${stats.reservedBeds}`);

  // 3. Run Cron Cleanup Logic
  console.log('\n--- Running Expired Reservation Cron Logic ---');
  const now = admin.firestore.Timestamp.now();
  const expiredReservationsSnapshot = await db.collection('bed_reservations')
      .where('expiresAt', '<', now)
      .get();

  const activeExpiredDocs = [];
  expiredReservationsSnapshot.forEach(doc => {
      if (doc.data().status === 'active') {
          activeExpiredDocs.push(doc);
      }
  });

  console.log(`Cron found ${activeExpiredDocs.length} expired reservations.`);

  const propertiesToReconcile = new Set();
  
  for (const doc of activeExpiredDocs) {
      const data = doc.data();
      const { propertyId: propId, roomId: rmId, bedId: bdId } = data;

      console.log(`Processing expiration for reservation: ${doc.id}`);

      await db.runTransaction(async (transaction) => {
          const fBedRef = db.collection('beds').doc(bdId);
          const pBedRef = db.collection('properties').doc(propId).collection('beds').doc(bdId);
          const rBedRef = db.collection('properties').doc(propId).collection('rooms').doc(rmId).collection('beds').doc(bdId);
          const resRef = doc.ref;

          const bedUpdates = {
              status: 'available',
              reservedBy: null,
              reservationExpiresAt: null,
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
          };

          transaction.update(fBedRef, bedUpdates);
          transaction.update(pBedRef, bedUpdates);
          transaction.update(rBedRef, bedUpdates);
          transaction.update(resRef, {
              status: 'expired',
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
      });

      propertiesToReconcile.add(propId);
  }

  // 4. Trigger reconciliation for all affected properties
  for (const propId of propertiesToReconcile) {
      console.log(`Triggering reconciliation for property: ${propId}`);
      stats = await performReconciliation(propId);
      console.log(`Post-Cleanup Reconciled Stats -> Available: ${stats.availableBeds}, Reserved: ${stats.reservedBeds}`);
  }

  // 5. Verify Bed statuses are available in all 3 structures
  console.log('\n--- Verifying Database Statuses ---');
  const flatDoc = await flatBedRef.get();
  const propDoc = await propBedRef.get();
  const roomDoc = await roomBedRef.get();
  const resDoc = await reservationRef.get();

  console.log(`Flat Bed Status:  ${flatDoc.data().status}`);
  console.log(`Prop Bed Status:  ${propDoc.data().status}`);
  console.log(`Room Bed Status:  ${roomDoc.data().status}`);
  console.log(`Reservation:      ${resDoc.data().status}`);

  const success = flatDoc.data().status === 'available' &&
                  propDoc.data().status === 'available' &&
                  roomDoc.data().status === 'available' &&
                  resDoc.data().status === 'expired' &&
                  stats.availableBeds === 6 &&
                  stats.reservedBeds === 0;

  if (success) {
    console.log('\n[SUCCESS] Reservation cron logic passed successfully!');
  } else {
    console.log('\n[FAILURE] Statuses or counts are incorrect.');
  }
}

runTest().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});

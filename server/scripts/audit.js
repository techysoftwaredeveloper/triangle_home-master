/**
 * Database Consistency Audit Script
 * Verifies relationships between Bookings, Beds, Payments, and Escrow.
 */
const { db } = require('../config/firebase-config');

async function runAudit() {
  console.log('--- Starting Database Consistency Audit ---');

  const results = {
    mismatchedOccupancy: [],
    orphanedEscrows: [],
    missingPayments: [],
    statusMismatches: [],
  };

  // 1. Audit Bookings ↔ Beds
  const bookingsSnap = await db.collection('bookings').where('status', 'in', ['confirmed', 'checkedIn']).get();
  for (const doc of bookingsSnap.docs) {
    const data = doc.data();
    if (data.bedId) {
      const bedDoc = await db.doc(`properties/${data.property_id}/rooms/${data.roomId}/beds/${data.bedId}`).get();
      if (!bedDoc.exists) {
        results.statusMismatches.push(`Booking ${doc.id} references non-existent bed ${data.bedId}`);
      } else {
        const bedStatus = bedDoc.data().status;
        const expectedStatus = data.status === 'checkedIn' ? 'occupied' : 'booked';
        if (bedStatus !== expectedStatus) {
           results.statusMismatches.push(`Booking ${doc.id} status is ${data.status}, but Bed ${data.bedId} status is ${bedStatus}`);
        }
      }
    }
  }

  // 2. Audit Bookings ↔ Escrow
  const escrowSnap = await db.collection('escrow').get();
  for (const doc of escrowSnap.docs) {
    const bookingId = doc.id;
    const bookingDoc = await db.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) {
      results.orphanedEscrows.push(`Escrow ${doc.id} has no corresponding booking`);
    }
  }

  // 3. Audit Property Occupancy Counters (Consistency Check)
  const propertiesSnap = await db.collection('properties').get();
  for (const propDoc of propertiesSnap.docs) {
      const data = propDoc.data();
      const cachedOccupancy = data.currentOccupancy || 0;

      // Calculate actual occupancy from beds
      let actualOccupancy = 0;
      const roomsSnap = await propDoc.ref.collection('rooms').get();
      for (const roomDoc of roomsSnap.docs) {
          const bedsSnap = await roomDoc.ref.collection('beds').where('status', 'in', ['occupied', 'booked']).get();
          actualOccupancy += bedsSnap.size;
      }

      if (cachedOccupancy !== actualOccupancy) {
          results.mismatchedOccupancy.push(`Property ${propDoc.id}: Cached=${cachedOccupancy}, Actual=${actualOccupancy}`);
      }
  }

  console.log('--- Audit Results ---');
  console.log(JSON.stringify(results, null, 2));
  return results;
}

if (require.main === module) {
  runAudit().then(() => process.exit(0)).catch(err => {
    console.error(err);
    process.exit(1);
  });
}

module.exports = runAudit;

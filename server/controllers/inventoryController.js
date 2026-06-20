const { db, admin } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');

exports.lockBed = asyncHandler(async (req, res) => {
  const { propertyId, roomId, bedId } = req.body;
  const userId = req.user.uid;

  if (!propertyId || !roomId || !bedId) {
    return res.status(400).json({ success: false, error: 'Missing required identifiers' });
  }

  await db.runTransaction(async (transaction) => {
    const flatBedRef = db.collection('beds').doc(bedId);
    const roomRef = db.collection('rooms').doc(roomId);
    const statsRef = db.collection('propertyStats').doc(propertyId);

    // Nested references for consistency with current architecture
    const propertyRef = db.collection('properties').doc(propertyId);
    const propBedRef = propertyRef.collection('beds').doc(bedId);
    const roomBedRef = propertyRef.collection('rooms').doc(roomId).collection('beds').doc(bedId);

    // 1. Check Bed Status
    const bedDoc = await transaction.get(flatBedRef);
    if (!bedDoc.exists) throw new Error('Bed not found');

    const bedData = bedDoc.data();
    if (bedData.status !== 'available') {
      throw new Error('Bed is no longer available');
    }

    const expiry = new Date(Date.now() + 15 * 60 * 1000); // 15 mins

    // 2. Update Bed Status in all locations
    const bedUpdates = {
      status: 'reserved',
      reservedBy: userId,
      reservationExpiresAt: admin.firestore.Timestamp.fromDate(expiry),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    transaction.update(flatBedRef, bedUpdates);
    transaction.update(propBedRef, bedUpdates);
    transaction.update(roomBedRef, bedUpdates);

    // 3. Create Reservation Audit
    const reservationRef = db.collection('bed_reservations').doc();
    transaction.set(reservationRef, {
      propertyId,
      roomId,
      bedId,
      userId,
      status: 'active',
      expiresAt: admin.firestore.Timestamp.fromDate(expiry),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 4. Update Counters
    transaction.update(roomRef, {
      availableBeds: admin.firestore.FieldValue.increment(-1)
    });

    transaction.set(statsRef, {
      availableBeds: admin.firestore.FieldValue.increment(-1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  res.json({ success: true, message: 'Bed locked successfully' });
});

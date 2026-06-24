const { db, admin } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Helper to update bed status across all locations
 */
async function updateBedStatusInternal(transaction, propertyId, roomId, bedId, newStatus) {
    const flatBedRef = db.collection('beds').doc(bedId);
    const propBedRef = db.collection('properties').doc(propertyId).collection('beds').doc(bedId);
    const roomBedRef = db.collection('properties').doc(propertyId).collection('rooms').doc(roomId).collection('beds').doc(bedId);

    const updates = {
        status: newStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    transaction.update(flatBedRef, updates);
    transaction.update(propBedRef, updates);
    transaction.update(roomBedRef, updates);
}

exports.updateBedStatus = asyncHandler(async (req, res) => {
    const { bedId } = req.params;
    const { status, propertyId, roomId } = req.body;

    if (!propertyId || !roomId || !status) {
        return res.status(400).json({ success: false, error: 'Missing required parameters' });
    }

    await db.runTransaction(async (transaction) => {
        const bedRef = db.collection('beds').doc(bedId);
        const bedDoc = await transaction.get(bedRef);
        if (!bedDoc.exists) throw new Error('Bed not found');

        const oldStatus = bedDoc.data().status;
        if (oldStatus === status) return;

        await updateBedStatusInternal(transaction, propertyId, roomId, bedId, status);

        // Update stats if transitioning to/from available
        const statsRef = db.collection('propertyStats').doc(propertyId);
        const roomRef = db.collection('rooms').doc(roomId);

        let availableDiff = 0;
        if (oldStatus === 'available') availableDiff = -1;
        if (status === 'available') availableDiff = 1;

        if (availableDiff !== 0) {
            transaction.update(statsRef, {
                availableBeds: admin.firestore.FieldValue.increment(availableDiff),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            transaction.update(roomRef, {
                availableBeds: admin.firestore.FieldValue.increment(availableDiff),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
    });

    res.json({ success: true, message: 'Bed status updated' });
});

exports.deleteBed = asyncHandler(async (req, res) => {
    const { bedId } = req.params;
    const { propertyId, roomId } = req.body;

    await db.runTransaction(async (transaction) => {
        const bedRef = db.collection('beds').doc(bedId);
        const bedDoc = await transaction.get(bedRef);
        if (!bedDoc.exists) throw new Error('Bed not found');

        const data = bedDoc.data();
        if (data.status === 'occupied' || data.status === 'booked') {
            throw new Error('Cannot delete occupied or booked bed');
        }

        const statsRef = db.collection('propertyStats').doc(propertyId);
        const roomRef = db.collection('rooms').doc(roomId);
        const propertyRef = db.collection('properties').doc(propertyId);

        transaction.delete(bedRef);
        transaction.delete(db.collection('properties').doc(propertyId).collection('beds').doc(bedId));
        transaction.delete(db.collection('properties').doc(propertyId).collection('rooms').doc(roomId).collection('beds').doc(bedId));

        const decr = admin.firestore.FieldValue.increment(-1);
        const updates = { totalBeds: decr, updatedAt: admin.firestore.FieldValue.serverTimestamp() };
        if (data.status === 'available') updates.availableBeds = decr;

        transaction.update(statsRef, updates);
        transaction.update(roomRef, updates);
        transaction.update(propertyRef, { totalBeds: decr, capacity: decr });
    });

    res.json({ success: true, message: 'Bed deleted' });
});

exports.updateRoomStatus = asyncHandler(async (req, res) => {
    const { roomId } = req.params;
    const { status, propertyId } = req.body;

    const bedsSnap = await db.collection('beds').where('roomId', '==', roomId).get();
    const batch = db.batch();

    bedsSnap.forEach(doc => {
        const bedId = doc.id;
        const updates = { status, updatedAt: admin.firestore.FieldValue.serverTimestamp() };
        batch.update(db.collection('beds').doc(bedId), updates);
        batch.update(db.collection('properties').doc(propertyId).collection('beds').doc(bedId), updates);
        batch.update(db.collection('properties').doc(propertyId).collection('rooms').doc(roomId).collection('beds').doc(bedId), updates);
    });

    batch.update(db.collection('rooms').doc(roomId), { status, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    batch.update(db.collection('properties').doc(propertyId).collection('rooms').doc(roomId), { status, updatedAt: admin.firestore.FieldValue.serverTimestamp() });

    await batch.commit();
    res.json({ success: true, message: 'Room status updated' });
});

exports.deleteRoom = asyncHandler(async (req, res) => {
    const { roomId } = req.params;
    const { propertyId } = req.body;

    const bedsSnap = await db.collection('beds').where('roomId', '==', roomId).get();
    let canDelete = true;
    bedsSnap.forEach(doc => {
        const s = doc.data().status;
        if (s === 'occupied' || s === 'booked') canDelete = false;
    });

    if (!canDelete) return res.status(400).json({ success: false, error: 'Room has occupied beds' });

    const batch = db.batch();
    let bedCount = 0;
    bedsSnap.forEach(doc => {
        bedCount++;
        batch.delete(doc.ref);
        batch.delete(db.collection('properties').doc(propertyId).collection('beds').doc(doc.id));
        batch.delete(db.collection('properties').doc(propertyId).collection('rooms').doc(roomId).collection('beds').doc(doc.id));
    });

    batch.delete(db.collection('rooms').doc(roomId));
    batch.delete(db.collection('properties').doc(propertyId).collection('rooms').doc(roomId));

    const decr = admin.firestore.FieldValue.increment(-bedCount);
    batch.update(db.collection('propertyStats').doc(propertyId), { totalBeds: decr, availableRooms: admin.firestore.FieldValue.increment(-1) });
    batch.update(db.collection('properties').doc(propertyId), { totalBeds: decr, capacity: decr, rooms: admin.firestore.FieldValue.increment(-1) });

    await batch.commit();
    res.json({ success: true, message: 'Room deleted' });
});

exports.updateFloorStatus = asyncHandler(async (req, res) => {
    const { floorId } = req.params;
    const { status, propertyId } = req.body;

    const roomsSnap = await db.collection('rooms').where('floorId', '==', floorId).get();
    const batch = db.batch();

    for (const roomDoc of roomsSnap.docs) {
        const roomId = roomDoc.id;
        const bedsSnap = await db.collection('beds').where('roomId', '==', roomId).get();
        bedsSnap.forEach(bedDoc => {
            const updates = { status, updatedAt: admin.firestore.FieldValue.serverTimestamp() };
            batch.update(bedDoc.ref, updates);
            batch.update(db.collection('properties').doc(propertyId).collection('beds').doc(bedDoc.id), updates);
            batch.update(db.collection('properties').doc(propertyId).collection('rooms').doc(roomId).collection('beds').doc(bedDoc.id), updates);
        });
        batch.update(roomDoc.ref, { status, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    }

    batch.update(db.collection('properties').doc(propertyId).collection('floors').doc(floorId), { status, updatedAt: admin.firestore.FieldValue.serverTimestamp() });

    await batch.commit();
    res.json({ success: true, message: 'Floor status updated' });
});

exports.deleteFloor = asyncHandler(async (req, res) => {
    const { floorId } = req.params;
    const { propertyId } = req.body;

    const roomsSnap = await db.collection('rooms').where('floorId', '==', floorId).get();
    let canDelete = true;
    let totalBedCount = 0;

    for (const roomDoc of roomsSnap.docs) {
        const bedsSnap = await db.collection('beds').where('roomId', '==', roomDoc.id).get();
        bedsSnap.forEach(bedDoc => {
            totalBedCount++;
            const s = bedDoc.data().status;
            if (s === 'occupied' || s === 'booked') canDelete = false;
        });
    }

    if (!canDelete) return res.status(400).json({ success: false, error: 'Floor has occupied beds' });

    const batch = db.batch();
    for (const roomDoc of roomsSnap.docs) {
        const roomId = roomDoc.id;
        const bedsSnap = await db.collection('beds').where('roomId', '==', roomId).get();
        bedsSnap.forEach(bedDoc => {
            batch.delete(bedDoc.ref);
            batch.delete(db.collection('properties').doc(propertyId).collection('beds').doc(bedDoc.id));
            batch.delete(db.collection('properties').doc(propertyId).collection('rooms').doc(roomId).collection('beds').doc(bedDoc.id));
        });
        batch.delete(roomDoc.ref);
        batch.delete(db.collection('properties').doc(propertyId).collection('rooms').doc(roomId));
    }

    batch.delete(db.collection('properties').doc(propertyId).collection('floors').doc(floorId));

    const decr = admin.firestore.FieldValue.increment(-totalBedCount);
    batch.update(db.collection('propertyStats').doc(propertyId), { totalBeds: decr, availableRooms: admin.firestore.FieldValue.increment(-roomsSnap.size) });
    batch.update(db.collection('properties').doc(propertyId), { totalBeds: decr, capacity: decr, rooms: admin.firestore.FieldValue.increment(-roomsSnap.size) });

    await batch.commit();
    res.json({ success: true, message: 'Floor deleted' });
});

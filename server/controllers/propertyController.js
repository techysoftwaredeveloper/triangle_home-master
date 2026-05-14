const { db } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');

// Trigger occupancy reconciliation
exports.reconcileOccupancy = asyncHandler(async (req, res) => {
    const { propertyId } = req.params;

    const propertyRef = db.collection('properties').doc(propertyId);
    const propertyDoc = await propertyRef.get();

    if (!propertyDoc.exists) {
        const error = new Error('Property not found');
        error.statusCode = 404;
        throw error;
    }

    const reportedOccupancy = propertyDoc.data().currentOccupancy || 0;

    // Count actual confirmed/checked-in bookings
    const bookingsSnapshot = await db.collection('bookings')
        .where('property_id', '==', propertyId)
        .where('status', 'in', ['confirmed', 'checkedIn'])
        .get();

    const actualOccupancy = bookingsSnapshot.size;

    if (reportedOccupancy !== actualOccupancy) {
        await propertyRef.update({
            currentOccupancy: actualOccupancy,
            updatedAt: new Date().toISOString()
        });
    }

    res.json({
        success: true,
        reported: reportedOccupancy,
        actual: actualOccupancy,
        reconciled: reportedOccupancy !== actualOccupancy
    });
});

// Create property listing
exports.createProperty = asyncHandler(async (req, res) => {
    const hosterId = req.user.uid;
    const propertyData = {
        ...req.body,
        hoster_id: hosterId,
        status: 'pending',
        rating: 0,
        reviewCount: 0,
        currentOccupancy: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    };

    const docRef = await db.collection('properties').add(propertyData);
    res.status(201).json({ success: true, id: docRef.id });
});

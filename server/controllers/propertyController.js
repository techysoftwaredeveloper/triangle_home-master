const { db, admin } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');

// Standalone core property reconciliation logic
async function performReconciliation(propertyId) {
    const propertyRef = db.collection('properties').doc(propertyId);
    const statsRef = db.collection('propertyStats').doc(propertyId);
    const propertyDoc = await propertyRef.get();

    if (!propertyDoc.exists) {
        const error = new Error('Property not found');
        error.statusCode = 404;
        throw error;
    }

    const currentData = propertyDoc.data();

    // 1. Fetch all beds for this property from all possible Firestore schemas
    const bedsMap = new Map();

    const addBedsFromSnapshot = (snapshot) => {
        snapshot.forEach(doc => {
            const data = doc.data();
            const id = doc.id || data.id || data.bedId;
            if (id) {
                bedsMap.set(id, { id, ...data });
            }
        });
    };

    // A. Flat top-level collection beds
    const flatBedsSnap = await db.collection('beds')
        .where('propertyId', '==', propertyId)
        .get();
    addBedsFromSnapshot(flatBedsSnap);

    // B. Property subcollection beds
    const propBedsSnap = await db.collection('properties')
        .doc(propertyId)
        .collection('beds')
        .get();
    addBedsFromSnapshot(propBedsSnap);

    // C. Nested room subcollection beds
    const roomsSnap = await db.collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .get();
    for (const roomDoc of roomsSnap.docs) {
        const nestedBedsSnap = await roomDoc.ref.collection('beds').get();
        addBedsFromSnapshot(nestedBedsSnap);
    }

    // D. Flat rooms subcollection beds (if any)
    const flatRoomsSnap = await db.collection('rooms')
        .where('propertyId', '==', propertyId)
        .get();
    for (const roomDoc of flatRoomsSnap.docs) {
        const nestedBedsSnap = await roomDoc.ref.collection('beds').get();
        addBedsFromSnapshot(nestedBedsSnap);
    }

    // Map rooms by ID to retrieve roomType and base pricing
    const roomsMap = new Map();
    const populateRoom = (doc) => {
        const id = doc.id;
        const data = doc.data();
        if (!roomsMap.has(id)) {
            roomsMap.set(id, {
                id,
                ...data,
                calculatedTotalBeds: 0,
                calculatedAvailableBeds: 0,
                calculatedOccupiedBeds: 0,
                calculatedReservedBeds: 0,
            });
        }
    };
    roomsSnap.forEach(populateRoom);
    flatRoomsSnap.forEach(populateRoom);

    const pricing = currentData.pricing || {};

    let totalBeds = 0;
    let occupiedBeds = 0;
    let availableBeds = 0;
    let reservedBeds = 0;

    let candidateBeds = [];
    const batch = db.batch();
    let hasUpdates = false;

    // Track room bed counts dynamically
    bedsMap.forEach((bed, id) => {
        const roomId = bed.roomId;
        if (roomId && roomsMap.has(roomId)) {
            const roomObj = roomsMap.get(roomId);
            roomObj.calculatedTotalBeds++;
            const status = (bed.status || 'available').toLowerCase();
            if (status === 'available') {
                roomObj.calculatedAvailableBeds++;
            } else if (status === 'occupied' || status === 'booked') {
                roomObj.calculatedOccupiedBeds++;
            } else if (status === 'reserved') {
                roomObj.calculatedReservedBeds++;
                }

            // NEW: Track minimum bed price for this room to sync with room baseRent
            const bedRent = parseFloat(bed.monthlyRent || bed.price || 0);
            if (bedRent > 0) {
                if (!roomObj.minBedRent || bedRent < roomObj.minBedRent) {
                    roomObj.minBedRent = bedRent;
                }
            }
        }
    });

    // Reconcile and auto-heal room documents
    let availableRoomsCount = 0;
    roomsMap.forEach((room, roomId) => {
        let baseRent = parseFloat(room.baseRent || 0);
        let baseDeposit = parseFloat(room.baseDeposit || 0);
        const roomType = (room.roomType || '').toLowerCase();

        let derivedRent = baseRent;
        let derivedDeposit = baseDeposit;

        // Healing logic: if room rent is 0 or suspiciously low (e.g. 15 or 20), derive from beds
        if (derivedRent < 100 && room.minBedRent >= 100) {
            derivedRent = room.minBedRent;
        }

        // Fallback to property-level pricing map if still 0 or low
        if (derivedRent < 100) {
            if (roomType === 'single') {
                derivedRent = parseFloat(pricing.singleRent || pricing.price || 0);
            } else if (roomType === 'double') {
                derivedRent = parseFloat(pricing.doubleRent || 0);
            } else if (roomType === 'triple') {
                derivedRent = parseFloat(pricing.tripleRent || 0);
            } else if (roomType === 'dormitory') {
                derivedRent = parseFloat(pricing.dormitoryRent || 0);
                // Smart fallback for dormitory if specific rent is missing
                if (derivedRent === 0) {
                    derivedRent = parseFloat(pricing.tripleRent || pricing.price || 0) * 0.8;
                }
            }

            // Final safety fallback to property default price if still 0
            if (derivedRent === 0) {
                derivedRent = parseFloat(pricing.price || currentData.monthlyRent || currentData.price || 0);
            }
        }

        if (derivedDeposit < 100) {
            derivedDeposit = parseFloat(pricing.deposit || currentData.securityDeposit || currentData.deposit || 0);
        }

        let derivedOccupancyType = room.occupancyType || '';
        if (!derivedOccupancyType) {
            if (roomType === 'single') {
                derivedOccupancyType = 'Single Occupancy';
            } else if (roomType === 'double') {
                derivedOccupancyType = 'Double Sharing';
            } else if (roomType === 'triple') {
                derivedOccupancyType = 'Triple Sharing';
            } else if (roomType === 'dormitory') {
                derivedOccupancyType = 'Dormitory Sharing';
            }
        }

        const currentTotal = parseInt(room.totalBeds || 0);
        const currentAvailable = parseInt(room.availableBeds || 0);
        const currentOccupied = parseInt(room.occupiedBeds || 0);

        const calculatedTotal = room.calculatedTotalBeds || 0;
        const calculatedAvailable = room.calculatedAvailableBeds || 0;
        const calculatedOccupied = room.calculatedOccupiedBeds || 0;

        if (calculatedAvailable > 0) {
            availableRoomsCount++;
        }

        if (
            baseRent !== derivedRent ||
            baseDeposit !== derivedDeposit ||
            derivedOccupancyType !== room.occupancyType ||
            currentTotal !== calculatedTotal ||
            currentAvailable !== calculatedAvailable ||
            currentOccupied !== calculatedOccupied ||
            !room.hasOwnProperty('baseRent') ||
            !room.hasOwnProperty('baseDeposit') ||
            !room.hasOwnProperty('occupancyType')
        ) {
            hasUpdates = true;
            const roomUpdates = {
                baseRent: derivedRent,
                baseDeposit: derivedDeposit,
                occupancyType: derivedOccupancyType,
                totalBeds: calculatedTotal,
                availableBeds: calculatedAvailable,
                occupiedBeds: calculatedOccupied,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            };

            // 1. Flat room
            batch.set(db.collection('rooms').doc(roomId), roomUpdates, { merge: true });

            // 2. Property nested room
            batch.set(db.collection('properties').doc(propertyId).collection('rooms').doc(roomId), roomUpdates, { merge: true });
        }

        // Update local values so subsequent logic in controller can use them if needed
        room.baseRent = derivedRent;
        room.baseDeposit = derivedDeposit;
    });

    // Reconcile and update bed documents
    bedsMap.forEach((bed, id) => {
        totalBeds++;

        let rent = parseFloat(bed.monthlyRent || bed.price || 0);
        let advance = parseFloat(bed.securityDeposit || bed.deposit || 0);
        const status = (bed.status || 'available').toLowerCase();

        // Derive pricing from room type and property pricing map if missing or 0
        const room = roomsMap.get(bed.roomId) || {};
        const roomType = (room.roomType || '').toLowerCase();
        
        let derivedRent = rent;
        let derivedAdvance = advance;

        // Force healing if current rent is suspiciously low or missing
        if (derivedRent < 100) {
            if (room.baseRent && parseFloat(room.baseRent) >= 100) {
                derivedRent = parseFloat(room.baseRent);
            } else {
                // Last ditch fallback to pricing map if room also failed to heal
                if (roomType === 'single') {
                    derivedRent = parseFloat(pricing.singleRent || pricing.price || 0);
                } else if (roomType === 'double') {
                    derivedRent = parseFloat(pricing.doubleRent || 0);
                } else if (roomType === 'triple') {
                    derivedRent = parseFloat(pricing.tripleRent || 0);
                } else if (roomType === 'dormitory') {
                    derivedRent = parseFloat(pricing.dormitoryRent || 0);
                    if (derivedRent === 0) {
                        derivedRent = parseFloat(pricing.tripleRent || pricing.price || 0) * 0.8;
                    }
                }
            }
        }

        if (derivedAdvance < 100) {
            if (room.baseDeposit && parseFloat(room.baseDeposit) >= 100) {
                derivedAdvance = parseFloat(room.baseDeposit);
            } else {
                derivedAdvance = parseFloat(pricing.deposit || currentData.securityDeposit || currentData.deposit || 0);
            }
        }

        // Use batch.set with merge: true to defensively handle missing documents
        if (rent !== derivedRent || advance !== derivedAdvance || !bed.monthlyRent || !bed.securityDeposit || rent < 100) {
            hasUpdates = true;
            const bedUpdates = {
                monthlyRent: derivedRent,
                securityDeposit: derivedAdvance,
                price: derivedRent,
                deposit: derivedAdvance,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            };

            // 1. Flat top-level bed
            batch.set(db.collection('beds').doc(id), bedUpdates, { merge: true });

            // 2. Property subcollection bed
            batch.set(db.collection('properties').doc(propertyId).collection('beds').doc(id), bedUpdates, { merge: true });

            // 3. Room subcollection bed
            batch.set(db.collection('properties').doc(propertyId).collection('rooms').doc(bed.roomId).collection('beds').doc(id), bedUpdates, { merge: true });
        }

        candidateBeds.push({
            status,
            rent: derivedRent,
            advance: derivedAdvance,
            bed
        });

        if (status === 'occupied' || status === 'booked') {
            occupiedBeds++;
        } else if (status === 'available') {
            availableBeds++;
        } else if (status === 'reserved') {
            reservedBeds++;
        }
    });

    if (hasUpdates) {
        await batch.commit();
    }

    // 2. Dynamic Pricing Algorithm
    // Prioritize available beds with valid rent. If none, look at all valid beds.
    let finalMinRent = 0;
    let finalMinAdvance = 0;

    const availableCandidates = candidateBeds.filter(c => c.status === 'available' && c.rent > 0);

    if (availableCandidates.length > 0) {
        availableCandidates.sort((a, b) => {
            if (a.rent !== b.rent) return a.rent - b.rent;
            return a.advance - b.advance;
        });
        finalMinRent = availableCandidates[0].rent;
        finalMinAdvance = availableCandidates[0].advance;
    } else {
        const allCandidates = candidateBeds.filter(c => c.rent > 0);
        if (allCandidates.length > 0) {
            allCandidates.sort((a, b) => {
                if (a.rent !== b.rent) return a.rent - b.rent;
                return a.advance - b.advance;
            });
            finalMinRent = allCandidates[0].rent;
            finalMinAdvance = allCandidates[0].advance;
        } else {
            // Fallback to initial property level defaults if no beds exist
            finalMinRent = parseFloat(currentData.monthlyRent || currentData.price || 0);
            finalMinAdvance = parseFloat(currentData.securityDeposit || currentData.deposit || 0);
        }
    }

    const updateData = {
        totalBeds,
        occupiedBeds,
        availableBeds,
        reservedBeds,
        availableRooms: availableRoomsCount,
        monthlyRent: finalMinRent,
        securityDeposit: finalMinAdvance,
        currentOccupancy: occupiedBeds,
        updatedAt: new Date().toISOString()
    };

    // NEW: Calculate propertyDetails room counts for dashboard consistency
    let singleRooms = 0;
    let doubleRooms = 0;
    let tripleRooms = 0;
    let dormitoryBeds = 0;

    roomsMap.forEach(room => {
        const type = (room.roomType || '').toLowerCase();
        if (type === 'single') singleRooms++;
        else if (type === 'double') doubleRooms++;
        else if (type === 'triple') tripleRooms++;
        else if (type === 'dormitory') dormitoryBeds += (room.totalBeds || 0);
    });

    // 3. Transactional Update
    await db.runTransaction(async (t) => {
        t.update(propertyRef, {
            monthlyRent: finalMinRent,
            securityDeposit: finalMinAdvance,
            availableBeds: availableBeds,
            totalBeds: totalBeds,
            availableRooms: availableRoomsCount,
            currentOccupancy: occupiedBeds,
            'propertyDetails.singleRooms': singleRooms,
            'propertyDetails.doubleRooms': doubleRooms,
            'propertyDetails.tripleRooms': tripleRooms,
            'propertyDetails.dormitoryBeds': dormitoryBeds,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        t.set(statsRef, {
            totalBeds,
            occupiedBeds,
            availableBeds,
            reservedBeds,
            availableRooms: availableRoomsCount,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
    });

    return updateData;
}

// Trigger deep property reconciliation with dynamic pricing algorithm
exports.reconcileOccupancy = asyncHandler(async (req, res) => {
    const { propertyId } = req.params;
    const result = await performReconciliation(propertyId);
    res.json({
        success: true,
        propertyId,
        reconciled: result
    });
});

exports.performReconciliation = performReconciliation;

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

// Update property status (Hoster self-action)
exports.updateStatus = asyncHandler(async (req, res) => {
    const { propertyId } = req.params;
    const { status } = req.body;
    const hosterId = req.user.uid;

    const propertyRef = db.collection('properties').doc(propertyId);
    const propertyDoc = await propertyRef.get();

    if (!propertyDoc.exists) {
        return res.status(404).json({ success: false, error: 'Property not found' });
    }

    const data = propertyDoc.data();
    // Validate Ownership
    if (data.hoster_id !== hosterId && data.hosterId !== hosterId) {
        return res.status(403).json({ success: false, error: 'Unauthorized: You do not own this property' });
    }

    // Allowed status transitions for hosters
    const allowedStatuses = ['active', 'blocked', 'renewal', 'disabled', 'deleteRequested'];
    if (!allowedStatuses.includes(status)) {
        return res.status(400).json({ success: false, error: 'Invalid status requested' });
    }

    await propertyRef.update({
        status: status,
        updatedAt: new Date().toISOString()
    });

    res.json({ success: true, message: `Property status updated to ${status}` });
});

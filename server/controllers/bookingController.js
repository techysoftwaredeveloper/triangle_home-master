const { db, admin } = require('../config/firebase-config');
const { validationResult } = require('express-validator');
const asyncHandler = require('../utils/asyncHandler');

// Create a new booking with atomic occupancy check
exports.createBooking = asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  const { propertyId, roomId, bedId, price, type, tenantDetails, breakdown, moveInDate, floor, roomName, bedName } = req.body;
  const userId = req.user.uid;

  await db.runTransaction(async (transaction) => {
    const propertyRef = db.collection('properties').doc(propertyId);
    const propertyDoc = await transaction.get(propertyRef);

    if (!propertyDoc.exists) {
      const error = new Error('Property not found');
      error.statusCode = 404;
      throw error;
    }

    const propertyData = propertyDoc.data();

    // Check occupancy if not selecting a specific bed
    if (!bedId) {
      const capacity = propertyData.capacity || 0;
      const currentOccupancy = propertyData.currentOccupancy || 0;

      if (currentOccupancy >= capacity) {
        const error = new Error('Property is already at full capacity');
        error.statusCode = 400;
        throw error;
      }
    }

    const bookingRef = db.collection('bookings').doc();
    const bookingData = {
      user_id: userId,
      property_id: propertyId,
      roomId: roomId || null,
      bedId: bedId || null,
      propertyData: {
          title: propertyData.basicInfo?.collegeName || propertyData.name || 'Property',
          location: `${propertyData.locality || ''}, ${propertyData.city || ''}`,
          image: propertyData.images?.[0] || '',
          type: type || propertyData.type || '',
          floor: floor || null,
          roomName: roomName || null,
          bedName: bedName || null,
          moveInDate: moveInDate || new Date().toISOString()
      },
      price,
      breakdown: breakdown || null,
      type,
      tenantDetails,
      status: 'pending',
      paymentStatus: 'pending',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      expiryTime: new Date(Date.now() + 30 * 60 * 1000).toISOString(), // 30 minutes expiry
    };

    transaction.set(bookingRef, bookingData);
  });

  res.status(201).json({ success: true, message: 'Booking requested successfully' });
});

// Update booking status with state transition guards
exports.updateBookingStatus = asyncHandler(async (req, res) => {
    const { bookingId } = req.params;
    const { status } = req.body;

    const validStatuses = ['pending', 'approved', 'confirmed', 'cancelled', 'checkedIn', 'checkedOut', 'expired'];
    if (!validStatuses.includes(status)) {
        return res.status(400).json({ success: false, error: 'Invalid status' });
    }

    await db.runTransaction(async (transaction) => {
        const bookingRef = db.collection('bookings').doc(bookingId);
        const bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) {
            const error = new Error('Booking not found');
            error.statusCode = 404;
            throw error;
        }

        const currentBookingData = bookingDoc.data();
        const currentStatus = currentBookingData.status;
        const propertyId = currentBookingData.property_id;

        // Simple transition guard
        if (currentStatus === 'cancelled' || currentStatus === 'checkedOut' || currentStatus === 'expired') {
            throw new Error(`Cannot change status from ${currentStatus}`);
        }

        // 2. Handle Occupancy & Bed Inventory Side Effects
        const roomId = currentBookingData.roomId;
        const bedId = currentBookingData.bedId;

        if (propertyId) {
            const propertyRef = db.collection('properties').doc(propertyId);

            // SOURCE OF TRUTH: Bed Inventory
            if (bedId && roomId) {
                const bedRef = propertyRef.collection('rooms').doc(roomId).collection('beds').doc(bedId);
                const flatBedRef = db.collection('beds').doc(bedId);
                const propBedRef = propertyRef.collection('beds').doc(bedId);
                const bedDoc = await transaction.get(bedRef);

                if (!bedDoc.exists) {
                    throw new Error('Bed not found in inventory');
                }

                const bedStatus = bedDoc.data().status;

                // Transition: Confirming Booking
                if (status === 'confirmed' || status === 'bookingConfirmed') {
                    if (currentStatus !== 'confirmed' && currentStatus !== 'bookingConfirmed') {
                        if (bedStatus !== 'available' && bedStatus !== 'reserved') {
                            throw new Error('Bed is no longer available');
                        }
                        const updates = {
                            status: 'booked',
                            updatedAt: admin.firestore.FieldValue.serverTimestamp()
                        };
                        transaction.update(bedRef, updates);
                        transaction.update(flatBedRef, updates);
                        transaction.update(propBedRef, updates);
                        // Cache update on property
                        transaction.update(propertyRef, {
                            currentOccupancy: admin.firestore.FieldValue.increment(1),
                            updatedAt: admin.firestore.FieldValue.serverTimestamp()
                        });
                    }
                }

                // Transition: Checking In
                if (status === 'checkedIn' && currentStatus !== 'checkedIn') {
                    const updates = {
                        status: 'occupied',
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    };
                    transaction.update(bedRef, updates);
                    transaction.update(flatBedRef, updates);
                    transaction.update(propBedRef, updates);

                    // Set release eligibility on escrow
                    transaction.update(db.collection('escrow').doc(bookingId), {
                        releaseEligibleAt: admin.firestore.Timestamp.fromDate(
                            new Date(Date.now() + 48 * 60 * 60 * 1000)
                        ),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }

                // Transition: Cancellation/Checkout
                if ((status === 'cancelled' && (currentStatus === 'confirmed' || currentStatus === 'bookingConfirmed')) ||
                    (status === 'checkedOut' && currentStatus === 'checkedIn') ||
                    (status === 'expired' || status === 'reservationExpired')) {
                    const updates = {
                        status: 'available',
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    };
                    transaction.update(bedRef, updates);
                    transaction.update(flatBedRef, updates);
                    transaction.update(propBedRef, updates);
                    transaction.update(propertyRef, {
                        currentOccupancy: admin.firestore.FieldValue.increment(-1),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                }
            } else {
                // Fallback for property-level only occupancy
                if ((status === 'confirmed' || status === 'bookingConfirmed') &&
                    (currentStatus !== 'confirmed' && currentStatus !== 'bookingConfirmed')) {
                    transaction.update(propertyRef, {
                        currentOccupancy: admin.firestore.FieldValue.increment(1),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }

                if ((status === 'cancelled' && (currentStatus === 'confirmed' || currentStatus === 'bookingConfirmed')) ||
                    (status === 'checkedOut' && currentStatus === 'checkedIn')) {
                    transaction.update(propertyRef, {
                        currentOccupancy: admin.firestore.FieldValue.increment(-1),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }
            }
        }

        const bookingUpdates = {
            status: status,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        if (status === 'checkedIn') {
            bookingUpdates.checkedInAt = admin.firestore.FieldValue.serverTimestamp();
        }

        transaction.update(bookingRef, bookingUpdates);
    });

    // Handle financial side effects after transaction (or inside if atomic is strictly required,
    // but here we might prefer a separate step or Cloud Function)
    if (status === 'paymentSuccess') {
        // We could trigger escrow creation here, but usually it's better to do it via a dedicated API call
        // or a background trigger once the payment is verified.
    }

    res.json({ success: true, message: `Booking updated to ${status}` });
});

// Get current user's bookings
exports.getMyBookings = asyncHandler(async (req, res) => {
    const userId = req.user.uid;
    const bookingsSnapshot = await db.collection('bookings')
        .where('user_id', '==', userId)
        .orderBy('createdAt', 'desc')
        .get();

    const bookings = [];
    bookingsSnapshot.forEach(doc => bookings.push({ id: doc.id, ...doc.data() }));
    res.json({ success: true, bookings });
});

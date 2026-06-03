const { db } = require('../config/firebase-config');
const { validationResult } = require('express-validator');
const asyncHandler = require('../utils/asyncHandler');

// Create a new booking with atomic occupancy check
exports.createBooking = asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }

  const { propertyId, price, type, tenantDetails } = req.body;
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
    const capacity = propertyData.capacity || 0;
    const currentOccupancy = propertyData.currentOccupancy || 0;

    if (currentOccupancy >= capacity) {
      const error = new Error('Property is already at full capacity');
      error.statusCode = 400;
      throw error;
    }

    const bookingRef = db.collection('bookings').doc();
    const bookingData = {
      user_id: userId,
      property_id: propertyId,
      propertyData: {
          title: propertyData.basicInfo?.collegeName || propertyData.name || 'Property',
          location: `${propertyData.locality || ''}, ${propertyData.city || ''}`,
          image: propertyData.images?.[0] || ''
      },
      price,
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

        // Handle Occupancy & Bed Inventory Side Effects
        if (propertyId) {
            const propertyRef = db.collection('properties').doc(propertyId);
            const roomId = currentBookingData.roomId;
            const bedId = currentBookingData.bedId;

            // SOURCE OF TRUTH: Bed Inventory
            if (bedId && roomId) {
                const bedRef = propertyRef.collection('rooms').doc(roomId).collection('beds').doc(bedId);
                const bedDoc = await transaction.get(bedRef);

                if (!bedDoc.exists) {
                    throw new Error('Bed not found in inventory');
                }

                const bedStatus = bedDoc.data().status;

                // Transition: Confirming Booking
                if (status === 'confirmed' && currentStatus !== 'confirmed') {
                    if (bedStatus !== 'available' && bedStatus !== 'reserved') {
                        throw new Error('Bed is no longer available');
                    }
                    transaction.update(bedRef, {
                        status: 'booked',
                        updatedAt: new Date().toISOString()
                    });
                    // Cache update on property
                    transaction.update(propertyRef, {
                        currentOccupancy: db.FieldValue.increment(1),
                        updatedAt: new Date().toISOString()
                    });
                }

                // Transition: Checking In
                if (status === 'checkedIn' && currentStatus !== 'checkedIn') {
                    transaction.update(bedRef, {
                        status: 'occupied',
                        updatedAt: new Date().toISOString()
                    });
                }

                // Transition: Cancellation/Checkout
                if ((status === 'cancelled' && currentStatus === 'confirmed') ||
                    (status === 'checkedOut' && currentStatus === 'checkedIn') ||
                    (status === 'expired')) {
                    transaction.update(bedRef, {
                        status: 'available',
                        updatedAt: new Date().toISOString()
                    });
                    transaction.update(propertyRef, {
                        currentOccupancy: db.FieldValue.increment(-1),
                        updatedAt: new Date().toISOString()
                    });
                }
            } else {
                // Fallback for property-level only occupancy
                if (status === 'confirmed' && currentStatus !== 'confirmed') {
                    transaction.update(propertyRef, {
                        currentOccupancy: db.FieldValue.increment(1),
                        updatedAt: new Date().toISOString(),
                    });
                }

                if ((status === 'cancelled' && currentStatus === 'confirmed') ||
                    (status === 'checkedOut' && currentStatus === 'checkedIn')) {
                    transaction.update(propertyRef, {
                        currentOccupancy: db.FieldValue.increment(-1),
                        updatedAt: new Date().toISOString(),
                    });
                }
            }
        }

        transaction.update(bookingRef, {
            status: status,
            updatedAt: new Date().toISOString()
        });
    });

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

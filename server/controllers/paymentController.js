const { db, admin } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');
const logger = require('../utils/logger');

/**
 * Records a payment and triggers booking status transition.
 * Ported from PaymentService in Flutter.
 */
exports.recordPayment = asyncHandler(async (req, res) => {
    const { bookingId, requestId, amount, type, paymentMethod, extraData } = req.body;

    if (!bookingId || !requestId || !amount) {
        return res.status(400).json({ success: false, error: 'Missing required fields' });
    }

    try {
        // 1. Idempotency Check
        const existing = await db.collection('payments')
            .where('request_id', '==', requestId)
            .limit(1)
            .get();

        if (!existing.empty) {
            return res.json({
                success: true,
                message: 'Payment already recorded',
                paymentId: existing.docs[0].id
            });
        }

        const paymentDocRef = db.collection('payments').doc();
        let bookingData;

        // 2. Transactional update
        await db.runTransaction(async (transaction) => {
            const bookingRef = db.collection('bookings').doc(bookingId);
            const bookingDoc = await transaction.get(bookingRef);

            if (!bookingDoc.exists) {
                const error = new Error('Booking not found');
                error.statusCode = 404;
                throw error;
            }

            bookingData = bookingDoc.data();

            // Record Payment
            transaction.set(paymentDocRef, {
                booking_id: bookingId,
                request_id: requestId,
                amount: amount,
                type: type,
                method: paymentMethod,
                status: 'completed',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                ...extraData,
            });

            const currentStatus = bookingData.status || 'pending';

            // Logic from PaymentService.dart: if approved, move to confirmed
            if (currentStatus === 'approved') {
                transaction.update(bookingRef, {
                    status: 'confirmed',
                    paymentStatus: 'completed',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                const propertyId = bookingData.property_id;
                if (propertyId) {
                    transaction.update(db.collection('properties').doc(propertyId), {
                        currentOccupancy: admin.firestore.FieldValue.increment(1),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }
            } else if (currentStatus === 'reservationPending') {
                // Handle different status names if applicable
                transaction.update(bookingRef, {
                    status: 'paymentSuccess',
                    paymentStatus: 'completed',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        });

        res.status(201).json({
            success: true,
            message: 'Payment recorded successfully',
            paymentId: paymentDocRef.id
        });

    } catch (error) {
        logger.error(`Payment recording failed: ${error.message}`);
        throw error;
    }
});

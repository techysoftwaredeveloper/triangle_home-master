const { db, admin } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');
const logger = require('../utils/logger');

/**
 * Creates an escrow record.
 * Ported from EscrowService in Flutter.
 */
exports.createEscrow = asyncHandler(async (req, res) => {
    const { bookingId, deposit, rent, commissionRate = 25.0 } = req.body;

    if (!bookingId) {
        return res.status(400).json({ success: false, error: 'Booking ID is required' });
    }

    const gross = parseFloat(deposit || 0) + parseFloat(rent || 0);
    const commissionAmount = (parseFloat(rent || 0) * commissionRate) / 100;
    const hosterAmount = gross - commissionAmount;

    const escrowData = {
        bookingId,
        depositAmount: deposit,
        rentAmount: rent,
        grossAmount: gross,
        commissionRate,
        commissionAmount,
        hosterAmount,
        status: 'held',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        releaseEligibleAt: null,
        isFrozen: false,
        freezeReason: null,
    };

    await db.collection('escrow').doc(bookingId).set(escrowData);

    // Log financial event
    await db.collection('financial_events').add({
        bookingId,
        event: 'ESCROW_CREATED',
        amount: gross,
        performedBy: 'system',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ success: true, message: 'Escrow record created' });
});

/**
 * Requests a payout.
 * Ported from PayoutService in Flutter.
 */
exports.requestPayout = asyncHandler(async (req, res) => {
    const { bookingId } = req.body;
    const userId = req.user.uid;

    const escrowRef = db.collection('escrow').doc(bookingId);
    const escrowDoc = await escrowRef.get();

    if (!escrowDoc.exists) {
        return res.status(404).json({ success: false, error: 'Escrow record not found' });
    }

    // Verify ownership or permissions (simplified for now)

    await escrowRef.update({
        status: 'payoutRequested',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('financial_events').add({
        bookingId,
        event: 'PAYOUT_REQUESTED',
        performedBy: userId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({ success: true, message: 'Payout requested' });
});

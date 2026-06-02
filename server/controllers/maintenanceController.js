const { db, admin } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');

/**
 * THE JANITOR: 15-MINUTE AUTOMATION TASKS
 */
exports.runMaintenanceTasks = asyncHandler(async (req, res) => {
  const now = admin.firestore.Timestamp.now();
  const results = {
    expiredReservations: 0,
    readyPayouts: 0,
    notificationJobs: 0
  };

  // 1. Expire Unpaid Reservations
  const expiredResSnap = await db.collection('bookings')
    .where('status', '==', 'reserved')
    .where('expiryTime', '<=', now)
    .get();

  for (const doc of expiredResSnap.docs) {
    await db.runTransaction(async (transaction) => {
      transaction.update(doc.ref, {
        status: 'reservationExpired',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // Log audit event
      transaction.set(db.collection('booking_events').doc(), {
        booking_id: doc.id,
        event: 'RESERVATION_EXPIRED',
        reason: 'Auto-expired after 48h limit',
        performed_by: 'system_janitor',
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    });
    results.expiredReservations++;
  }

  // 2. Mark Escrow as Ready For Payout
  const readyPayoutSnap = await db.collection('escrow')
    .where('escrowStatus', '==', 'held')
    .where('releaseEligibleAt', '<=', now)
    .get();

  for (const doc of readyPayoutSnap.docs) {
    // Check if there are active disputes before marking ready
    const disputes = await db.collection('disputes')
      .where('bookingId', '==', doc.data().bookingId)
      .where('status', 'in', ['open', 'underReview'])
      .get();

    if (disputes.empty) {
      await doc.ref.update({
        escrowStatus: 'readyForPayout',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      results.readyPayouts++;
    }
  }

  // 3. Process Notification Queue (Basic logic)
  const pendingJobs = await db.collection('notification_jobs')
    .where('status', '==', 'pending')
    .limit(20)
    .get();

  for (const job of pendingJobs.docs) {
    // Note: Integration with sendNotification.js would happen here
    await job.ref.update({
      status: 'processed',
      processedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    results.notificationJobs++;
  }

  res.json({ success: true, results });
});

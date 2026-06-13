const cron = require('node-cron');
const { db, admin } = require('../config/firebase-config');

/**
 * Scheduled tasks
 */

// 1. Cancel expired bookings every 15 minutes
cron.schedule('*/15 * * * *', async () => {
    console.log('Running task: Cancel expired bookings');
    const now = new Date().toISOString();

    try {
        const expiredBookingsSnapshot = await db.collection('bookings')
            .where('status', '==', 'pending')
            .where('expiryTime', '<', now)
            .get();

        const batch = db.batch();
        expiredBookingsSnapshot.forEach(doc => {
            batch.update(doc.ref, {
                status: 'expired',
                updatedAt: new Date().toISOString()
            });
        });

        await batch.commit();
        if (expiredBookingsSnapshot.size > 0) {
            console.log(`Cancelled ${expiredBookingsSnapshot.size} expired bookings.`);
        }
    } catch (error) {
        console.error('Error in expired bookings cron:', error);
    }
});

// 2. Daily Integrity Check (at 3 AM)
cron.schedule('0 3 * * *', async () => {
    console.log('Running task: Daily integrity check');
    // Implement integrity logic here if needed
});

// 3. Clean up expired bed reservations every 5 minutes
cron.schedule('*/5 * * * *', async () => {
    console.log('Running task: Clean up expired bed reservations');
    const now = admin.firestore.Timestamp.now();

    try {
        const expiredReservationsSnapshot = await db.collection('bed_reservations')
            .where('expiresAt', '<', now)
            .get();

        const activeExpiredDocs = [];
        expiredReservationsSnapshot.forEach(doc => {
            if (doc.data().status === 'active') {
                activeExpiredDocs.push(doc);
            }
        });

        if (activeExpiredDocs.length === 0) {
            return;
        }

        console.log(`Found ${activeExpiredDocs.length} expired bed reservations.`);

        const propertiesToReconcile = new Set();
        
        for (const doc of activeExpiredDocs) {
            const data = doc.data();
            const { propertyId, roomId, bedId } = data;

            if (!propertyId || !roomId || !bedId) {
                continue;
            }

            console.log(`Releasing expired bed: ${bedId} in room: ${roomId} for property: ${propertyId}`);

            try {
                // Let's release the bed across all 3 collections in a transaction
                await db.runTransaction(async (transaction) => {
                    const flatBedRef = db.collection('beds').doc(bedId);
                    const propBedRef = db.collection('properties').doc(propertyId).collection('beds').doc(bedId);
                    const roomBedRef = db.collection('properties').doc(propertyId).collection('rooms').doc(roomId).collection('beds').doc(bedId);
                    const reservationRef = doc.ref;

                    const bedUpdates = {
                        status: 'available',
                        reservedBy: null,
                        reservationExpiresAt: null,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    };

                    transaction.update(flatBedRef, bedUpdates);
                    transaction.update(propBedRef, bedUpdates);
                    transaction.update(roomBedRef, bedUpdates);
                    transaction.update(reservationRef, {
                        status: 'expired',
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                });

                propertiesToReconcile.add(propertyId);
            } catch (txError) {
                console.error(`Transaction failed for reservation ${doc.id}:`, txError.message || txError);
            }
        }

        // Trigger reconciliation for all affected properties to recalculate room and property stats
        const { performReconciliation } = require('../controllers/propertyController');
        for (const propertyId of propertiesToReconcile) {
            try {
                console.log(`Triggering reconciliation for property: ${propertyId}`);
                await performReconciliation(propertyId);
                console.log(`Reconciliation complete for property: ${propertyId}`);
            } catch (reconErr) {
                console.error(`Failed to reconcile property ${propertyId}:`, reconErr.message || reconErr);
            }
        }
    } catch (error) {
        console.error('Error in expired bed reservations cron:', error.message || error);
    }
});

console.log('Cron tasks initialized');

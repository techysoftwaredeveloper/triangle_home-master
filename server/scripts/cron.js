const cron = require('node-cron');
const { db } = require('../config/firebase-config');

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

console.log('Cron tasks initialized');

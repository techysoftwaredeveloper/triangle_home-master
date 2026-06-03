const { admin, db } = require('../config/firebase-config');

/**
 * Utility to send push notifications with deduplication
 * @param {string} eventId - Unique ID for the event (e.g., booking_confirmed_123)
 */
exports.sendNotification = async (token, title, body, data = {}, eventId = null) => {
  if (eventId) {
    const logRef = db.collection('notification_logs').doc(eventId);
    const logDoc = await logRef.get();
    if (logDoc.exists) {
      console.log(`Notification for event ${eventId} already sent. Skipping.`);
      return null;
    }
    await logRef.set({
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      recipient: token,
      title
    });
  }

  const message = {
    notification: {
      title,
      body,
    },
    data,
    token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    return response;
  } catch (error) {
    console.error('Error sending message:', error);
    throw error;
  }
};

exports.sendToTopic = async (topic, title, body, data = {}) => {
    const message = {
      notification: {
        title,
        body,
      },
      data,
      topic,
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('Successfully sent message to topic:', response);
      return response;
    } catch (error) {
      console.error('Error sending message to topic:', error);
      throw error;
    }
  };

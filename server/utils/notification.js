const { admin } = require('../config/firebase-config');

/**
 * Utility to send push notifications
 */
exports.sendNotification = async (token, title, body, data = {}) => {
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

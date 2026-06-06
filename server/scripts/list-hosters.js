const { db } = require('../config/firebase-config');

const checkType = async () => {
  try {
    const snapshot = await db.collection('users').get();
    snapshot.forEach(doc => {
      const data = doc.data();
      const updated = data.updatedAt;
      console.log(`ID: ${doc.id}`);
      console.log(`updatedAt type: ${typeof updated}`);
      if (updated) {
        console.log(`updatedAt constructor: ${updated.constructor.name}`);
        console.log(`toDate: ${typeof updated.toDate === 'function' ? 'exists' : 'not a function'}`);
      }
    });
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
};

checkType();

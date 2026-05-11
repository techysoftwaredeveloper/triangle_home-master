const { db, auth } = require('../firebase-config');

// Get statistics for the dashboard
exports.getStats = async (req, res) => {
  try {
    const [usersSnapshot, hostersSnapshot, requestsSnapshot, propertiesSnapshot, bookingsSnapshot, paymentsSnapshot] = await Promise.all([
      db.collection('student').get(),
      db.collection('hoster').get(),
      db.collection('hoster_requests').where('status', '==', 'pending').get(),
      db.collection('properties').get(),
      db.collection('bookings').get(),
      db.collection('payments').get()
    ]);

    let totalRevenue = 0;
    paymentsSnapshot.forEach(doc => {
      totalRevenue += doc.data().amount || 0;
    });

    res.json({
      success: true,
      totalUsers: usersSnapshot.size + hostersSnapshot.size,
      totalHosters: hostersSnapshot.size,
      totalStudents: usersSnapshot.size,
      totalProperties: propertiesSnapshot.size,
      totalBookings: bookingsSnapshot.size,
      totalRevenue: totalRevenue,
      pendingProperties: propertiesSnapshot.docs.filter(doc => doc.data().status === 'pending').length,
      pendingHosters: requestsSnapshot.size
    });
  } catch (error) {
    console.error('Stats Error:', error);
    res.status(500).json({ success: false, error: 'Failed to retrieve dashboard statistics' });
  }
};

// List all users
exports.getAllUsers = async (req, res) => {
  try {
    const [studentsSnapshot, hostersSnapshot, requestsSnapshot] = await Promise.all([
      db.collection('student').get(),
      db.collection('hoster').get(),
      db.collection('hoster_requests').get()
    ]);

    const hosters = hostersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data(), role: 'hoster' }));

    requestsSnapshot.forEach(doc => {
      const data = doc.data();
      if (!hosters.some(h => h.id === doc.id)) {
        hosters.push({ id: doc.id, ...data, role: 'hoster', status: data.status || 'pending' });
      }
    });

    const students = studentsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data(), role: 'student' }));

    res.json({ success: true, students, hosters });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to retrieve user list' });
  }
};

// List all properties
exports.getAllProperties = async (req, res) => {
  try {
    const propertiesSnapshot = await db.collection('properties').orderBy('createdAt', 'desc').get();
    const properties = [];
    propertiesSnapshot.forEach(doc => properties.push({ id: doc.id, ...doc.data() }));
    res.json(properties);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// List all bookings
exports.getAllBookings = async (req, res) => {
  try {
    const bookingsSnapshot = await db.collection('bookings').orderBy('createdAt', 'desc').get();
    const bookings = [];
    bookingsSnapshot.forEach(doc => bookings.push({ id: doc.id, ...doc.data() }));
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Ban or Unban a user
exports.toggleUserStatus = async (req, res) => {
  const { userId, collection, status } = req.body; // status: 'active' or 'banned'
  try {
    await db.collection(collection).doc(userId).update({
      accountStatus: status,
      updatedAt: new Date().toISOString()
    });

    // Also update custom claims if needed to prevent login
    const user = await auth.getUser(userId);
    await auth.setCustomUserClaims(userId, { ...user.customClaims, banned: status === 'banned' });

    res.json({ message: `User ${status} successfully` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Property Approval
exports.updatePropertyStatus = async (req, res) => {
  const { propertyId } = req.params;
  const { status } = req.body; // 'approved', 'rejected', 'pending'
  try {
    await db.collection('properties').doc(propertyId).update({
      status: status,
      updatedAt: new Date().toISOString()
    });
    res.json({ message: `Property ${status} successfully` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Hoster Approval
exports.approveHoster = async (req, res) => {
  const { hosterId } = req.params;
  try {
    // 1. Get the request data
    const requestDoc = await db.collection('hoster_requests').doc(hosterId).get();
    let hosterData = {};

    if (requestDoc.exists) {
      hosterData = requestDoc.data();
      // Update request status
      await db.collection('hoster_requests').doc(hosterId).update({
        status: 'approved',
        updatedAt: new Date().toISOString()
      });
    }

    // 2. Create/Update in hoster collection
    await db.collection('hoster').doc(hosterId).set({
      ...hosterData,
      status: 'approved',
      updatedAt: new Date().toISOString()
    }, { merge: true });

    // 3. Set custom claim for hoster
    await auth.setCustomUserClaims(hosterId, { role: 'hoster' });

    res.json({ message: 'Hoster approved successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

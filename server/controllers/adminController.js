const { db, auth } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');

// Get statistics for the dashboard
exports.getStats = asyncHandler(async (req, res) => {
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
});

// List all users
exports.getAllUsers = asyncHandler(async (req, res) => {
    const [studentsSnapshot, hostersSnapshot, requestsSnapshot] = await Promise.all([
      db.collection('student').get(),
      db.collection('hoster').get(),
      db.collection('hoster_requests').get()
    ]);

    // 1. Get explicitly approved hosters
    const hosters = hostersSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      role: 'hoster',
      status: 'approved'
    }));

    // 2. Add pending/rejected requests from hoster_requests
    requestsSnapshot.forEach(doc => {
      const data = doc.data();
      if (!hosters.some(h => h.id === doc.id)) {
        hosters.push({
          id: doc.id,
          ...data,
          role: 'hoster',
          status: data.status || 'pending'
        });
      } else {
        const index = hosters.findIndex(h => h.id === doc.id);
        hosters[index].status = 'approved';
      }
    });

    const students = studentsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data(), role: 'student' }));

    res.json({ success: true, students, hosters });
});

// List all properties
exports.getAllProperties = asyncHandler(async (req, res) => {
    const propertiesSnapshot = await db.collection('properties').orderBy('createdAt', 'desc').get();
    const properties = [];
    propertiesSnapshot.forEach(doc => properties.push({ id: doc.id, ...doc.data() }));
    res.json(properties);
});

// List all bookings
exports.getAllBookings = asyncHandler(async (req, res) => {
    const bookingsSnapshot = await db.collection('bookings').orderBy('createdAt', 'desc').get();
    const bookings = [];
    bookingsSnapshot.forEach(doc => bookings.push({ id: doc.id, ...doc.data() }));
    res.json(bookings);
});

// Ban or Unban a user
exports.toggleUserStatus = asyncHandler(async (req, res) => {
  const { userId, collection, status } = req.body; // status: 'active' or 'banned'
  await db.collection(collection).doc(userId).update({
    accountStatus: status,
    updatedAt: new Date().toISOString()
  });

  const user = await auth.getUser(userId);
  await auth.setCustomUserClaims(userId, { ...user.customClaims, banned: status === 'banned' });

  res.json({ message: `User ${status} successfully` });
});

// Property Approval
exports.updatePropertyStatus = asyncHandler(async (req, res) => {
  const { propertyId } = req.params;
  const { status } = req.body; // 'approved', 'rejected', 'pending'
  await db.collection('properties').doc(propertyId).update({
    status: status,
    updatedAt: new Date().toISOString()
  });
  res.json({ message: `Property ${status} successfully` });
});

// Hoster Approval
exports.approveHoster = asyncHandler(async (req, res) => {
  const { hosterId } = req.params;
  const requestDoc = await db.collection('hoster_requests').doc(hosterId).get();
  let hosterData = {};

  if (requestDoc.exists) {
    hosterData = requestDoc.data();
    await db.collection('hoster_requests').doc(hosterId).update({
      status: 'approved',
      updatedAt: new Date().toISOString()
    });
  }

  await db.collection('hoster').doc(hosterId).set({
    ...hosterData,
    status: 'approved',
    updatedAt: new Date().toISOString()
  }, { merge: true });

  await auth.setCustomUserClaims(hosterId, { role: 'hoster' });

  res.json({ message: 'Hoster approved successfully' });
});

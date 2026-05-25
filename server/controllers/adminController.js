const { db, auth } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');

/**
 * UPDATED: Dashboard Statistics
 * Aligned with real-time app needs and correct collection names
 */
exports.getStats = asyncHandler(async (req, res) => {
    const [
      usersSnapshot,
      propertiesSnapshot,
      bookingsSnapshot,
      paymentsSnapshot,
      suggestionsSnapshot,
      reportsSnapshot,
      auditLogsSnapshot
    ] = await Promise.all([
      db.collection('users').get(),
      db.collection('properties').get(),
      db.collection('bookings').get(),
      db.collection('payments').get(),
      db.collection('property_suggestions').get(), // Corrected collection name
      db.collection('reports').get(),
      db.collection('audit_logs').get()
    ]);

    let totalRevenue = 0;
    paymentsSnapshot.forEach(doc => {
      totalRevenue += doc.data().amount || 0;
    });

    const students = usersSnapshot.docs.filter(doc => {
      const data = doc.data();
      return data.role === 'student' || data.role === 'user';
    }).length;

    const hosters = usersSnapshot.docs.filter(doc => doc.data().role === 'hoster').length;

    const pendingProperties = propertiesSnapshot.docs.filter(doc => doc.data().status === 'pending').length;

    // Check for pending hosters in the 'users' collection with status 'pending'
    const pendingHosters = usersSnapshot.docs.filter(doc =>
      doc.data().role === 'hoster' &&
      (doc.data().status === 'pending' || doc.data().accountStatus === 'pending')
    ).length;

    const pendingReports = reportsSnapshot.docs.filter(doc =>
      (doc.data().status || '').toLowerCase() === 'pending'
    ).length;

    const pendingSuggestions = suggestionsSnapshot.docs.filter(doc =>
      (doc.data().status || '').toLowerCase() === 'pending'
    ).length;

    const pendingModeration = auditLogsSnapshot.docs.filter(doc =>
      (doc.data().status || '').toLowerCase() === 'pending'
    ).length;

    res.json({
      success: true,
      totalUsers: usersSnapshot.size,
      totalHosters: hosters,
      totalStudents: students,
      totalProperties: propertiesSnapshot.size,
      totalBookings: bookingsSnapshot.size,
      totalRevenue: totalRevenue,
      pendingProperties: pendingProperties,
      pendingHosters: pendingHosters,
      pendingApprovals: pendingProperties + pendingHosters,
      pendingReports: pendingReports,
      pendingSuggestions: pendingSuggestions,
      pendingModeration: pendingModeration,
      totalNotifications: pendingProperties + pendingHosters + pendingReports + pendingModeration
    });
});

/**
 * UPDATED: User Management
 * Aligned with 'users' collection and is_active boolean
 */
exports.getAllUsers = asyncHandler(async (req, res) => {
    const usersSnapshot = await db.collection('users').orderBy('createdAt', 'desc').get();
    const users = usersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    const students = users.filter(u => u.role === 'student' || u.role === 'user');
    const hosters = users.filter(u => u.role === 'hoster');

    res.json({ success: true, students, hosters, total: users.length });
});

/**
 * UPDATED: Status Toggles
 * Using is_active (bool) and accountStatus (string)
 */
exports.toggleUserStatus = asyncHandler(async (req, res) => {
  const { userId, status, isActive } = req.body;

  const updateData = {
    updatedAt: new Date().toISOString()
  };

  if (isActive !== undefined) updateData.is_active = isActive;
  if (status) updateData.accountStatus = status;

  await db.collection('users').doc(userId).update(updateData);

  // Set custom claims for security layer
  const user = await auth.getUser(userId);
  await auth.setCustomUserClaims(userId, {
    ...user.customClaims,
    isActive: isActive !== false,
    banned: isActive === false || status === 'banned'
  });

  res.json({ success: true, message: `User status updated successfully` });
});

/**
 * UPDATED: Property Approvals
 */
exports.updatePropertyStatus = asyncHandler(async (req, res) => {
  const { propertyId } = req.params;
  const { status } = req.body; // 'active', 'rejected', 'pending'
  await db.collection('properties').doc(propertyId).update({
    status: status,
    updatedAt: new Date().toISOString()
  });
  res.json({ success: true, message: `Property ${status} successfully` });
});

/**
 * UPDATED: Hoster Elevation
 */
exports.approveHoster = asyncHandler(async (req, res) => {
  const { hosterId } = req.params;

  await db.collection('users').doc(hosterId).update({
    status: 'approved',
    accountStatus: 'active',
    role: 'hoster',
    is_active: true,
    updatedAt: new Date().toISOString()
  });

  await auth.setCustomUserClaims(hosterId, { role: 'hoster' });

  res.json({ success: true, message: 'Hoster approved successfully' });
});

exports.getAllProperties = asyncHandler(async (req, res) => {
  const snapshot = await db.collection('properties').orderBy('createdAt', 'desc').get();
  const properties = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  res.json(properties);
});

exports.getAllBookings = asyncHandler(async (req, res) => {
  const snapshot = await db.collection('bookings').orderBy('createdAt', 'desc').get();
  const bookings = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  res.json(bookings);
});

exports.updateUserRole = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const { role } = req.body;

  await db.collection('users').doc(userId).update({
    role: role,
    updatedAt: new Date().toISOString()
  });

  await auth.setCustomUserClaims(userId, { role: role });

  res.json({ success: true, message: `User role updated to ${role}` });
});

exports.updateSuggestionStatus = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  await db.collection('property_suggestions').doc(id).update({
    status: status,
    updatedAt: new Date().toISOString()
  });
  res.json({ success: true, message: 'Suggestion status updated' });
});

exports.updateReportStatus = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { status, resolution } = req.body;
  const updateData = {
    status: status,
    updatedAt: new Date().toISOString()
  };
  if (resolution) updateData.resolution = resolution;

  await db.collection('reports').doc(id).update(updateData);
  res.json({ success: true, message: 'Report status updated' });
});

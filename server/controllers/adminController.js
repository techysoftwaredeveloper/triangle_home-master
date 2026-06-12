const { db, auth } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');
const { cache } = require('../utils/cache');

/**
 * UPDATED: Dashboard Statistics
 * Aligned with real-time app needs and correct collection names
 */
exports.getStats = asyncHandler(async (req, res) => {
    // HIGH-PERFORMANCE: Using O(1) count() aggregations for production-grade scale
    const [
      usersCount,
      hostersCount,
      studentsCount,
      professionalsCount,
      pendingHostersCount,
      totalPropertiesCount,
      pendingPropertiesCount,
      totalBookingsCount,
      pendingReportsCount,
      pendingSuggestionsCount,
      pendingModerationCount,
      totalLeadsCount,
      paymentsSnapshot // Still need snapshot for revenue sum (until Firestore sum() is used)
    ] = await Promise.all([
      db.collection('users').count().get(),
      db.collection('users').where('role', 'in', ['hoster', 'owner', 'manager', 'agency']).count().get(),
      db.collection('users').where('role', 'in', ['student', 'user']).count().get(),
      db.collection('users').where('role', '==', 'professional').count().get(),
      db.collection('users').where('onboardingStatus', '==', 'submitted').count().get(),
      db.collection('properties').count().get(),
      db.collection('properties').where('status', '==', 'pending').count().get(),
      db.collection('bookings').count().get(),
      db.collection('reports').where('status', '==', 'pending').count().get(),
      db.collection('property_suggestions').where('status', '==', 'pending').count().get(),
      db.collection('audit_logs').where('status', '==', 'pending').count().get(),
      db.collection('leads').count().get(),
      db.collection('payments').where('status', 'in', ['paid', 'success', 'captured']).get()
    ]);

    let totalRevenue = 0;
    paymentsSnapshot.forEach(doc => {
      totalRevenue += doc.data().amount || 0;
    });

    // Note: Global occupancy calculation still requires properties snapshot or a pre-aggregated doc.
    // For now, we fetch properties size from count.
    // Optimization: In a real production app, keep a 'stats' doc updated via Cloud Functions.

    res.json({
      success: true,
      totalUsers: usersCount.data().count,
      totalHosters: hostersCount.data().count,
      totalStudents: studentsCount.data().count,
      totalProfessionals: professionalsCount.data().count,
      totalProperties: totalPropertiesCount.data().count,
      totalBookings: totalBookingsCount.data().count,
      totalLeads: totalLeadsCount.data().count,
      totalRevenue: totalRevenue,
      pendingProperties: pendingPropertiesCount.data().count,
      pendingHosters: pendingHostersCount.data().count,
      pendingReports: pendingReportsCount.data().count,
      pendingSuggestions: pendingSuggestionsCount.data().count,
      pendingModeration: pendingModerationCount.data().count,
      pendingVerifications: 0, // Simplified for O(1), add specific field query if needed
      pendingApprovals: pendingPropertiesCount.data().count + pendingHostersCount.data().count,
      totalNotifications: pendingPropertiesCount.data().count + pendingHostersCount.data().count + pendingReportsCount.data().count
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
  if (status) {
    updateData.accountStatus = status;
    updateData.status = status; // Keep in sync
    updateData['permissions.status'] = status; // Keep in sync
  }

  await db.collection('users').doc(userId).set(updateData, { merge: true });

  // Clear related cache
  cache.del('/api/admin/stats');
  cache.del('/api/admin/users');

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

  await db.collection('properties').doc(propertyId).set({
    status: status,
    updatedAt: new Date().toISOString()
  }, { merge: true });

  cache.del('/api/admin/stats');
  cache.del('/api/admin/properties');

  res.json({ success: true, message: `Property ${status} successfully` });
});

/**
 * UPDATED: Hoster Elevation
 * Copies info from hoster_requests to user profile info
 */
exports.approveHoster = asyncHandler(async (req, res) => {
  const { hosterId } = req.params;

  // 1. Get the hoster request details (legacy check)
  const requestDoc = await db.collection('hoster_requests').doc(hosterId).get();
  let hosterInfo = {};

  if (requestDoc.exists) {
    const data = requestDoc.data();
    hosterInfo = {
      name: data.name,
      email: data.email,
      phone: data.phone,
      businessName: data.businessName,
      address: data.businessAddress,
      propertyType: data.propertyType,
      createdAt: data.requestedAt || new Date()
    };

    // Mark request as approved
    await db.collection('hoster_requests').doc(hosterId).update({
      status: 'approved',
      reviewedAt: new Date()
    });
  }

  // 2. Update the user document atomically
  const userUpdate = {
    status: 'approved',
    accountStatus: 'active',
    onboardingStatus: 'approved',
    'permissions.status': 'approved',
    role: 'hoster',
    is_active: true,
    updatedAt: new Date().toISOString()
  };

  // If we have legacy info from hoster_requests, migrate it
  if (Object.keys(hosterInfo).length > 0) {
    userUpdate.info = hosterInfo;
  }

  await db.collection('users').doc(hosterId).update(userUpdate);

  // 3. Set Custom User Claims for Firebase Auth
  await auth.setCustomUserClaims(hosterId, { role: 'hoster', isAdmin: false });

  res.json({
    success: true,
    message: 'Hoster approved successfully',
    data: { uid: hosterId, role: 'hoster' }
  });
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

/**
 * NEW: Document Verification Management
 * Aligned with Verification Center Screen
 */
exports.getPendingVerifications = asyncHandler(async (req, res) => {
  const usersSnapshot = await db.collection('users').get();
  const pendingUsers = usersSnapshot.docs
    .map(doc => ({ id: doc.id, ...doc.data() }))
    .filter(u => {
      const verif = u.verification || {};
      return verif.govIdStatus === 'pending' ||
             verif.roleIdStatus === 'pending' ||
             verif.addressStatus === 'pending' ||
             verif.selfieStatus === 'pending';
    });

  res.json({ success: true, users: pendingUsers });
});

exports.updateVerificationStatus = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const { fieldPrefix, status, isVerified, rejectionReason } = req.body;

  const updateData = {
    updatedAt: new Date().toISOString()
  };

  // Update status for the specific document type
  updateData[`verification.${fieldPrefix}Status`] = status;

  // If verifying, set the boolean flag
  if (isVerified !== undefined) {
    updateData[`verification.${fieldPrefix}Verified`] = isVerified;
  }

  // Handle rejection reason if any
  if (rejectionReason) {
    updateData[`verification.${fieldPrefix}RejectionReason`] = rejectionReason;
  }

  await db.collection('users').doc(userId).set(updateData, { merge: true });

  // Recalculate Booking Readiness on server if needed or let client handle on sync
  // For now, simple update
  res.json({ success: true, message: `Verification for ${fieldPrefix} updated to ${status}` });
});

/**
 * NEW: Hoster Re-submission
 * Reset all status fields to 'pending' and enable account
 */
exports.resubmitHoster = asyncHandler(async (req, res) => {
  const userId = req.user.uid;

  const updateData = {
    status: 'pending',
    accountStatus: 'pending',
    'permissions.status': 'pending',
    is_active: true,
    onboardingStatus: 'submitted',
    updatedAt: new Date().toISOString()
  };

  await db.collection('users').doc(userId).set(updateData, { merge: true });

  // Update custom claims to unban/activate
  const user = await auth.getUser(userId);
  await auth.setCustomUserClaims(userId, {
    ...user.customClaims,
    isActive: true,
    banned: false
  });

  // Clear cache
  cache.del('/api/admin/stats');
  cache.del('/api/admin/users');

  res.json({ success: true, message: 'Application re-submitted successfully' });
});

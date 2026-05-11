const { auth, db } = require('../config/firebase-config');

// Create a new admin
exports.createAdmin = async (req, res) => {
  const { email, password, phoneNumber, name } = req.body;
  try {
    const userRecord = await auth.createUser({
      email,
      password,
      phoneNumber,
      displayName: name,
    });

    // Set custom claims
    await auth.setCustomUserClaims(userRecord.uid, { role: 'admin' });

    // Add to admins collection for easy lookup if needed
    await db.collection('admins').doc(userRecord.uid).set({
      email,
      name,
      phoneNumber,
      role: 'admin',
      createdAt: new Date().toISOString()
    });

    res.status(201).json({ success: true, message: 'Admin created successfully', uid: userRecord.uid });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// List all admins
exports.getAllAdmins = async (req, res) => {
  try {
    const adminsSnapshot = await db.collection('admins').get();
    const admins = [];
    adminsSnapshot.forEach(doc => admins.push({ id: doc.id, ...doc.data() }));
    res.json({ success: true, admins });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// Remove an admin
exports.removeAdmin = async (req, res) => {
  const { adminId } = req.params;
  try {
    // Delete from Auth
    await auth.deleteUser(adminId);

    // Delete from Firestore
    await db.collection('admins').doc(adminId).delete();

    res.json({ success: true, message: 'Admin removed successfully' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

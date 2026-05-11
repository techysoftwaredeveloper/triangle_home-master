const { auth, db } = require('../firebase-config');

const promoteToSuperAdmin = async (uid, email) => {
  try {
    // Set custom claims
    await auth.setCustomUserClaims(uid, { role: 'superadmin' });

    // Add to admins collection
    await db.collection('admins').doc(uid).set({
      email: email,
      role: 'superadmin',
      updatedAt: new Date().toISOString()
    });

    console.log(`Successfully promoted ${email} to superadmin`);
  } catch (error) {
    console.error('Error promoting to superadmin:', error);
  }
};

// Usage: node scripts/setup-superadmin.js <UID> <EMAIL>
const args = process.argv.slice(2);
if (args.length < 2) {
  console.log('Usage: node scripts/setup-superadmin.js <UID> <EMAIL>');
  process.exit(1);
}

promoteToSuperAdmin(args[0], args[1]);

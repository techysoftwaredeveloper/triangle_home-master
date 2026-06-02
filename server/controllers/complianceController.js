const { db } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');

/**
 * FRAUD DETECTION ENGINE
 */
exports.checkFraudRisks = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const userDoc = await db.collection('users').doc(userId).get();

  if (!userDoc.exists) {
    return res.status(404).json({ success: false, error: 'User not found' });
  }

  const userData = userDoc.data();
  const verif = userData.verification || {};
  const risks = [];

  // 1. Check for Duplicate PAN
  if (verif.panNumber) {
    const dupPanSnap = await db.collection('users')
      .where('verification.panNumber', '==', verif.panNumber)
      .get();

    if (dupPanSnap.docs.length > 1) {
      risks.push({
        type: 'DUPLICATE_IDENTIFIER',
        severity: 'CRITICAL',
        description: 'PAN number is linked to multiple accounts'
      });
    }
  }

  // 2. Check for Duplicate Bank Account
  if (userData.bank_info?.accountNumber) {
    const dupBankSnap = await db.collection('users')
      .where('bank_info.accountNumber', '==', userData.bank_info.accountNumber)
      .get();

    if (dupBankSnap.docs.length > 1) {
      risks.push({
        type: 'DUPLICATE_BANK_AC',
        severity: 'HIGH',
        description: 'Bank account is linked to multiple accounts'
      });
    }
  }

  // 3. Check for Suspicious Activity Patterns
  const bookingSnap = await db.collection('bookings')
    .where('user_id', '==', userId)
    .where('status', '==', 'cancelled')
    .get();

  if (bookingSnap.docs.length > 5) {
    risks.push({
      type: 'ABUSIVE_CANCELLATION',
      severity: 'MEDIUM',
      description: 'High number of booking cancellations detected'
    });
  }

  // Update User Risk Profile
  await userDoc.ref.update({
    compliance: {
      risks,
      riskLevel: risks.length > 0 ? (risks.some(r => r.severity === 'CRITICAL') ? 'CRITICAL' : 'HIGH') : 'LOW',
      lastCheckedAt: new Date().toISOString()
    }
  });

  res.json({ success: true, riskLevel: userData.compliance?.riskLevel || 'LOW', risks });
});

/**
 * ADMIN: BULK COMPLIANCE AUDIT
 */
exports.getHighRiskUsers = asyncHandler(async (req, res) => {
  const highRiskSnap = await db.collection('users')
    .where('compliance.riskLevel', 'in', ['HIGH', 'CRITICAL'])
    .limit(50)
    .get();

  const users = [];
  highRiskSnap.forEach(doc => users.push({ id: doc.id, ...doc.data() }));

  res.json({ success: true, users });
});

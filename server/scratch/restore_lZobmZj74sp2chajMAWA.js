const { db } = require('../config/firebase-config');
const { reconcileOccupancy } = require('../controllers/propertyController');

async function restore() {
  const propertyId = 'lZobmZj74sp2chajMAWA';
  const propertyRef = db.collection('properties').doc(propertyId);
  
  console.log(`Restoring default values for property: ${propertyId}`);
  await propertyRef.update({
    monthlyRent: 7500,
    securityDeposit: 125000
  });

  // Run reconciliation
  const req = { params: { propertyId } };
  let responseData = null;
  const res = {
    json: (data) => {
      responseData = data;
    }
  };
  
  const runController = () => new Promise((resolve, reject) => {
    reconcileOccupancy(req, res, (err) => {
      reject(err || new Error('next() called'));
    });
    // Wait slightly
    setTimeout(() => {
      if (responseData) resolve(responseData);
    }, 1000);
  });

  const result = await runController();
  console.log('\nRestored Reconciliation Result:');
  console.log(`  Total Beds:      ${result.reconciled.totalBeds}`);
  console.log(`  Monthly Rent:    ₹${result.reconciled.monthlyRent}`);
  console.log(`  Security Deposit: ₹${result.reconciled.securityDeposit}`);
}

restore().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});

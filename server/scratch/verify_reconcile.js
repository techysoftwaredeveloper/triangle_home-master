const { db } = require('../config/firebase-config');
const { reconcileOccupancy } = require('../controllers/propertyController');

async function reconcileAll() {
  console.log('--- Starting Global Property Reconciliation Audit ---');
  
  const propertiesSnap = await db.collection('properties').get();
  console.log(`Found ${propertiesSnap.size} properties in database.`);

  for (const doc of propertiesSnap.docs) {
    const propertyId = doc.id;
    const propData = doc.data();
    console.log(`\nReconciling: [${propertyId}] ${propData.name || propData.title || 'Unnamed'}`);
    
    // Create mocked req/res and handle async resolution
    const runController = () => new Promise((resolve, reject) => {
      const req = { params: { propertyId } };
      const res = {
        json: (data) => {
          resolve(data);
        }
      };
      const next = (err) => {
        reject(err || new Error('next() called with error'));
      };
      reconcileOccupancy(req, res, next);
    });
    
    try {
      // Execute the reconciliation controller and await completion
      const responseData = await runController();
      if (responseData && responseData.success) {
        console.log(`  [SUCCESS]`);
        console.log(`    Total Beds:      ${responseData.reconciled.totalBeds}`);
        console.log(`    Occupied Beds:   ${responseData.reconciled.occupiedBeds}`);
        console.log(`    Available Beds:  ${responseData.reconciled.availableBeds}`);
        console.log(`    Reserved Beds:   ${responseData.reconciled.reservedBeds}`);
        console.log(`    Monthly Rent:    ₹${responseData.reconciled.monthlyRent}`);
        console.log(`    Security Deposit: ₹${responseData.reconciled.securityDeposit}`);
      } else {
        console.log(`  [FAILED] Controller did not return success response.`);
      }
    } catch (err) {
      console.error(`  [ERROR] Failed during execution:`, err.message || err);
    }
  }
}

reconcileAll().then(() => {
  console.log('\n--- Reconciliation Complete ---');
  process.exit(0);
}).catch(err => {
  console.error('Fatal error running reconciliation:', err);
  process.exit(1);
});

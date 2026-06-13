const { db, admin } = require('../config/firebase-config');
const { reconcileOccupancy } = require('../controllers/propertyController');

async function testPricing() {
  const propertyId = 'lZobmZj74sp2chajMAWA';
  console.log(`Setting up different rent/deposit amounts on beds for property: ${propertyId}`);

  // Fetch flat beds
  const flatBedsSnap = await db.collection('beds')
      .where('propertyId', '==', propertyId)
      .get();

  const bedsDocs = flatBedsSnap.docs;
  if (bedsDocs.length < 3) {
    console.error('Need at least 3 beds to perform pricing algorithm test');
    return;
  }

  // Bed 0: Available, Rent: 8500, Deposit: 15000
  // Bed 1: Available, Rent: 7200, Deposit: 20000
  // Bed 2: Available, Rent: 7200, Deposit: 18000 (Expected choice because rent is 7200 and deposit is 18000 < 20000)
  // Bed 3: Occupied, Rent: 6000, Deposit: 10000 (Occupied, so it should be ignored for available candidates, but used as fallback if none available)
  
  const testBedsData = [
    { status: 'available', monthlyRent: 8500, securityDeposit: 15000 },
    { status: 'available', monthlyRent: 7200, securityDeposit: 20000 },
    { status: 'available', monthlyRent: 7200, securityDeposit: 18000 },
    { status: 'occupied', monthlyRent: 6000, securityDeposit: 10000 }
  ];

  // We also have Bed 4 and Bed 5, we can leave them available with no rent (0)
  
  // Apply updates to flat and nested beds
  const batch = db.batch();
  for (let i = 0; i < bedsDocs.length; i++) {
    const doc = bedsDocs[i];
    const data = testBedsData[i] || { status: 'available', monthlyRent: 0, securityDeposit: 0 };
    
    // Flat bed
    batch.update(doc.ref, data);
    
    // Property subcollection bed
    const propBedRef = db.doc(`properties/${propertyId}/beds/${doc.id}`);
    batch.update(propBedRef, data);
    
    // Room subcollection bed
    const roomBedRef = db.doc(`properties/${propertyId}/rooms/${doc.data().roomId}/beds/${doc.id}`);
    batch.update(roomBedRef, data);
  }

  await batch.commit();
  console.log('Successfully updated test bed configurations.');

  // We wrap in a promise to await the controller
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

  const result = await runController();
  console.log('\nReconciliation Result:');
  console.log(`  Total Beds:      ${result.reconciled.totalBeds} (Expected: 6)`);
  console.log(`  Occupied Beds:   ${result.reconciled.occupiedBeds} (Expected: 1)`);
  console.log(`  Available Beds:  ${result.reconciled.availableBeds} (Expected: 5)`);
  console.log(`  Monthly Rent:    ₹${result.reconciled.monthlyRent} (Expected: 7200)`);
  console.log(`  Security Deposit: ₹${result.reconciled.securityDeposit} (Expected: 18000)`);

  // Now, let's test if all beds are occupied (fallback to all beds)
  console.log('\nUpdating all beds to occupied to test fallback behavior...');
  const batch2 = db.batch();
  for (let i = 0; i < bedsDocs.length; i++) {
    const doc = bedsDocs[i];
    batch2.update(doc.ref, { status: 'occupied' });
    batch2.update(db.doc(`properties/${propertyId}/beds/${doc.id}`), { status: 'occupied' });
    batch2.update(db.doc(`properties/${propertyId}/rooms/${doc.data().roomId}/beds/${doc.id}`), { status: 'occupied' });
  }
  await batch2.commit();

  const result2 = await runController();
  console.log('\nReconciliation Result (All Occupied):');
  console.log(`  Total Beds:      ${result2.reconciled.totalBeds} (Expected: 6)`);
  console.log(`  Occupied Beds:   ${result2.reconciled.occupiedBeds} (Expected: 6)`);
  console.log(`  Available Beds:  ${result2.reconciled.availableBeds} (Expected: 0)`);
  console.log(`  Monthly Rent:    ₹${result2.reconciled.monthlyRent} (Expected: 6000)`);
  console.log(`  Security Deposit: ₹${result2.reconciled.securityDeposit} (Expected: 10000)`);

  // Clean up: restore beds status to available and remove rent data to not corrupt developer database
  console.log('\nRestoring database state to original...');
  const batch3 = db.batch();
  for (let i = 0; i < bedsDocs.length; i++) {
    const doc = bedsDocs[i];
    const cleanData = { status: 'available', monthlyRent: admin.firestore.FieldValue.delete(), securityDeposit: admin.firestore.FieldValue.delete() };
    batch3.update(doc.ref, cleanData);
    batch3.update(db.doc(`properties/${propertyId}/beds/${doc.id}`), cleanData);
    batch3.update(db.doc(`properties/${propertyId}/rooms/${doc.data().roomId}/beds/${doc.id}`), cleanData);
  }
  await batch3.commit();

  // Final reconciliation to restore original stats
  await runController();
  console.log('Database restored.');
}

testPricing().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});

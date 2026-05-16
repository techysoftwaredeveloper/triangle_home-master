const { db } = require('../config/firebase-config');

const locations = [
  {
    state: "Kerala",
    cities: ["Kozhikode", "Malappuram", "Kochi", "Trivandrum", "Thrissur", "Kannur"]
  },
  {
    state: "Karnataka",
    cities: ["Bangalore", "Mangalore", "Mysore", "Hubli", "Belgaum"]
  },
  {
    state: "Tamil Nadu",
    cities: ["Chennai", "Coimbatore", "Madurai", "Salem", "Trichy"]
  },
  {
    state: "Maharashtra",
    cities: ["Mumbai", "Pune", "Nagpur", "Nashik", "Aurangabad"]
  },
  {
    state: "Delhi",
    cities: ["New Delhi", "North Delhi", "South Delhi"]
  },
  {
    state: "Telangana",
    cities: ["Hyderabad", "Warangal", "Nizamabad"]
  }
];

async function seedLocations() {
  console.log('🌱 Seeding major Indian states and cities...');
  const batch = db.batch();

  for (const loc of locations) {
    const stateRef = db.collection('locations').doc(loc.state);
    batch.set(stateRef, {
      name: loc.state,
      cities: loc.cities,
      updatedAt: new Date().toISOString()
    });
  }

  await batch.commit();
  console.log('✅ Seeding complete!');
  process.exit(0);
}

seedLocations().catch(err => {
  console.error('❌ Seeding failed:', err);
  process.exit(1);
});

const { db } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Get all states and their cities
 */
exports.getAllLocations = asyncHandler(async (req, res) => {
    const snapshot = await db.collection('locations').orderBy('name').get();
    const locations = [];
    snapshot.forEach(doc => {
        locations.push(doc.data());
    });
    res.json({ success: true, locations });
});

/**
 * Get only a list of major cities (flattened)
 */
exports.getMajorCities = asyncHandler(async (req, res) => {
    const snapshot = await db.collection('locations').get();
    let cities = [];
    snapshot.forEach(doc => {
        cities = [...cities, ...doc.data().cities];
    });
    // Return unique sorted cities
    const uniqueCities = [...new Set(cities)].sort();
    res.json({ success: true, cities: uniqueCities });
});

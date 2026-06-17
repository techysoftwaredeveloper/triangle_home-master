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

/**
 * Get localities for a city enriched with Hub info (Colleges/Industries)
 */
exports.getLocalitiesByCity = asyncHandler(async (req, res) => {
    const { city } = req.params;
    if (!city) {
        return res.status(400).json({ success: false, error: 'City is required' });
    }

    const cityLower = city.toLowerCase().trim();

    try {
        // Try fetching from dedicated localities sub-collection
        const snapshot = await db.collection('cities').doc(cityLower).collection('localities').get();

        let localities = [];
        snapshot.forEach(doc => {
            localities.push({ name: doc.id, ...doc.data() });
        });

        // Fallback/Sample Data for key cities if no Firestore data exists
        if (localities.length === 0) {
            localities = getFallbackLocalities(cityLower);
        }

        res.json({
            success: true,
            city,
            localities: localities.sort((a, b) => a.name.localeCompare(b.name))
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

function getFallbackLocalities(city) {
    const fallback = {
        'kochi': [
            { name: 'Kalamassery', hub: 'CUSAT, Model Engineering College', type: 'College' },
            { name: 'Kakkanad', hub: 'Infopark, SmartCity, Rajagiri College', type: 'Industrial/College' },
            { name: 'Edappally', hub: 'Amrita Hospital, Lulu Mall Area', type: 'College/Commercial' },
            { name: 'Aluva', hub: 'UC College, Industrial Belt', type: 'College/Industrial' },
            { name: 'Thrikkakara', hub: 'Bharata Mata College', type: 'College' },
            { name: 'Vytila', hub: 'Mobility Hub, Commercial Center', type: 'Commercial/Hub' }
        ],
        'bangalore': [
            { name: 'Koramangala', hub: 'St. Johns Medical College, Startup Hub', type: 'College/Industrial' },
            { name: 'Whitefield', hub: 'ITPL, Hope Farm Industrial Area', type: 'Industrial' },
            { name: 'Electronic City', hub: 'Infosys, Wipro, PES University', type: 'Industrial/College' },
            { name: 'HSR Layout', hub: 'NIFT Bangalore, Software Hub', type: 'College/Industrial' },
            { name: 'Marathahalli', hub: 'Tech Parks, Multiplexes', type: 'Industrial' },
            { name: 'Indiranagar', hub: 'Commercial Hub, Upscale Residential', type: 'Commercial' }
        ],
        'chennai': [
            { name: 'Guindy', hub: 'Anna University, Guindy Industrial Estate', type: 'College/Industrial' },
            { name: 'Taramani', hub: 'IIT Madras Research Park, TICEL Bio Park', type: 'Industrial/College' },
            { name: 'Adyar', hub: 'IIT Madras, CLRI', type: 'College/Industrial' },
            { name: 'OMR', hub: 'Tidel Park, SIPCOT, Satyabama University', type: 'Industrial/College' },
            { name: 'Ambattur', hub: 'Industrial Estate, IT Parks', type: 'Industrial' }
        ],
        'kozhikode': [
            { name: 'Medical College', hub: 'Government Medical College Kozhikode', type: 'College' },
            { name: 'Pantheeramkavu', hub: 'Cyberpark, UL Cyberpark', type: 'Industrial' },
            { name: 'Mavoor Road', hub: 'Commercial Hub', type: 'Commercial' },
            { name: 'Nadakkavu', hub: 'Education Hub, Key Schools', type: 'College' }
        ],
        'hyderabad': [
            { name: 'Gachibowli', hub: 'Financial District, University of Hyderabad', type: 'Industrial/College' },
            { name: 'HITEC City', hub: 'Cyber Towers, Tech Hub', type: 'Industrial' },
            { name: 'Kukatpally', hub: 'JNTU Hyderabad', type: 'College' },
            { name: 'Madhapur', hub: 'Inorbit Mall Area, IT Hub', type: 'Industrial/Commercial' }
        ],
        'mumbai': [
            { name: 'Powai', hub: 'IIT Bombay, Hiranandani Business Park', type: 'College/Industrial' },
            { name: 'Andheri', hub: 'SEEPZ Industrial Area, MIDC', type: 'Industrial' },
            { name: 'Bandra', hub: 'BKC Business Hub', type: 'Industrial' },
            { name: 'Colaba', hub: 'Tourist Hub, South Mumbai Center', type: 'Commercial' }
        ]
    };

    return fallback[city] || [];
}

/**
 * Add a new city and locality
 */
exports.addLocation = asyncHandler(async (req, res) => {
    const { city, locality } = req.body;
    if (!city) {
        return res.status(400).json({ success: false, error: 'City is required' });
    }

    const cityTrimmed = city.trim();
    const cityLower = cityTrimmed.toLowerCase();

    // 1. Ensure city is registered in the `cities` collection
    await db.collection('cities').doc(cityLower).set({
        name: cityTrimmed,
        active: true,
        updatedAt: new Date().toISOString()
    }, { merge: true });

    // 2. If locality is provided, add it to the `localities` sub-collection under this city
    if (locality && locality.trim()) {
        const localityTrimmed = locality.trim();
        await db.collection('cities').doc(cityLower).collection('localities').doc(localityTrimmed).set({
            name: localityTrimmed,
            addedAt: new Date().toISOString()
        }, { merge: true });
    }

    res.status(201).json({ success: true, message: 'Location registered successfully' });
});

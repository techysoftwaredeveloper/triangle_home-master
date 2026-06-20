const { db } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');
const logger = require('../utils/logger');

/**
 * Get Personalized Property Recommendations for a user.
 * Scores properties based on housing preferences: city, budget, property type, and gender.
 */
exports.getRecommendedProperties = asyncHandler(async (req, res) => {
    const userId = req.user.uid;

    try {
        // 1. Fetch User Housing Preferences
        const userDoc = await db.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            return res.status(404).json({ success: false, error: 'User not found' });
        }

        const userData = userDoc.data();
        const preferences = userData.housing_preferences || {};

        // Extract preferences with defaults
        const prefCity = (preferences.preferredCity || '').toLowerCase().trim();
        const budgetMin = preferences.budgetMin || 0;
        const budgetMax = preferences.budgetMax || 100000;
        const lookingFor = preferences.lookingFor || []; // Array of types
        const userGender = (userData.info?.gender || '').toLowerCase().trim();

        if (!prefCity) {
            return res.json({
                success: true,
                count: 0,
                results: [],
                message: 'No preferred city set'
            });
        }

        // 2. Query properties in the preferred city
        // We use city_normalized for efficient filtering
        let query = db.collection('properties')
            .where('status', '==', 'approved')
            .where('city_normalized', '==', prefCity);

        const snapshot = await query.limit(50).get();
        let scoredResults = [];

        snapshot.forEach(doc => {
            const data = doc.data();
            const basicInfo = data.basicInfo || {};
            const price = parseInt(data.monthlyRent?.toString().replace(/,/g, '') || '0');
            const propertyType = (data.propertyType || '').toLowerCase();
            const propertyGender = (data.gender ||
                                    (data.propertyDetails && data.propertyDetails.gender) ||
                                    basicInfo.tenantType || '').toLowerCase().trim();

            let score = 0;

            // Scoring Logic:

            // A. Budget Match (Primary weight)
            if (price >= budgetMin && price <= budgetMax) {
                score += 50;
            } else if (price < budgetMin) {
                // If cheaper, still good but slightly lower weight
                score += 30;
            } else if (price > budgetMax && price <= budgetMax * 1.2) {
                // Within 20% stretch
                score += 10;
            }

            // B. Property Type Match
            if (lookingFor.length > 0) {
                const typeMatch = lookingFor.some(type =>
                    propertyType.includes(type.toLowerCase())
                );
                if (typeMatch) score += 30;
            }

            // C. Gender Match (Critical)
            if (userGender) {
                let genderCompatible = false;
                if (!propertyGender || propertyGender === 'anyone' || propertyGender === 'unisex') {
                    genderCompatible = true;
                    score += 10; // Neutral compatibility
                } else {
                    const g = userGender;
                    if (g === 'male' || g === 'man' || g === 'boy') {
                        if (propertyGender === 'men' || propertyGender === 'boys' || propertyGender.includes('man') || propertyGender.includes('boy')) {
                            genderCompatible = true;
                            score += 20;
                        }
                    } else if (g === 'female' || g === 'woman' || g === 'girl') {
                        if (propertyGender === 'women' || propertyGender === 'girls' || propertyGender.includes('woman') || propertyGender.includes('girl')) {
                            genderCompatible = true;
                            score += 20;
                        }
                    }
                }

                // If gender is definitely not a match, we penalize heavily or skip
                if (!genderCompatible && propertyGender !== 'anyone' && propertyGender !== 'unisex') {
                    return; // Skip this property
                }
            }

            // D. Rating Bonus
            const rating = parseFloat(data.rating || 4.0);
            score += (rating * 2);

            scoredResults.push({
                id: doc.id,
                title: basicInfo.collegeName || data.name || 'Property',
                location: `${data.locality || ''}, ${data.city || ''}`,
                price: price,
                rating: rating,
                reviewCount: parseInt(data.reviewCount || 0),
                image: data.images?.length > 0 ? data.images[0] : '',
                amenities: data.features || [],
                score: score,
                ...data
            });
        });

        // 3. Sort by score and return top 10
        scoredResults.sort((a, b) => b.score - a.score);
        const finalResults = scoredResults.slice(0, 10);

        res.json({
            success: true,
            count: finalResults.length,
            results: finalResults
        });

    } catch (error) {
        logger.error(`Recommendations failed: ${error.message}`);
        res.status(500).json({ success: false, error: 'Internal server error during recommendations' });
    }
});

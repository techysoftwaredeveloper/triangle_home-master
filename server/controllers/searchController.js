const { db } = require('../config/firebase-config');
const asyncHandler = require('../utils/asyncHandler');
const logger = require('../utils/logger');

/**
 * Robust Server-Side Search for Properties
 * Handles filtering by city, locality, room type, accommodation type, and college proximity.
 */
exports.searchProperties = asyncHandler(async (req, res) => {
    const {
        city,
        localities, // Expected as a comma-separated string or array
        college,
        accommodationType,
        roomType,
        tenantType,
        limit = 20,
        offset = 0
    } = req.query;

    try {
        let query = db.collection('properties');

        // 1. Primary Filter: City (Best for indexing)
        if (city) {
            query = query.where('city_normalized', '==', city.toLowerCase().trim());
        }

        // Note: Firestore has limitations on multiple 'where' clauses with different fields.
        // For production, we fetch by city and perform fine-grained filtering here.
        // In a more advanced setup, we would use Algolia or ElasticSearch.

        const snapshot = await query.get();
        let results = [];

        snapshot.forEach(doc => {
            const data = doc.data();
            const basicInfo = data.basicInfo || {};
            const propertyLocality = data.locality || '';
            const propertyCollege = basicInfo.collegeName || basicInfo.name || data.name || data.title || '';
            const propertyType = data.propertyType || '';
            const propertySharing = basicInfo.sharing || '';
            const propertyTenantType = basicInfo.tenantType || '';

            // Filter by Localities (OR condition)
            if (localities) {
                const localityList = Array.isArray(localities) ? localities : localities.split(',');
                const match = localityList.some(loc =>
                    propertyLocality.toLowerCase().includes(loc.trim().toLowerCase())
                );
                if (!match) return;
            }

            // Filter by College Name
            if (college && !propertyCollege.toLowerCase().includes(college.toLowerCase())) {
                return;
            }

            // Filter by Accommodation Type
            if (accommodationType) {
                const type = accommodationType.toLowerCase();
                if (type === 'apartments' && !propertyType.toLowerCase().includes('apartment') && !propertyType.toLowerCase().includes('flat')) {
                    return;
                }
                if (type === 'paying guest hostels' && !propertyType.toLowerCase().includes('pg') && !propertyType.toLowerCase().includes('hostel')) {
                    return;
                }
            }

            // Filter by Room Type / Sharing
            if (roomType && roomType !== 'Any' && !propertySharing.toLowerCase().includes(roomType.toLowerCase())) {
                return;
            }

            // Filter by Tenant Type
            if (tenantType && tenantType !== 'Anyone') {
                const propertyGender = (data.gender || 
                                        (data.propertyDetails && data.propertyDetails.gender) || 
                                        propertyTenantType || '').toLowerCase().trim();
                
                let isMatch = false;
                if (!propertyGender || propertyGender === 'anyone' || propertyGender === 'unisex') {
                    isMatch = true;
                } else {
                    const q = tenantType.toLowerCase().trim();
                    if (q === 'man' || q === 'men' || q === 'boys' || q === 'boy') {
                        isMatch = propertyGender === 'men' || 
                                  propertyGender === 'boys' || 
                                  propertyGender.includes('man') || 
                                  propertyGender.includes('men') || 
                                  propertyGender.includes('boy');
                    } else if (q === 'woman' || q === 'women' || q === 'girls' || q === 'girl') {
                        isMatch = propertyGender === 'women' || 
                                  propertyGender === 'girls' || 
                                  propertyGender.includes('woman') || 
                                  propertyGender.includes('women') || 
                                  propertyGender.includes('girl');
                    } else {
                        isMatch = propertyGender.includes(q) || q.includes(propertyGender);
                    }
                }
                if (!isMatch) return;
            }

            results.push({
                id: doc.id,
                title: propertyCollege || data.name || 'Property',
                location: `${propertyLocality}, ${data.city || ''}`,
                price: parseInt(data.monthlyRent?.toString().replace(/,/g, '') || '0'),
                rating: parseFloat(data.rating || 4.0),
                reviewCount: parseInt(data.reviewCount || 0),
                image: data.images?.length > 0 ? data.images[0] : '',
                amenities: data.features || [],
                ...data
            });
        });

        // Handle Pagination in memory for now (since we filtered in memory)
        const paginatedResults = results.slice(offset, offset + limit);

        res.json({
            success: true,
            count: results.length,
            results: paginatedResults
        });

    } catch (error) {
        logger.error(`Search failed: ${error.message}`);
        res.status(500).json({ success: false, error: 'Internal server error during search' });
    }
});

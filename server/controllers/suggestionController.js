const { db } = require('../config/firebase-config');
const { validationResult } = require('express-validator');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Get all suggestions for the authenticated user
 */
exports.getMySuggestions = asyncHandler(async (req, res) => {
    const userId = req.user.uid;
    const suggestionsSnapshot = await db.collection('property_suggestions')
        .where('suggester_id', '==', userId)
        .orderBy('createdAt', 'desc')
        .get();

    const suggestions = [];
    suggestionsSnapshot.forEach(doc => suggestions.push({ id: doc.id, ...doc.data() }));

    res.json({ success: true, suggestions });
});

/**
 * Submit a new property suggestion
 */
exports.createSuggestion = asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, errors: errors.array() });
    }

    const userId = req.user.uid;
    const suggestionData = {
        ...req.body,
        suggester_id: userId,
        status: 'pending',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    };

    const docRef = await db.collection('property_suggestions').add(suggestionData);

    res.status(201).json({
        success: true,
        message: 'Suggestion submitted successfully',
        id: docRef.id
    });
});

/**
 * Admin: Update suggestion status
 */
exports.updateSuggestionStatus = asyncHandler(async (req, res) => {
    const { suggestionId } = req.params;
    const { status, statusText } = req.body;

    const validStatuses = ['pending', 'under_review', 'contacted', 'approved', 'rejected'];
    if (!validStatuses.includes(status)) {
        return res.status(400).json({ success: false, error: 'Invalid status' });
    }

    await db.collection('property_suggestions').doc(suggestionId).update({
        status,
        status_text: statusText,
        updatedAt: new Date().toISOString()
    });

    res.json({ success: true, message: `Suggestion status updated to ${status}` });
});

/**
 * Admin: Convert suggestion to hoster request and property listing
 * Optimized with Firestore Batch for atomicity and speed
 */
exports.convertToApprovals = asyncHandler(async (req, res) => {
    const { suggestionId } = req.params;
    console.log(`Starting conversion for suggestion: ${suggestionId}`);

    const suggestionDoc = await db.collection('property_suggestions').doc(suggestionId).get();
    if (!suggestionDoc.exists) {
        return res.status(404).json({ success: false, error: 'Suggestion not found' });
    }

    const data = suggestionDoc.data();
    const batch = db.batch();

    // 1. Identify/Prepare Hoster
    let hosterId;
    let userQuery = null;

    if (data.owner_email) {
        userQuery = await db.collection('users').where('info.email', '==', data.owner_email).limit(1).get();
    } else if (data.owner_phone) {
        userQuery = await db.collection('users').where('info.phoneNumber', '==', data.owner_phone).limit(1).get();
    }

    if (userQuery && !userQuery.empty) {
        hosterId = userQuery.docs[0].id;
        const userData = userQuery.docs[0].data();
        if (userData.role !== 'admin' && userData.role !== 'superadmin') {
            batch.update(db.collection('users').doc(hosterId), {
                role: 'hoster',
                status: 'pending',
                accountStatus: 'pending',
                'info.name': data.owner_name || userData.info?.name,
                'info.isFromSuggestion': true,
                updatedAt: new Date().toISOString()
            });
        }
    } else {
        const newUserRef = db.collection('users').doc();
        hosterId = newUserRef.id;
        batch.set(newUserRef, {
            role: 'hoster',
            status: 'pending',
            accountStatus: 'pending',
            is_active: true,
            info: {
                name: data.owner_name,
                email: data.owner_email,
                phoneNumber: data.owner_phone,
                isFromSuggestion: true,
                suggestedByName: data.suggester_name
            },
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        });
    }

    // 2. Prepare Property Listing
    const newPropertyRef = db.collection('properties').doc();
    batch.set(newPropertyRef, {
        hosterId: hosterId,
        hosterName: data.owner_name || 'New Hoster', // Ensure no undefined values
        name: data.business_name,
        location: data.business_address,
        category: data.category || 'Accommodation',
        status: 'pending',
        description: data.ambiance || 'Suggested property',
        amenities: data.amenities ? data.amenities.toString().split(',').map(s => s.trim()) : [],
        monthlyRent: data.monthly_rent || 'N/A',
        securityDeposit: data.deposit || 'N/A',
        suggestedById: data.suggester_id || null,
        suggestedByName: data.suggester_name || 'Anonymous',
        isFromSuggestion: true,
        tags: ['Converted Lead', data.category || 'Accommodation'],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    });

    // 3. Update Suggestion status
    batch.update(db.collection('property_suggestions').doc(suggestionId), {
        status: 'converted',
        convertedPropertyId: newPropertyRef.id,
        convertedHosterId: hosterId,
        updatedAt: new Date().toISOString()
    });

    console.log('Committing conversion batch...');
    await batch.commit();
    console.log('Conversion successful');

    res.json({
        success: true,
        message: 'Successfully converted to approvals',
        propertyId: newPropertyRef.id,
        hosterId: hosterId
    });
});

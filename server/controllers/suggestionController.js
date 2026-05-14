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

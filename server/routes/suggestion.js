const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const suggestionController = require('../controllers/suggestionController');
const { verifyToken, isAdmin } = require('../middleware/auth');

router.use(verifyToken);

// User routes
router.get('/my', suggestionController.getMySuggestions);
router.post('/', [
    body('business_name').notEmpty().trim(),
    body('business_address').notEmpty().trim(),
    body('category').notEmpty().trim()
], suggestionController.createSuggestion);

// Admin routes
router.patch('/:suggestionId/status', isAdmin, suggestionController.updateSuggestionStatus);

module.exports = router;

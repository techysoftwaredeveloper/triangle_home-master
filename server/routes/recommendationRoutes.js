const express = require('express');
const router = express.Router();
const recommendationController = require('../controllers/recommendationController');
const { optionalVerifyToken } = require('../middleware/auth');

// Recommendations can support guest users with optional authentication
router.get('/', optionalVerifyToken, recommendationController.getRecommendedProperties);

module.exports = router;

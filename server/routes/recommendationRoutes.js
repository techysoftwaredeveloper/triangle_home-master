const express = require('express');
const router = express.Router();
const recommendationController = require('../controllers/recommendationController');
const { verifyToken } = require('../middleware/auth');

// Recommendations require authentication to access user preferences
router.get('/', verifyToken, recommendationController.getRecommendedProperties);

module.exports = router;

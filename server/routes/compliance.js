const express = require('express');
const router = express.Router();
const complianceController = require('../controllers/complianceController');
const authMiddleware = require('../middleware/authMiddleware');

// User self-check or automated check
router.get('/check-risk/:userId', authMiddleware, complianceController.checkFraudRisks);

// Admin-only high risk report
router.get('/high-risk-users', authMiddleware, complianceController.getHighRiskUsers);

module.exports = router;

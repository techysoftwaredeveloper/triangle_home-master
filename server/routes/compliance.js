const express = require('express');
const router = express.Router();
const complianceController = require('../controllers/complianceController');
const { verifyToken } = require('../middleware/auth');

// User self-check or automated check
router.get('/check-risk/:userId', verifyToken, complianceController.checkFraudRisks);

// Admin-only high risk report
router.get('/high-risk-users', verifyToken, complianceController.getHighRiskUsers);

module.exports = router;

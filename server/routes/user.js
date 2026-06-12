const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { verifyToken } = require('../middleware/auth');

router.use(verifyToken);

// Hoster Re-submission (Self-action)
router.post('/resubmit-hoster', adminController.resubmitHoster);

module.exports = router;

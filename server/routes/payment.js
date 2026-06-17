const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { verifyToken } = require('../middleware/auth');
const { sensitiveLimiter } = require('../middleware/rateLimiter');

router.use(verifyToken);

router.post('/record', sensitiveLimiter, paymentController.recordPayment);

module.exports = router;

const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const authMiddleware = require('../middleware/authMiddleware');
const { body } = require('express-validator');

// Create Razorpay Order
router.post(
  '/create-order',
  authMiddleware,
  [
    body('propertyId').notEmpty(),
    body('bookingId').notEmpty(),
    body('type').isIn(['reservationFee', 'deposit', 'firstMonthRent']),
  ],
  paymentController.createOrder
);

// Verify Razorpay Payment
router.post(
  '/verify',
  authMiddleware,
  [
    body('razorpay_order_id').notEmpty(),
    body('razorpay_payment_id').notEmpty(),
    body('razorpay_signature').notEmpty(),
    body('bookingId').notEmpty(),
  ],
  paymentController.verifyPayment
);

module.exports = router;

const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const bookingController = require('../controllers/bookingController');
const { verifyToken } = require('../middleware/auth');

router.use(verifyToken);

router.get('/my', bookingController.getMyBookings);

router.post('/', [
    body('propertyId').notEmpty(),
    body('price').isNumeric(),
    body('type').notEmpty(),
    body('tenantDetails').isArray()
], bookingController.createBooking);

router.patch('/:bookingId/status', bookingController.updateBookingStatus);

module.exports = router;

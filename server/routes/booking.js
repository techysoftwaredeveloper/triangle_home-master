const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const bookingController = require('../controllers/bookingController');
const inventoryController = require('../controllers/inventoryController');
const { verifyToken } = require('../middleware/auth');

router.use(verifyToken);

router.get('/my', bookingController.getMyBookings);

router.post('/lock-bed', inventoryController.lockBed);

router.post('/', [
    body('propertyId').notEmpty(),
    body('price').isNumeric(),
    body('type').notEmpty(),
    body('tenantDetails').isArray()
], bookingController.createBooking);

router.patch('/:bookingId/status', bookingController.updateBookingStatus);

module.exports = router;

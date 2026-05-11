const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { verifyToken, isAdmin } = require('../middleware/auth');

router.use(verifyToken);
router.use(isAdmin);

router.get('/stats', adminController.getStats);
router.get('/users', adminController.getAllUsers);
router.get('/properties', adminController.getAllProperties);
router.get('/bookings', adminController.getAllBookings);
router.post('/users/toggle-status', adminController.toggleUserStatus);
router.patch('/properties/:propertyId/status', adminController.updatePropertyStatus);
router.post('/hosters/:hosterId/approve', adminController.approveHoster);

module.exports = router;

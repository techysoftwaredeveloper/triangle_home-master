const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { verifyToken, isAdmin } = require('../middleware/auth');

const { cacheMiddleware } = require('../utils/cache');

router.use(verifyToken);

// Hoster Re-submission (Self-action, no isAdmin check)
router.post('/resubmit-hoster', adminController.resubmitHoster);

router.use(isAdmin);

router.get('/stats', cacheMiddleware(300), adminController.getStats);
router.get('/users', cacheMiddleware(600), adminController.getAllUsers);
router.get('/properties', cacheMiddleware(300), adminController.getAllProperties);
router.get('/bookings', cacheMiddleware(300), adminController.getAllBookings);
router.post('/users/toggle-status', adminController.toggleUserStatus);
router.patch('/users/:userId/role', adminController.updateUserRole);
router.patch('/properties/:propertyId/status', adminController.updatePropertyStatus);
router.post('/hosters/:hosterId/approve', adminController.approveHoster);
router.patch('/suggestions/:id/status', adminController.updateSuggestionStatus);
router.patch('/reports/:id/status', adminController.updateReportStatus);
router.delete('/users/:userId', adminController.deleteUser);
router.delete('/bookings/:bookingId', adminController.deleteBooking);
router.post('/approvals/cleanup', adminController.cleanupIncompleteApprovals);

// Verification Management
router.get('/verifications/pending', adminController.getPendingVerifications);
router.patch('/users/:userId/verification', adminController.updateVerificationStatus);

module.exports = router;

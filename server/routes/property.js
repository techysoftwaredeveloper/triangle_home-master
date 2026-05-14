const express = require('express');
const router = express.Router();
const propertyController = require('../controllers/propertyController');
const { verifyToken } = require('../middleware/auth');

router.use(verifyToken);

router.post('/', propertyController.createProperty);
router.post('/:propertyId/reconcile', propertyController.reconcileOccupancy);

module.exports = router;

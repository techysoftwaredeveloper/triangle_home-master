const express = require('express');
const router = express.Router();
const inventoryController = require('../controllers/inventoryController');
const { verifyToken } = require('../middleware/auth');

router.use(verifyToken);

// Bed Actions
router.patch('/bed/:bedId/status', inventoryController.updateBedStatus);
router.delete('/bed/:bedId', inventoryController.deleteBed);

// Room Actions
router.patch('/room/:roomId/status', inventoryController.updateRoomStatus);
router.delete('/room/:roomId', inventoryController.deleteRoom);

// Floor Actions
router.patch('/floor/:floorId/status', inventoryController.updateFloorStatus);
router.delete('/floor/:floorId', inventoryController.deleteFloor);

module.exports = router;

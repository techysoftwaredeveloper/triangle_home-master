const express = require('express');
const router = express.Router();
const maintenanceController = require('../controllers/maintenanceController');
// Note: In production, this would be protected by a static secret key or App Check
// only callable by Cloud Scheduler.

router.get('/run-janitor', maintenanceController.runMaintenanceTasks);

module.exports = router;

const express = require('express');
const router = express.Router();
const locationController = require('../controllers/locationController');

// Public routes (no token required for city browsing)
router.get('/all', locationController.getAllLocations);
router.get('/major-cities', locationController.getMajorCities);
router.get('/:city/localities', locationController.getLocalitiesByCity);
router.post('/add', locationController.addLocation);

module.exports = router;

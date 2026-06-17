const express = require('express');
const router = express.Router();
const searchController = require('../controllers/searchController');

// Search is public
router.get('/properties', searchController.searchProperties);

module.exports = router;

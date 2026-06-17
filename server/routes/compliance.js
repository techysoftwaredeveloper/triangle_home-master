const express = require('express');
const router = express.Router();
const escrowController = require('../controllers/escrowController');
const { verifyToken } = require('../middleware/auth');

router.use(verifyToken);

router.post('/escrow', escrowController.createEscrow);
router.post('/payout/request', escrowController.requestPayout);

module.exports = router;

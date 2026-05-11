const express = require('express');
const router = express.Router();
const superadminController = require('../controllers/superadminController');
const { verifyToken, isSuperAdmin } = require('../middleware/auth');

router.use(verifyToken);
router.use(isSuperAdmin);

router.post('/admins', superadminController.createAdmin);
router.get('/admins', superadminController.getAllAdmins);
router.delete('/admins/:adminId', superadminController.removeAdmin);

module.exports = router;

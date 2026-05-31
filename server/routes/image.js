const express = require('express');
const router = express.Router();
const multer = require('multer');
const { optimizeImage, generateThumbnail } = require('../utils/imageHandler');
const { verifyToken } = require('../middleware/auth');

const upload = multer({ storage: multer.memoryStorage() });

/**
 * Endpoint to optimize an image before uploading to Firebase
 * Useful for mobile clients to reduce bandwidth
 */
router.post('/optimize', verifyToken, upload.single('image'), async (req, res) => {
    if (!req.file) {
        return res.status(400).json({ success: false, error: 'No image provided' });
    }

    try {
        const optimizedBuffer = await optimizeImage(req.file.buffer);

        res.set('Content-Type', 'image/jpeg');
        res.send(optimizedBuffer);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

/**
 * Generates a thumbnail version of the image
 */
router.post('/thumbnail', verifyToken, upload.single('image'), async (req, res) => {
    if (!req.file) {
        return res.status(400).json({ success: false, error: 'No image provided' });
    }

    try {
        const thumbBuffer = await generateThumbnail(req.file.buffer);

        res.set('Content-Type', 'image/webp');
        res.send(thumbBuffer);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

module.exports = router;

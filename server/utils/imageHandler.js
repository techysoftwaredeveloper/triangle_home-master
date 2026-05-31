const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

/**
 * Optimizes an image buffer for web use
 * @param {Buffer} buffer Original image buffer
 * @param {number} width Target width (optional)
 * @returns {Buffer} Optimized image buffer
 */
exports.optimizeImage = async (buffer, width = 800) => {
    try {
        return await sharp(buffer)
            .resize({ width, withoutEnlargement: true })
            .jpeg({ quality: 80, mozjpeg: true })
            .toBuffer();
    } catch (error) {
        console.error('Image optimization error:', error);
        return buffer;
    }
};

/**
 * Generates a thumbnail for an image buffer
 * @param {Buffer} buffer Original image buffer
 * @returns {Buffer} Thumbnail buffer
 */
exports.generateThumbnail = async (buffer) => {
    try {
        return await sharp(buffer)
            .resize(200, 200, { fit: 'cover' })
            .webp({ quality: 70 })
            .toBuffer();
    } catch (error) {
        console.error('Thumbnail generation error:', error);
        return buffer;
    }
};

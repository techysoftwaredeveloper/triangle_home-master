const { admin } = require('../config/firebase-config');

/**
 * Middleware to verify Firebase App Check tokens.
 */
const verifyAppCheck = async (req, res, next) => {
    const appCheckToken = req.header('X-Firebase-AppCheck');

    if (!appCheckToken) {
        if (process.env.NODE_ENV !== 'production') {
            return next();
        }
        return res.status(401).json({
            success: false,
            error: 'Unauthorized: App Check token missing'
        });
    }

    try {
        const claims = await admin.appCheck().verifyToken(appCheckToken);
        req.appCheck = claims;
        next();
    } catch (err) {
        console.error('App Check Error:', err.message);
        res.status(401).json({
            success: false,
            error: 'Unauthorized: Invalid App Check token'
        });
    }
};

module.exports = verifyAppCheck;

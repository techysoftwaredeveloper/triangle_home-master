const rateLimit = require('express-rate-limit');

/**
 * Standard Rate Limiter for API protection
 */
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per window
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        success: false,
        error: 'Too many requests from this IP, please try again after 15 minutes'
    }
});

/**
 * Stricter Limiter for sensitive endpoints
 */
const sensitiveLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 10,
    message: {
        success: false,
        error: 'Too many attempts. Please try again later.'
    }
});

module.exports = { apiLimiter, sensitiveLimiter };

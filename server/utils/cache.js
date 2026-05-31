const NodeCache = require('node-cache');

// Initialize cache with 5 minutes TTL by default
const cache = new NodeCache({ stdTTL: 300, checkperiod: 60 });

/**
 * Cache middleware for Express routes
 * @param {number} ttl Time to live in seconds
 */
const cacheMiddleware = (ttl) => {
    return (req, res, next) => {
        // Only cache GET requests
        if (req.method !== 'GET') return next();

        const key = req.originalUrl || req.url;
        const cachedResponse = cache.get(key);

        if (cachedResponse) {
            console.log(`Cache Hit: ${key}`);
            return res.json(cachedResponse);
        }

        // Override res.json to store the response in cache
        res.originalJson = res.json;
        res.json = (body) => {
            cache.set(key, body, ttl);
            res.originalJson(body);
        };

        next();
    };
};

module.exports = {
    cache,
    cacheMiddleware
};

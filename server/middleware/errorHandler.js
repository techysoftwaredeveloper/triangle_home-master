/**
 * Global Error Handling Middleware
 */
const errorHandler = (err, req, res, next) => {
    console.error(`[ERROR] ${new Date().toISOString()}: ${err.stack}`);

    // Map specific errors to status codes
    const statusCode = err.statusCode || 500;
    const message = err.message || 'Internal Server Error';

    res.status(statusCode).json({
        success: false,
        error: {
            message,
            code: err.code || 'INTERNAL_ERROR',
            details: process.env.NODE_ENV === 'development' ? err.stack : undefined
        }
    });
};

module.exports = errorHandler;

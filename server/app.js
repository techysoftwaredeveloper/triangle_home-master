const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const compression = require('compression');
const logger = require('./utils/logger');
const { apiLimiter } = require('./middleware/rateLimiter');
const verifyAppCheck = require('./middleware/appCheck');
const errorHandler = require('./middleware/errorHandler');
const adminRoutes = require('./routes/admin');
const superadminRoutes = require('./routes/superadmin');
const bookingRoutes = require('./routes/booking');
const propertyRoutes = require('./routes/property');
const suggestionRoutes = require('./routes/suggestion');
const locationRoutes = require('./routes/location');
const imageRoutes = require('./routes/image');
const paymentRoutes = require('./routes/payment');
const maintenanceRoutes = require('./routes/maintenance');
const complianceRoutes = require('./routes/compliance');
const searchRoutes = require('./routes/search');
const recommendationRoutes = require('./routes/recommendationRoutes');

const app = express();

app.use(morgan('combined', { stream: { write: message => logger.http(message.trim()) } }));

// Production Security Headers
app.use(helmet({
    contentSecurityPolicy: process.env.NODE_ENV === 'production' ? undefined : false,
    crossOriginEmbedderPolicy: process.env.NODE_ENV === 'production' ? true : false,
}));

app.use(compression());

// CORS Configuration
const allowedOrigins = process.env.ALLOWED_ORIGINS
    ? process.env.ALLOWED_ORIGINS.split(',')
    : ['*'];

app.use(cors({
    origin: (origin, callback) => {
        if (!origin || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Firebase-AppCheck'],
    credentials: true
}));

app.use(verifyAppCheck);
app.use(apiLimiter);
app.use(bodyParser.json());

// Routes
app.use('/api/admin', adminRoutes);
app.use('/api/superadmin', superadminRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/properties', propertyRoutes);
app.use('/api/suggestions', suggestionRoutes);
app.use('/api/locations', locationRoutes);
app.use('/api/images', imageRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/maintenance', maintenanceRoutes);
app.use('/api/compliance', complianceRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/recommendations', recommendationRoutes);

app.get('/', (req, res) => {
  res.send('Triangle Home Admin API is running...');
});

// Health Checks
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'UP', timestamp: new Date().toISOString() });
});

app.get('/api/readiness', (req, res) => {
  // Add actual readiness logic here (e.g. check Firebase connection)
  res.status(200).json({ status: 'READY' });
});

// 404 Handler
app.use((req, res, next) => {
    res.status(404).json({
        success: false,
        error: `Route not found: ${req.method} ${req.originalUrl}`
    });
});

app.use(errorHandler);

module.exports = app;

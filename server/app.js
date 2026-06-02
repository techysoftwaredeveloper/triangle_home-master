const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const compression = require('compression');
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

const app = express();

app.use(morgan('dev'));
app.use(helmet());
app.use(compression());
app.use(cors());
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

app.get('/', (req, res) => {
  res.send('Triangle Home Admin API is running...');
});

app.use(errorHandler);

module.exports = app;

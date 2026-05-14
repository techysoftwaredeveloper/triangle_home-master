const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const { apiLimiter } = require('./middleware/rateLimiter');
const verifyAppCheck = require('./middleware/appCheck');
const errorHandler = require('./middleware/errorHandler');
const adminRoutes = require('./routes/admin');
const superadminRoutes = require('./routes/superadmin');
const bookingRoutes = require('./routes/booking');
const propertyRoutes = require('./routes/property');
const suggestionRoutes = require('./routes/suggestion');

const app = express();

app.use(morgan('dev'));
app.use(helmet());
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

app.get('/', (req, res) => {
  res.send('Triangle Home Admin API is running...');
});

app.use(errorHandler);

module.exports = app;

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const adminRoutes = require('./routes/admin');
const superadminRoutes = require('./routes/superadmin');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(bodyParser.json());

// Routes
app.use('/api/admin', adminRoutes);
app.use('/api/superadmin', superadminRoutes);

app.get('/', (req, res) => {
  res.send('Triangle Home Admin API is running...');
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on http://0.0.0.0:${PORT}`);
});

const app = require('./app');
const { validateEnv } = require('./utils/validator');

const PORT = process.env.PORT || 5000;

try {
  // Validate infrastructure before starting
  validateEnv();

  // Initialize cron jobs
  require('./scripts/cron');

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`
🚀 Backend Server Ready
-----------------------
Port: ${PORT}
Interface: 0.0.0.0
Mode: ${process.env.NODE_ENV || 'development'}
    `);
  });
} catch (error) {
  console.error('FAILED TO START SERVER:');
  console.error(error.message);
  process.exit(1);
}

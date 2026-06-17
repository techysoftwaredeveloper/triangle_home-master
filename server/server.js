const app = require('./app');
const { validateEnv } = require('./utils/validator');

const PORT = process.env.PORT || 5000;

try {
  // Validate infrastructure before starting
  validateEnv();

  // Initialize cron jobs
  require('./scripts/cron');

  const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`
🚀 Backend Server Ready
-----------------------
Port: ${PORT}
Interface: 0.0.0.0
Mode: ${process.env.NODE_ENV || 'development'}
    `);
  });

  // Graceful Shutdown
  const gracefulShutdown = () => {
    console.log('Stopping server...');
    server.close(() => {
      console.log('Server stopped.');
      process.exit(0);
    });

    // Force close after 10s
    setTimeout(() => {
      console.error('Could not close connections in time, forcefully shutting down');
      process.exit(1);
    }, 10000);
  };

  process.on('SIGTERM', gracefulShutdown);
  process.on('SIGINT', gracefulShutdown);
} catch (error) {
  console.error('FAILED TO START SERVER:');
  console.error(error.message);
  process.exit(1);
}

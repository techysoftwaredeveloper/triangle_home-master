/**
 * Backend Startup Validator
 * Ensures all required environment variables are present before starting
 */

const validateEnv = () => {
  const required = [
    // 'FIREBASE_SERVICE_ACCOUNT',
  ];

  const missing = required.filter(key => !process.env[key]);

  if (missing.length > 0) {
    throw new Error(`CRITICAL: Missing environment variables: ${missing.join(', ')}`);
  }

  if (process.env.NODE_ENV === 'production' && !process.env.FIREBASE_SERVICE_ACCOUNT) {
      console.warn('CRITICAL WARNING: Running in production without FIREBASE_SERVICE_ACCOUNT environment variable!');
  }
};

module.exports = { validateEnv };

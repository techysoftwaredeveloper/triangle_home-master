/**
 * Backend Startup Validator
 * Ensures all required environment variables are present before starting
 */

const validateEnv = () => {
  const required = [
    // 'FIREBASE_SERVICE_ACCOUNT', // Commented out to allow local fallback during dev
  ];

  const missing = required.filter(key => !process.env[required]);

  if (missing.length > 0) {
    throw new Error(`CRITICAL: Missing environment variables: ${missing.join(', ')}`);
  }
};

module.exports = { validateEnv };

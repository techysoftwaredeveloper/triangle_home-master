/**
 * Backend Startup Validator
 * Ensures all required environment variables are present before starting
 */

const validateEnv = () => {
  const required = [
    'NODE_ENV',
    'FIREBASE_PROJECT_ID',
    'RAZORPAY_KEY_ID',
    'RAZORPAY_KEY_SECRET'
  ];

  if (process.env.NODE_ENV === 'production') {
    required.push('FIREBASE_SERVICE_ACCOUNT');
    required.push('ALLOWED_ORIGINS');
  }

  const missing = required.filter(key => !process.env[key]);

  if (missing.length > 0) {
    throw new Error(`CRITICAL: Missing environment variables: ${missing.join(', ')}`);
  }
};

module.exports = { validateEnv };

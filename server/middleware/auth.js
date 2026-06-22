const { auth } = require('../config/firebase-config');

/**
 * Production-grade middleware to verify Firebase ID tokens
 * and enforce role-based access control.
 */
const verifyToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error: 'Unauthorized: No token provided'
    });
  }

  const token = authHeader.split('Bearer ')[1];

  try {
    const decodedToken = await auth.verifyIdToken(token);
    // Attach user info and roles to request
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      phoneNumber: decodedToken.phone_number,
      role: decodedToken.role || 'user', // Default to basic user if no claim
      banned: decodedToken.banned || false
    };

    if (req.user.banned) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: This account has been banned'
      });
    }

    next();
  } catch (error) {
    console.error('Error verifying token:', error.code);
    let message = 'Unauthorized: Invalid token';
    if (error.code === 'auth/id-token-expired') message = 'Unauthorized: Token expired';

    res.status(401).json({ success: false, error: message });
  }
};

/**
 * Optional middleware to verify Firebase ID tokens.
 * If token is present, it verifies it. If not, it just continues.
 */
const optionalVerifyToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(); // Continue without user
  }

  const token = authHeader.split('Bearer ')[1];
  if (token === 'null' || !token) {
    return next(); // Continue without user
  }

  try {
    const decodedToken = await auth.verifyIdToken(token);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      phoneNumber: decodedToken.phone_number,
      role: decodedToken.role || 'user',
      banned: decodedToken.banned || false
    };

    if (req.user.banned) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden: This account has been banned'
      });
    }

    next();
  } catch (error) {
    // For optional auth, we still want to log errors but continue as guest
    console.error('Optional token verification failed:', error.code);
    next();
  }
};

const isAdmin = (req, res, next) => {
  if (req.user && (req.user.role === 'admin' || req.user.role === 'superadmin')) {
    next();
  } else {
    res.status(403).json({
      success: false,
      error: 'Forbidden: Admin access required'
    });
  }
};

const isSuperAdmin = (req, res, next) => {
  if (req.user && req.user.role === 'superadmin') {
    next();
  } else {
    res.status(403).json({
      success: false,
      error: 'Forbidden: Superadmin access required'
    });
  }
};

module.exports = { verifyToken, optionalVerifyToken, isAdmin, isSuperAdmin };

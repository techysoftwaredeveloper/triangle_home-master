# Triangle Home Backend

## Overview
Node.js backend for Triangle Home, providing APIs for Admin, Superadmin, Hoster, and Student operations.

## Key Features
- **Production-Grade Infrastructure**:
    - **Security**: Hardened with `Helmet` (secure headers) and `express-rate-limit` (DDoS protection).
    - **Error Handling**: Centralized `errorHandler` with standardized JSON responses.
    - **Reliability**: All routes wrapped in `asyncHandler` to prevent server crashes on unhandled rejections.
    - **Logging**: Professional multi-file logging with `Winston` (logs available in `logs/` directory).
- **Booking Management**: Atomic booking creation with occupancy checks using Firestore transactions.
- **Property Management**: Occupancy reconciliation and property moderation.
- **Admin APIs**: Statistics, user management, and property approval.
- **Security**: Firebase ID Token verification with role-based access control (RBAC).
- **Scheduled Tasks**: Automatic cancellation of expired bookings via cron jobs.
- **Logging**: Request logging using Morgan.

## Setup

### Prerequisites
- Node.js (v18+)
- Firebase Project

### Installation
1. `cd server`
2. `npm install`

### Configuration
1. Create a `.env` file in the `server` directory.
2. Add your Firebase Service Account JSON as an environment variable:
   `FIREBASE_SERVICE_ACCOUNT='{...}'`
   Alternatively, place `serviceAccountKey.json` in the `server` directory.
3. Configure `LOG_LEVEL` (default: `info`) and `NODE_ENV` (default: `development`).

### Running the Server
- Development: `node server.js`
- The server runs on port `5000` by default.

## API Endpoints
All endpoints (except root) require a valid Firebase ID Token in the `Authorization` header and a valid Firebase App Check token in the `X-Firebase-AppCheck` header.

## Troubleshooting App Check
If you receive `401 Unauthorized: App Check token missing` or `Invalid App Check token`:
1. **Development**: Ensure your Debug Token is registered in the Firebase Console.
2. **Production**: Ensure the app is registered with Play Integrity (Android) or App Attest (iOS).
3. **Environment**: App Check is enforced strictly only in `production` mode in the current implementation to prevent blocking local development unless `NODE_ENV=production` is set.

### Bookings
- `GET /api/bookings/my`: Get current user's bookings.
- `POST /api/bookings`: Create a new booking request.
- `PATCH /api/bookings/:bookingId/status`: Update booking status.

### Properties
- `POST /api/properties`: Create a new property listing.
- `POST /api/properties/:propertyId/reconcile`: Reconcile property occupancy.

### Admin
- `GET /api/admin/stats`: Get dashboard statistics (including Students, Professionals, and Hosters).
- `GET /api/admin/users`: List all users.
- `PATCH /api/admin/users/:userId/role`: Change user role.
- `PATCH /api/admin/properties/:propertyId/status`: Approve/Reject properties.
- `GET /api/admin/verifications/pending`: List users awaiting document verification.
- `PATCH /api/admin/users/:userId/verification`: Approve/Reject specific user documents.

## Testing
Run the integration test script:
`node tests/test-api.js`
(Requires server to be running)

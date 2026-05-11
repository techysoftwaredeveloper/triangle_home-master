# Server-Side Implementation for Admin/Superadmin Control

This plan outlines the creation of a Node.js backend to provide administrative and super-administrative control over users, hosters, and property listings.

## User Review Required

> [!IMPORTANT]
> **Firebase Service Account Key**: You must download the `serviceAccountKey.json` from the Firebase Console (Project Settings > Service Accounts) and place it in the `server/` directory for the backend to function.
>
> **Consistency of IDs**: The current Flutter app seems to use phone numbers as document IDs in some collections (e.g., `student`, `hoster`) while using UIDs in others. The server-side code assumes the provided ID matches the Firestore document ID.

## Proposed Changes

### [Backend Server]

A new Node.js/Express server using Firebase Admin SDK.

#### [index.js](file:///C:/Users/hitec/own/dev/triangle_home-master/server/index.js)
- Entry point for the Express application.
- Sets up middleware (CORS, body-parser) and routes.

#### [firebase-config.js](file:///C:/Users/hitec/own/dev/triangle_home-master/server/firebase-config.js)
- Initializes Firebase Admin SDK.
- Exports `db` (Firestore) and `auth` (Firebase Auth) instances.

#### [auth.js](file:///C:/Users/hitec/own/dev/triangle_home-master/server/middleware/auth.js)
- `verifyToken`: Validates Firebase ID tokens sent in the `Authorization` header.
- `isAdmin`: Ensures the user has an `admin` or `superadmin` role in custom claims.
- `isSuperAdmin`: Ensures the user has a `superadmin` role.

#### [adminController.js](file:///C:/Users/hitec/own/dev/triangle_home-master/server/controllers/adminController.js)
- `getStats`: Aggregates statistics for the dashboard.
- `getAllUsers`: Fetches all students and hosters.
- `toggleUserStatus`: Bans/unbans users and updates custom claims.
- `updatePropertyStatus`: Approves or rejects property listings.
- `approveHoster`: Approves hoster registration and sets the `hoster` custom claim.

#### [superadminController.js](file:///C:/Users/hitec/own/dev/triangle_home-master/server/controllers/superadminController.js)
- `createAdmin`: Creates a new Firebase user and assigns the `admin` role.
- `getAllAdmins`: Lists all users with admin privileges.
- `removeAdmin`: Deletes an admin account.

#### [setup-superadmin.js](file:///C:/Users/hitec/own/dev/triangle_home-master/server/scripts/setup-superadmin.js)
- A utility script to promote an existing user to `superadmin` to bootstrap the system.

## How to Start the Server

### 1. Prerequisites
- **Node.js**: Ensure you have Node.js installed on your machine.
- **Firebase Service Account Key**:
    1. Go to the [Firebase Console](https://console.firebase.google.com/).
    2. Navigate to **Project Settings** > **Service Accounts**.
    3. Click **Generate new private key**.
    4. Save the downloaded JSON file as `serviceAccountKey.json` inside the `server/` directory.

### 2. Install Dependencies
Open your terminal, navigate to the `server/` directory, and run:
```bash
cd server
npm install
```

### 3. Environment Setup (Optional)
You can create a `.env` file in the `server/` directory to customize the port:
```env
PORT=5000
```

### 4. Start the Server
Run the following command in the `server/` directory:
```bash
node index.js
```
The server will start, and you should see:
`Server is running on port 5000`

### 5. Bootstrap Superadmin
To promote an existing user to superadmin so they can use the admin APIs:
```bash
node scripts/setup-superadmin.js <USER_UID> <USER_EMAIL>
```

---

## Verification Plan

### Automated Tests
- Since this is a new server, I recommend testing endpoints using Postman or `curl` after providing the service account key.
- Example command to promote a superadmin:
  ```bash
  node server/scripts/setup-superadmin.js <USER_UID> <USER_EMAIL>
  ```

### Manual Verification
1. **Bootstrap**: Run the setup script to create the first superadmin.
2. **Login**: Obtain a Firebase ID token for the superadmin user.
3. **API Access**: Use the token to call `GET /api/admin/stats`.
4. **Admin Creation**: Call `POST /api/superadmin/admins` to create a new admin.
5. **Role Check**: Verify that the new admin can access `/api/admin/*` but not `/api/superadmin/*`.

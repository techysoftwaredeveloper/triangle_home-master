# Updated Firestore Security Rules (Including Property Suggestions)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }

    function hasRole(role) {
      return isSignedIn() && getUserData().role == role;
    }

    function isAdmin() {
      return hasRole('admin');
    }

    // --- Users ---
    match /users/{userId} {
      allow read: if isSignedIn() && (request.auth.uid == userId || isAdmin());
      allow create: if isSignedIn() && request.auth.uid == userId &&
                    request.resource.data.role in ['student', 'hoster'] &&
                    (request.resource.data.permissions == null || request.resource.data.permissions.is_admin == false);
      allow update: if request.auth.uid == userId &&
                    !request.resource.data.diff(resource.data).affectedKeys()
                    .hasAny(['role', 'permissions', 'is_active']);
      allow delete: if isAdmin();
    }

    // --- Properties ---
    match /properties/{propertyId} {
      allow read: if true;
      allow write: if isAdmin() || (hasRole('hoster') && request.auth.uid == request.resource.data.hoster_id);
    }

    // --- Rooms & Beds ---
    match /rooms/{roomId} {
      allow read: if true;
      allow write: if isAdmin() || hasRole('hoster');
    }

    match /beds/{bedId} {
      allow read: if true;
      allow write: if isAdmin() || hasRole('hoster');
    }

    // --- Bookings ---
    match /bookings/{bookingId} {
      allow read: if isSignedIn() && (
        request.auth.uid == resource.data.user_id ||
        request.auth.uid == get(/databases/$(database)/documents/properties/$(resource.data.property_id)).data.hoster_id ||
        isAdmin()
      );
      allow create: if isSignedIn() && request.resource.data.user_id == request.auth.uid;
      allow update, delete: if isAdmin();
    }

    // --- Property Suggestions (NEW) ---
    match /property_suggestions/{suggestionId} {
      allow create: if isSignedIn() && request.resource.data.suggester_id == request.auth.uid;
      allow read: if isAdmin() || (isSignedIn() && resource.data.suggester_id == request.auth.uid);
      allow update, delete: if isAdmin();
    }

    // --- Cities & Localities ---
    match /cities/{cityId} {
      allow read: if true;
      allow write: if isAdmin();
      match /areas/{areaId} {
        allow read: if true;
        allow write: if isAdmin();
      }
    }

    // --- Wishlists ---
    match /wishlists/{wishId} {
      allow read, write: if isSignedIn() && request.auth.uid == (resource == null ? request.resource.data.user_id : resource.data.user_id);
    }

    // --- Reviews ---
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if isSignedIn();
      allow update, delete: if isAdmin() || (isSignedIn() && request.auth.uid == resource.data.user_id);
    }

    // --- Config & Settings ---
    match /config/{docId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /settings/global {
      allow read: if true;
      allow write: if isAdmin();
    }

    // --- Payments & Invoices ---
    match /payments/{paymentId} {
      allow read: if isSignedIn() && (request.auth.uid == resource.data.user_id || isAdmin());
      allow write: if false; // Only via Cloud Functions
    }

    match /invoices/{invoiceId} {
      allow read: if isSignedIn() && (
        request.auth.uid == get(/databases/$(database)/documents/bookings/$(resource.data.booking_id)).data.user_id ||
        isAdmin()
      );
      allow write: if false;
    }

    // --- Notifications ---
    match /notifications/{notifId} {
      allow read: if isSignedIn() && request.auth.uid == resource.data.user_id;
      allow update: if isSignedIn() && request.auth.uid == resource.data.user_id &&
                    request.resource.data.diff(resource.data).affectedKeys().hasOnly(['is_read']);
      allow create, delete: if false;
    }

    // --- Activity Logs & Analytics ---
    match /activity_logs/{logId} {
      allow read: if isAdmin();
      allow write: if false;
    }

    match /analytics/{docId} {
      allow read: if isAdmin() || hasRole('hoster');
      allow write: if false;
    }

    // --- Hoster Requests ---
    match /hoster_requests/{userId} {
      allow read: if isSignedIn() && (request.auth.uid == userId || isAdmin());
      allow create: if isSignedIn() && request.auth.uid == userId;
      allow update: if isAdmin();
    }
  }
}
```

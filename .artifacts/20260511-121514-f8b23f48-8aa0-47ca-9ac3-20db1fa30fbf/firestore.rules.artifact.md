# Firestore Security Rules (Final Production-Grade)

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // PUBLIC READ COLLECTIONS
    match /properties/{document=**} {
      allow read: if true;
      allow write: if request.auth != null
        && (request.auth.token.role == 'admin' || request.auth.token.role == 'superadmin');
    }

    match /cities/{document=**} {
      allow read: if true;
      allow write: if request.auth != null
        && (request.auth.token.role == 'admin' || request.auth.token.role == 'superadmin');
    }

    // USER DATA
    match /student/{userId} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;
    }

    match /hoster/{userId} {
      allow read, write: if request.auth != null
        && request.auth.uid == userId;
    }

    // ADMIN ONLY
    match /config/{document=**} {
      allow read: if true;
      allow write: if request.auth != null
        && request.auth.token.role == 'superadmin';
    }

    // ORDERS / BOOKINGS
    match /bookings/{orderId} {
      allow create: if request.auth != null;

      allow read: if request.auth != null
        && (
          resource.data.userId == request.auth.uid
          || request.auth.token.role == 'admin'
          || request.auth.token.role == 'superadmin'
        );

      allow update, delete: if request.auth != null
        && (request.auth.token.role == 'admin' || request.auth.token.role == 'superadmin');
    }
  }
}
```

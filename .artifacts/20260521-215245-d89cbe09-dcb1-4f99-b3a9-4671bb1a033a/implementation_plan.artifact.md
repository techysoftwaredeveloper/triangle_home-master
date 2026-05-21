# Optimize App Permissions

Prune unnecessary permissions, add missing essential ones, and ensure all sensitive permission requests are triggered only by user engagement (just-in-time).

## User Review Required

- **Biometrics**: I am keeping `USE_BIOMETRIC` as the app supports biometric login/settings.
- **Location**: I am keeping `ACCESS_FINE_LOCATION` for high-accuracy map functionality, but I am removing its automatic request on app startup.

## Proposed Changes

### Android Module

#### [AndroidManifest.xml](file:///C:/Users/hitec/own/dev/triangle_home-master/android/app/src/main/AndroidManifest.xml)

- **Removed**: `CALL_PHONE` (System dialer via `tel:` scheme is safer).
- **Added**: `ACCESS_NETWORK_STATE` (Connectivity monitoring).
- **Added**: `CAMERA` (Photo uploads).
- **Added**: `READ_MEDIA_IMAGES` (Modern gallery access).
- **Added**: `READ_EXTERNAL_STORAGE` (Legacy gallery access with `maxSdkVersion="32"`).
- **Added**: `POST_NOTIFICATIONS` (Push alerts for Android 13+).

```xml
    <!-- Optimized Permissions Set -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

---

### Home Module

#### [home_screen.dart](file:///C:/Users/hitec/own/dev/triangle_home-master/lib/screens/home_screen.dart)

- **Modified**: `_getCurrentCityFromLocation()` to **not** request location permission on startup.
- **Result**: The app will check if permission is already granted. If not, it will default to major cities without popping a permission dialog until the user taps "Near Me" or a location-triggering element.

---

## Verification Plan

### Manual Verification
- **Static Analysis**: Verify `AndroidManifest.xml` changes.
- **Startup Check**: Launch the app and verify **no permission dialogs** appear immediately.
- **On-Demand Check**:
    1. Tap "Near Me" in city selection. Verify it pops the **Location** request.
    2. Tap to change Profile Picture. Verify it pops **Camera/Gallery** request.
- **Dialer Check**: Tap a phone number. Verify it opens the system dialer with the number pre-filled.

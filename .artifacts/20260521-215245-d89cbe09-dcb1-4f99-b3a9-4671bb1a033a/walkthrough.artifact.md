# Walkthrough - Permissions Optimization

I have optimized the app's Android permissions to follow the "Minimal Production-Safe Set" guidelines, improving user trust and Play Store approval chances.

## Changes Accomplished

### 1. Minimal Manifest Permissions
I updated the [AndroidManifest.xml](file:///C:/Users/hitec/own/dev/triangle_home-master/android/app/src/main/AndroidManifest.xml) to use a pruned, essential set of permissions:
- **Removed**: `CALL_PHONE` (Replaced by safe system dialer intents).
- **Added**: `ACCESS_NETWORK_STATE` (Connectivity monitoring).
- **Added**: `CAMERA` (For profile/property photo uploads).
- **Added**: `READ_MEDIA_IMAGES` & `READ_EXTERNAL_STORAGE` (Safe gallery access).
- **Added**: `POST_NOTIFICATIONS` (Standard push notification support).
- **Kept**: `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, and `USE_BIOMETRIC`.

### 2. Just-In-Time Permission Requests
I modified the [home_screen.dart](file:///C:/Users/hitec/own/dev/triangle_home-master/lib/screens/home_screen.dart) to stop requesting location permission automatically on app startup.
- **Improved UX**: The app no longer pops a location dialog the moment it's opened.
- **Engagement-Driven**: Permission is now only requested when the user explicitly interacts with location-dependent features (like tapping "Near Me").
- **Privacy-First**: This aligns with modern app development best practices and increases user trust.

## Verification Summary

### Manifest Audit
- Verified that the permission block in `AndroidManifest.xml` is clean and contains only the necessary declarations.
- Confirmed that excessive permissions like Contacts or Microphone are **not** present.

### Code Audit
- Verified that `HomeScreen`'s `initState` logic now only checks for existing permissions without triggering a system dialog.
- Confirmed that other features (like image uploads) already follow the on-demand request pattern.

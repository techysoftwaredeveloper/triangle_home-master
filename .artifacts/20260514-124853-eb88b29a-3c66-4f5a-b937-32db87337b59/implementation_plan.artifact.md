# Implementation Plan - Production-Grade App Check

This plan outlines the changes to upgrade the App Check implementation from a debug-only setup to a production-grade logic that uses **Play Integrity** for Android and **App Attest/DeviceCheck** for iOS.

## User Action Required (CRITICAL)

> [!IMPORTANT]
> To enable production App Check, you MUST perform these steps in the Firebase and Google Play consoles:
> 1. **Android (Play Integrity)**:
>    - Go to **Google Play Console** > **App integrity** > **Link Cloud project** and select your Firebase project.
>    - Go to **Firebase Console** > **App Check** > **Apps** > **Android** and register your SHA-256 fingerprint.
> 2. **iOS (App Attest)**:
>    - Go to **Firebase Console** > **App Check** > **Apps** > **iOS** and configure your Team ID and App ID.
> 3. **Enforcement**:
>    - After verifying that legitimate traffic is passing (check the metrics tab), enable **Enforcement** for Firestore and Authentication in the Firebase Console.

## Proposed Changes

### [Dart Configuration]

#### [main.dart](file:///C:/Users/hitec/own/dev/triangle_home-master/lib/main.dart)
- Update `FirebaseAppCheck.instance.activate` to use production providers based on the build mode (`kReleaseMode`).
- Use `AndroidProvider.playIntegrity` for Android production.
- Use `AppleProvider.appAttest` for iOS production.

```dart
    await FirebaseAppCheck.instance.activate(
      androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
      appleProvider: kReleaseMode ? AppleProvider.appAttest : AppleProvider.debug,
    );
```

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no syntax errors.

### Manual Verification
- **Debug Mode**: Run the app in debug mode and verify that it still works using the debug provider (and previously registered debug tokens).
- **Production Logic**: Verify that the code correctly switches to `playIntegrity` and `appAttest` when `kReleaseMode` is true.
- **Logcat Check**: Ensure that in debug mode, the app still prints the debug secret if needed (as it currently does).

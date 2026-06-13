import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppCheckInitializer {
  /// Production-grade Firebase App Check initialization.
  /// Handles Emulator, Debug, Internal testing, and Production modes.
  static Future<void> initialize() async {
    try {
      final bool isAndroid = !kIsWeb && Platform.isAndroid;
      final bool isApple = !kIsWeb && (Platform.isIOS || Platform.isMacOS);

      debugPrint('===== APP CHECK INIT =====');
      debugPrint('kDebugMode: $kDebugMode');
      debugPrint('kReleaseMode: $kReleaseMode');

      if (kIsWeb) {
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider(
            '6LcC4N8sAAAAAPxY6w6R3yM8QQhCtx1HH-w0vuSD',
          ),
        );
      } else if (isAndroid) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: _androidProvider(),
        );
      } else if (isApple) {
        await FirebaseAppCheck.instance.activate(
          appleProvider: _appleProvider(),
        );
      }

      // Enable token auto-refresh for production hardening
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

      debugPrint('✅ Firebase App Check initialized');
    } catch (e, s) {
      debugPrint('❌ App Check init failed: $e');
      debugPrint('$s');
    }
  }

  static AndroidProvider _androidProvider() {
    if (kDebugMode) {
      debugPrint('Using DEBUG provider (emulator/local dev)');
      return AndroidProvider.debug;
    }
    // Release builds or profile builds use Play Integrity
    debugPrint('Using PLAY INTEGRITY provider');
    return AndroidProvider.playIntegrity;
  }

  static AppleProvider _appleProvider() {
    if (kDebugMode) {
      debugPrint('Using DEBUG Apple provider');
      return AppleProvider.debug;
    }
    // Use fallback for older iOS devices in production
    debugPrint('Using App Attest with Device Check fallback');
    return AppleProvider.appAttestWithDeviceCheckFallback;
  }
}

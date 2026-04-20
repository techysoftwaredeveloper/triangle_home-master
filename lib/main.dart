import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:triangle_home/splash_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Activate Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode
        ? AndroidProvider.playIntegrity
        : AndroidProvider.debug,
    appleProvider: kReleaseMode
        ? AppleProvider.deviceCheck
        : AppleProvider.debug,
    webProvider: ReCaptchaEnterpriseProvider('YOUR_RECAPTCHA_ENTERPRISE_SITE_KEY'),
  );

  runApp(const ProviderScope(child: TriangleHomes()));
}

class TriangleHomes extends StatelessWidget {
  const TriangleHomes({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Triangle Homes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      //home: AdminToolsScreen(),
    );
  }
}

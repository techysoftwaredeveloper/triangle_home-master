import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:triangle_home/splash_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar Local Database
  final isarService = IsarService();
  await isarService.db; // Wait for initialization

  // Set transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Robust App Check Initialization
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
      appleProvider: kReleaseMode ? AppleProvider.appAttest : AppleProvider.debug,
      webProvider: ReCaptchaV3Provider('6LcC4N8sAAAAAPxY6w6R3yM8QQhCtx1HH-w0vuSD'),
    );
    debugPrint('🚀 Firebase App Check activated with reCAPTCHA.');
  } catch (e) {
    debugPrint('⚠️ Firebase App Check activation warning: $e');
  }

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'IN'), // English, India - Uses DD/MM/YYYY
        Locale('en', 'GB'), // English, Great Britain
        Locale('en', 'US'), // English, American
      ],
      home: const SplashScreen(),
      //home: AdminToolsScreen(),
    );
  }
}

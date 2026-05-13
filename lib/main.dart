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

  // ✅ Robust App Check Initialization
  try {
    // 💡 Tip: In development, if you get PERMISSION_DENIED even with correct rules,
    // ensure your debug token is registered in the Firebase Console.
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    debugPrint('🚀 Firebase App Check activated.');
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
      home: const SplashScreen(),
      //home: AdminToolsScreen(),
    );
  }
}

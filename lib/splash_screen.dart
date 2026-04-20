import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:triangle_home/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Allow everyone to go to HomeScreen first
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ✅ SVG Background
            SvgPicture.asset(
              'assets/images/splashbackground.svg', // Ensure this file exists and path is correct
              fit: BoxFit.cover,
            ),

            // ✅ Foreground Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/Logo.svg',
                    width: 100,
                    height: 100,
                    semanticsLabel: 'App Logo',
                  ).animate().fadeIn(duration: 800.ms).scale(delay: 400.ms),
                  const SizedBox(height: 24),
                  const Text(
                    'TRIANGLE HOMES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'outfit',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

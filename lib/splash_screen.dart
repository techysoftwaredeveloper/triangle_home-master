import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/screens/admin/admin_dashboard.dart';
import 'package:triangle_home/services/firebase_service.dart';
import 'package:triangle_home/theme/app_theme.dart';

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
    // Delay to allow the splash animation to play
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final firebaseService = FirebaseService();
    final isAdmin = await firebaseService.isAdmin();

    if (isAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C4A79), // Lighter navy from top
              Color(0xFF1E335A), // Primary brand navy
              Color(0xFF132244), // Deep navy at bottom
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle curve patterns (using the existing SVG background as an overlay)
            Opacity(
              opacity: 0.4,
              child: SvgPicture.asset(
                'assets/images/splashbackground.svg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // Animated Foreground Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Animation
                  SvgPicture.asset(
                    'assets/images/Logo.svg',
                    width: 120,
                    height: 120,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ).animate()
                    .fadeIn(duration: 1200.ms, curve: Curves.easeOut)
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 1200.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 32),

                  // Text Animation
                  const Text(
                    'TRIANGLE HOMES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'outfit',
                      fontWeight: FontWeight.w400,
                      letterSpacing: 8, // Wide spacing as seen in image
                    ),
                  ).animate()
                    .fadeIn(delay: 600.ms, duration: 1000.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

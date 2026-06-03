import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/screens/admin/admin_dashboard_redesign.dart';
import 'package:triangle_home/hoster_info_screen.dart';
import 'package:triangle_home/services/auth_production_service.dart';
import 'package:triangle_home/screens/hoster/hoster_dashboard_screen.dart';
import 'package:triangle_home/screens/list_property/list_property_screen.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final IsarService _isarService = IsarService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Delay to allow the splash animation to play
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    try {
      final authService = AuthProductionService();
      final authDetails = await authService.getUserAuthDetails(user);
      final role = authDetails['role'] as UserRole;
      final status = authDetails['status'] as String;
      final uid = user.uid;

      if (!mounted) return;

      // 1. Admin priority
      if (role == UserRole.superadmin || role == UserRole.admin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboardRedesign()),
        );
        return;
      }

      // 2. Check for active hoster workflow drafts & requests
      final propertyDraft = await _isarService.getPropertyDraft(uid);
      final hosterAppDraft = await _isarService.getAdminCache(
        'hoster_application_draft_$uid',
      );
      final onboardingIntent = await _isarService.getUserIntent();

      // Check Firestore for a pending/rejected request if not already a hoster
      bool hasHosterRequest = false;
      if (role != UserRole.hoster) {
        final requestDoc =
            await FirebaseFirestore.instance
                .collection('hoster_requests')
                .doc(uid)
                .get();
        if (requestDoc.exists) {
          hasHosterRequest = true;
        }
      }

      // If they have any hoster-related draft, intent, or existing request, stay in hoster flow
      if (onboardingIntent == 'hoster' ||
          hosterAppDraft != null ||
          propertyDraft != null ||
          role == UserRole.hoster ||
          hasHosterRequest) {
        // If they are already an approved hoster, clear the "intent" as it's now a reality
        if (role == UserRole.hoster && status == 'approved') {
          await _isarService.clearUserIntent();
        }

        // RESUME WORKFLOW logic
        if (propertyDraft != null && status == 'approved') {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ListPropertyScreen()),
          );
        } else if (hosterAppDraft != null ||
            hasHosterRequest ||
            (role == UserRole.hoster && status != 'approved')) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => HosterInfoScreen(phoneNumber: user.phoneNumber ?? ''),
            ),
          );
        } else if (role == UserRole.hoster && status == 'approved') {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HosterDashboardScreen()),
          );
        } else if (onboardingIntent == 'hoster' &&
            (role == UserRole.none || role == UserRole.student)) {
          // New hoster registration resume
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => HosterInfoScreen(phoneNumber: user.phoneNumber ?? ''),
            ),
          );
        } else {
          // Fallback hoster destination
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => HosterInfoScreen(phoneNumber: user.phoneNumber ?? ''),
            ),
          );
        }
        return;
      }

      // 3. Student / Guest flow
      if (role == UserRole.student || role == UserRole.none) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      }

      // 4. Ultimate fallback
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      debugPrint('Splash screen error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
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
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 1200.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        duration: 1200.ms,
                        curve: Curves.easeOutBack,
                      ),

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
                      )
                      .animate()
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

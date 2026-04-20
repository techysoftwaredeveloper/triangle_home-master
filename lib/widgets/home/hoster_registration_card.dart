import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/auth/login_screen.dart';
import 'package:triangle_home/screens/hoster/become_hoster_screen.dart';
import 'package:triangle_home/screens/hoster/hoster_dashboard_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';

/// HosterRegistrationCard - Entry point for Hoster login/registration.
/// Routing:
///   Not logged in → LoginScreen
///   Logged in, approved hoster → HosterDashboardScreen
///   Logged in, not a hoster → BecomeHosterScreen (request form)
class HosterRegistrationCard extends StatelessWidget {
  const HosterRegistrationCard({super.key});

  Future<void> _handleHosterLogin(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    // 1. Not logged in → go to login (no specific destination, OTP flow handles it)
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen(isStudent: false)),
      );
      return;
    }

    final uid = user.uid;

    // 2. Check if already an approved hoster
    final hosterDoc =
        await FirebaseFirestore.instance.collection('hoster').doc(uid).get();

    if (!context.mounted) return;

    if (hosterDoc.exists) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HosterDashboardScreen()),
      );
      return;
    }

    // 3. Not a hoster yet → go to request form
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BecomeHosterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withValues(alpha: 0.05), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _handleHosterLogin(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_business_rounded,
                color: AppTheme.primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'List Your Property',
                    style: TextStyle(
                      fontSize: AppTheme.fontLG,
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'College, PG, or Apartment owner?\nJoin TRIANGLE HOMES today!',
                    style: TextStyle(
                      fontSize: AppTheme.fontSM + 1,
                      fontFamily: AppTheme.fontFamily,
                      color: AppTheme.textLightColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.1, end: 0);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/hoster_info_screen.dart';
import 'package:triangle_home/screens/auth/login_screen.dart';
import 'package:triangle_home/screens/hoster/become_hoster_screen.dart';
import 'package:triangle_home/screens/hoster/hoster_dashboard_screen.dart';
import 'package:triangle_home/screens/list_property/intro_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';

/// HosterRegistrationCard - Entry point for Hoster login/registration.
class HosterRegistrationCard extends StatelessWidget {
  const HosterRegistrationCard({super.key});

  Future<void> _handleHosterFlow(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    // 1. If logged in, check role
    if (user != null && !user.isAnonymous) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!context.mounted) return;

      if (userDoc.exists && userDoc.data()?['role'] == 'hoster') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HosterDashboardScreen()));
        return;
      }
    }

    // 2. If not logged in or not a hoster, show the Intro Screen first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListPropertyIntroScreen(
          onGetStarted: () {
            // After intro, if still not logged in, go to Login
            if (user == null || user.isAnonymous) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen(isStudent: false)),
              );
            } else {
              // Already logged in but not a hoster, go to application form
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HosterInfoScreen(
                    phoneNumber: user?.phoneNumber ?? '',
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.05), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _handleHosterFlow(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: AppTheme.font2XL,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.textDarkColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last updated: May 11, 2026',
              style: TextStyle(
                color: AppTheme.textMutedColor,
                fontFamily: AppTheme.fontFamily,
                fontSize: AppTheme.fontSM,
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              '1. Information We Collect',
              'We collect information you provide directly to us, including your name, email address, phone number, and other details necessary for providing our accommodation listing and booking services.',
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
            _buildSection(
              '2. How We Use Your Information',
              'We use the information we collect to provide, maintain, and improve our services, communicate with you, process bookings, and ensure a safe and reliable platform for all users.',
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
            _buildSection(
              '3. Information Sharing',
              'We do not sell your personal information. We share your information only with your consent or as necessary to provide our services (e.g., sharing tenant details with hosters).',
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),
            _buildSection(
              '4. Data Security',
              'We implement industry-standard security measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction.',
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),
            _buildSection(
              '5. Your Rights',
              'You have the right to access, correct, or request deletion of your personal information. You can manage your profile details in the app or contact our support team.',
            ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0),
            _buildSection(
              '6. Changes to This Policy',
              'We may update this privacy policy from time to time. We will notify you of any significant changes by posting the new policy on this page.',
            ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to contact/support
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: AppTheme.fontMD,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTheme.fontLG,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.textDarkColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: AppTheme.fontBase,
              height: 1.6,
              color: AppTheme.textColor,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

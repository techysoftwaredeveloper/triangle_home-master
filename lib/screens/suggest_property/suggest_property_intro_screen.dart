import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/hoster/become_hoster_screen.dart';
import 'package:triangle_home/screens/suggest_property/suggest_property_form_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';

class SuggestPropertyIntroScreen extends StatelessWidget {
  const SuggestPropertyIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDarkColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Text(
                    'Suggest a Property',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      color: AppTheme.primaryColor,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 8),
                  const Text(
                    'Help others find a great place to live or stay.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLightColor,
                      fontFamily: 'Outfit',
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 32),

                  // High-fidelity House Illustration Placeholder
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 120,
                        width: 180,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.home_work_rounded, size: 70, color: AppTheme.primaryColor),
                      ),
                      Positioned(
                        top: 0,
                        right: 40,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.location_on_rounded, color: AppTheme.primaryColor, size: 30),
                        ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.easeOutBack),
                      ),
                    ],
                  ).animate().scale(delay: 300.ms, duration: 500.ms, curve: Curves.easeOutBack),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Center(
              child: Text(
                'Why suggest a property?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                  color: AppTheme.textDarkColor,
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),
            _buildBenefitItem(
              icon: Icons.group_add_outlined,
              title: 'Help the Community',
              description: 'Your suggestions help students and professionals find verified and reliable accommodations.',
              color: Colors.green,
            ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 16),
            _buildBenefitItem(
              icon: Icons.verified_user_outlined,
              title: 'Trusted & Verified',
              description: 'We verify every property and business owner to ensure safety and trust for everyone.',
              color: Colors.blue,
            ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 16),
            _buildBenefitItem(
              icon: Icons.card_giftcard_outlined,
              title: 'Appreciation Rewards',
              description: 'Top suggesters get special rewards, recognition and exclusive benefits.',
              color: Colors.orange,
            ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 32),

            // Quote/Highlight box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.format_quote_rounded, color: Colors.green, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Your suggestion can make someone\'s stay better and stress-free!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Outfit',
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 800.ms),

            const SizedBox(height: 48),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SuggestPropertyFormScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Suggest a Property',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BecomeHosterScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Own a property? Become a Hoster',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: AppTheme.primaryColor),
                ),
              ),
            ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 32),

            // Secure Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 16, color: AppTheme.textLightColor.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(
                  'Your information is safe and secure',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightColor.withValues(alpha: 0.6),
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 1100.ms),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    color: AppTheme.textDarkColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightColor,
                    fontFamily: 'Outfit',
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.3), size: 14),
        ],
      ),
    );
  }
}

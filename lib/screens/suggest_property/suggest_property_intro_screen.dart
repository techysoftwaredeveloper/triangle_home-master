import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/hoster/partner_onboarding_screen.dart';
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textDarkColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Property Suggestion',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  const Text(
                    'Help your community grow',
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
                        height: 140,
                        width: 220,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const Icon(
                          Icons.home_work_rounded,
                          size: 80,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 30,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ).animate().scale(
                          delay: 500.ms,
                          duration: 400.ms,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                    ],
                  ).animate().scale(
                    delay: 300.ms,
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            _buildSectionTitle('Benefits of suggesting'),
            const SizedBox(height: 24),
            _buildBenefitItem(
              icon: Icons.group_add_outlined,
              title: 'Help the Community',
              description:
                  'Aid students & pros in finding verified, reliable stays.',
              color: const Color(0xFF22C55E), // Green
            ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 12),
            _buildBenefitItem(
              icon: Icons.verified_user_outlined,
              title: 'Trusted & Verified',
              description:
                  'We verify owners to ensure safety and trust for all.',
              color: const Color(0xFF3B82F6), // Blue
            ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 12),
            _buildBenefitItem(
              icon: Icons.card_giftcard_outlined,
              title: 'Appreciation Rewards',
              description:
                  'Top suggesters get special rewards and recognition.',
              color: const Color(0xFFF59E0B), // Orange
            ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.1, end: 0),

            const SizedBox(height: 40),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SuggestPropertyFormScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PartnerOnboardingScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Own a property? Become a Host',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 32),

            // Secure Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: AppTheme.textLightColor.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'Your data is private and encrypted',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLightColor.withValues(alpha: 0.5),
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 1000.ms),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        fontFamily: 'Outfit',
        color: AppTheme.textLightColor,
        letterSpacing: 1.2,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightColor,
                    fontFamily: 'Outfit',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

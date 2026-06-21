import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
              'Terms of Service',
              style: TextStyle(
                fontSize: AppTheme.font2XL,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.textDarkColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last updated: June 22, 2026',
              style: TextStyle(
                color: AppTheme.textMutedColor,
                fontFamily: AppTheme.fontFamily,
                fontSize: AppTheme.fontSM,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSection(
              '1. Acceptance of Terms',
              'By accessing or using the Triangle Homes application, you agree to be bound by these Terms and Conditions and all applicable laws and regulations in India. If you do not agree with any of these terms, you are prohibited from using the platform.',
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
            
            _buildSection(
              '2. Platform Role & Intermediary Status',
              'Triangle Homes acts as an Intermediary as defined under Section 2(1)(w) of the Information Technology Act, 2000. We provide a platform to connect Residents (Tenants) with Hosters (Property Owners/Managers). Triangle Homes does not own, manage, or control the properties listed on the platform.',
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
            
            _buildSection(
              '3. User Verification (KYC)',
              'Safety is our priority. All users must provide accurate and up-to-date Know Your Customer (KYC) documentation, including Government IDs (Aadhaar/PAN) and proof of student or professional status. Providing fraudulent information is a criminal offense.',
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),
            
            _buildSection(
              '4. Booking & Payments',
              'Bookings are confirmed only upon successful payment of the security deposit or booking fee. All payments are subject to GST (18%) as per Indian Taxation Laws. Triangle Homes uses secure third-party payment gateways and does not store sensitive card information.',
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),
            
            _buildSection(
              '5. Limitation of Liability',
              'Triangle Homes shall not be liable for any direct, indirect, or incidental damages arising from disputes between Residents and Hosters, property conditions, or loss of personal belongings. Users are encouraged to inspect properties before finalizing.',
            ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0),
            
            _buildSection(
              '6. Prohibited Conduct',
              'Users must adhere to the house rules set by Hosters. Any illegal activities, harassment, property damage, or violation of local municipal laws will result in immediate account termination and legal action.',
            ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1, end: 0),
            
            _buildSection(
              '7. Governing Law & Jurisdiction',
              'These terms are governed by the laws of the Republic of India. Any disputes arising out of the use of this platform shall be subject to the exclusive jurisdiction of the courts in Kozhikode, Kerala.',
            ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1, end: 0),
            
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppTheme.primaryColor),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Your safety and data privacy are protected by Triangle Homes encryption standards.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textLightColor, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
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

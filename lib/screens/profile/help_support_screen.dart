import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: AppTheme.fontLG,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.fontFamily,
                      color: AppTheme.textDarkColor,
                    ),
                  ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 16),
                  _buildFaqItem('How do I list my property?', 'You can list your property by clicking on the "List A Property" button in the bottom navigation bar and following the simple registration steps.'),
                  _buildFaqItem('How do I book a property?', 'Browse through available properties on the home screen, select one you like, and click on "Book Now" to start the process.'),
                  _buildFaqItem('What payment methods are accepted?', 'We accept all major credit/debit cards, UPI, and net banking through our secure payment gateway.'),
                  _buildFaqItem('Is my data secure?', 'Yes, we take privacy and security seriously. Your data is encrypted and handled according to our strict privacy policy.'),

                  const SizedBox(height: 32),
                  const Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: AppTheme.fontLG,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.fontFamily,
                      color: AppTheme.textDarkColor,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    subtitle: 'support@trianglehomes.com',
                    onTap: () {},
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                  _buildContactCard(
                    icon: Icons.phone_outlined,
                    title: 'Phone Support',
                    subtitle: '+91 98765 43210',
                    onTap: () {},
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                  _buildContactCard(
                    icon: Icons.chat_outlined,
                    title: 'Live Chat',
                    subtitle: 'Chat with our support team',
                    onTap: () {},
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent_rounded, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: AppTheme.fontXL,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our team is here to assist you 24/7',
            style: TextStyle(
              fontSize: AppTheme.fontBase,
              color: Colors.white.withOpacity(0.8),
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: AppTheme.fontBase,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.fontFamily,
            color: AppTheme.textColor,
          ),
        ),
        iconColor: AppTheme.primaryColor,
        collapsedIconColor: AppTheme.textMutedColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: AppTheme.fontSM,
                height: 1.5,
                color: AppTheme.textLightColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: AppTheme.fontBase,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: AppTheme.fontSM,
            color: AppTheme.textLightColor,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMutedColor),
      ),
    );
  }
}

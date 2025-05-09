import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: ${DateTime.now().toString().split(' ')[0]}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Information We Collect',
            'We collect information you provide directly to us, including name, email address, phone number, and other details necessary for our services.',
          ),
          _buildSection(
            'How We Use Your Information',
            'We use the information we collect to provide, maintain, and improve our services, communicate with you, and ensure a safe platform for all users.',
          ),
          _buildSection(
            'Information Sharing',
            'We do not sell your personal information. We share your information only with your consent or as necessary to provide our services.',
          ),
          _buildSection(
            'Data Security',
            'We implement appropriate security measures to protect your personal information from unauthorized access, alteration, or destruction.',
          ),
          _buildSection(
            'Your Rights',
            'You have the right to access, correct, or delete your personal information. Contact us to exercise these rights.',
          ),
          _buildSection(
            'Changes to This Policy',
            'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page.',
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Handle contact
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Contact Us'),
          ).animate().fadeIn().slideY(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }
}
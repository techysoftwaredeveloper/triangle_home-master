import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSection(
            'Frequently Asked Questions',
            [
              _buildFaqItem('How do I list my property?', 'You can list your property by clicking on the "List Property" button in the bottom navigation bar and following the simple steps.'),
              _buildFaqItem('How do I book a property?', 'Browse through available properties, select one you like, and click on "Book Now" to start the booking process.'),
              _buildFaqItem('What payment methods are accepted?', 'We accept all major credit/debit cards, UPI, and net banking.'),
            ],
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact Us',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email Support'),
                  subtitle: const Text('support@trianglehomes.com'),
                  onTap: () {},
                ).animate().fadeIn().slideX(),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Phone Support'),
                  subtitle: const Text('+91 98765 43210'),
                  onTap: () {},
                ).animate().fadeIn().slideX(),
                ListTile(
                  leading: const Icon(Icons.chat_outlined),
                  title: const Text('Live Chat'),
                  subtitle: const Text('Chat with our support team'),
                  onTap: () {},
                ).animate().fadeIn().slideX(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(answer),
        ),
      ],
    ).animate().fadeIn().slideX();
  }
}
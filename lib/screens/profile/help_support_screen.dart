import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

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
      body: Column(
        children: [
          _buildHeader(),
          Container(
            color: AppTheme.primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
              tabs: const [Tab(text: 'Resident FAQ'), Tab(text: 'Partner FAQ')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFaqList(_residentFaqs),
                _buildFaqList(_partnerFaqs),
              ],
            ),
          ),
          _buildContactSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent_rounded, size: 56, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: AppTheme.fontXL,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Support for residents and property partners',
            style: TextStyle(
              fontSize: AppTheme.fontBase,
              color: Colors.white.withValues(alpha: 0.8),
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildFaqList(List<Map<String, String>> faqs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children:
            faqs
                .map((faq) => _buildFaqItem(faq['q']!, faq['a']!))
                .toList(),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Outfit',
            color: AppTheme.textDarkColor,
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
                fontSize: 13,
                height: 1.5,
                color: AppTheme.textColor,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Still need help?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.textDarkColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _contactAction(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  onTap: () => _launchUrl('mailto:support@trianglehomes.in'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _contactAction(
                  icon: Icons.phone_outlined,
                  label: 'Call Us',
                  onTap: () => _launchUrl('tel:+919876543210'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _contactAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  onTap: () {}, // Live chat placeholder
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final List<Map<String, String>> _residentFaqs = [
    {
      'q': 'How do personalized recommendations work?',
      'a': 'Our smart engine analyzes your profile—including budget, gender, and stay preferences—to score and surface the best-matching properties for your needs.',
    },
    {
      'q': 'What is the 15-minute checkout timer?',
      'a': 'To ensure fairness, we temporarily lock your selected bed for 15 minutes while you complete the payment. If the payment isn\'t finished within this time, the bed is released for other residents.',
    },
    {
      'q': 'Why is my identity verification mandatory?',
      'a': 'Safety is our top priority. Verified profiles help us maintain a secure community of students and professionals. You\'ll need to upload a Government ID (Aadhaar/PAN) to start booking.',
    },
    {
      'q': 'What is the breakdown of my booking payment?',
      'a': 'Your initial payment includes the First Month\'s Rent + Security Deposit + 18% GST on platform services. A clear breakdown is shown before you pay.',
    },
    {
      'q': 'Can I visit a property before booking?',
      'a': 'Yes! You can contact the property partner directly through the app to schedule a physical visit or request a video tour.',
    },
  ];

  final List<Map<String, String>> _partnerFaqs = [
    {
      'q': 'How do I become an approved hoster?',
      'a': 'Complete our multi-step partner onboarding, which includes providing business details, address proof, and KYC documents. Our admin team reviews all applications within 24-48 hours.',
    },
    {
      'q': 'How do I manage my property inventory?',
      'a': 'You can add floors, rooms, and individual beds via the Hoster Dashboard. You can also mark specific beds for maintenance or block them as needed.',
    },
    {
      'q': 'What if my application is rejected?',
      'a': 'If your application or a specific document is rejected, you\'ll see a clear reason from our admin team. You can click "Edit & Re-submit" to fix the issue and try again.',
    },
    {
      'q': 'How are payouts handled?',
      'a': 'Rent payments from residents are collected securely. Payouts are transferred to your registered bank account after deducting applicable platform fees.',
    },
    {
      'q': 'How can I increase my property\'s visibility?',
      'a': 'High-quality photos, detailed descriptions of amenities, and prompt responses to resident inquiries significantly improve your ranking in our recommendation engine.',
    },
  ];
}

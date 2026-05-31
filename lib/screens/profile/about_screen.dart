import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:triangle_home/theme/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logomain.png',
                      height: 80,
                      width: 80,
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 24),
                  const Text(
                    'Triangle Homes',
                    style: TextStyle(
                      fontSize: AppTheme.font2XL,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.fontFamily,
                      color: AppTheme.textDarkColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version $_version',
                    style: const TextStyle(
                      color: AppTheme.textMutedColor,
                      fontFamily: AppTheme.fontFamily,
                      fontSize: AppTheme.fontSM,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildSectionCard(
              title: 'Who We Are',
              content: 'Triangle Homes is your trusted partner in finding the perfect accommodation. We connect students and professionals with quality paying guest accommodations, hostels, and apartments.',
              icon: Icons.info_outline_rounded,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),
            _buildInfoRow(
              'Our Mission',
              'To provide safe, comfortable, and affordable accommodation solutions for everyone.',
              Icons.flag_outlined,
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),
            _buildInfoRow(
              'Quality Assurance',
              'All properties are verified and regularly inspected for quality.',
              Icons.verified_outlined,
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),
            _buildInfoRow(
              'Customer Support',
              '24/7 support to assist you with your accommodation needs.',
              Icons.support_agent_rounded,
            ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 40),
            const Text(
              'Connect With Us',
              style: TextStyle(
                fontSize: AppTheme.fontLG,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.textDarkColor,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(Icons.facebook_rounded, 'Facebook'),
                _buildSocialButton(Icons.language_rounded, 'Website'),
                _buildSocialButton(Icons.email_outlined, 'Email'),
              ],
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String content, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppTheme.fontLG,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: AppTheme.fontBase,
              height: 1.6,
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontBase,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSM,
                    color: AppTheme.textLightColor,
                    fontFamily: AppTheme.fontFamily,
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

  Widget _buildSocialButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon),
            onPressed: () {},
            color: AppTheme.primaryColor,
            iconSize: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppTheme.fontXS,
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

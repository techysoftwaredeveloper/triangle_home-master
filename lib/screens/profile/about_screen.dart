import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logomain.png',
                  height: 100,
                  width: 100,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Triangle Homes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Version $_version',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ).animate().scale(),
          const SizedBox(height: 32),
          const Text(
            'About Triangle Homes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Triangle Homes is your trusted partner in finding the perfect accommodation. We connect students and professionals with quality paying guest accommodations, hostels, and apartments.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ).animate().fadeIn().slideX(),
          const SizedBox(height: 24),
          _buildInfoTile(
            'Our Mission',
            'To provide safe, comfortable, and affordable accommodation solutions for everyone.',
            Icons.flag,
          ),
          _buildInfoTile(
            'Quality Assurance',
            'All properties are verified and regularly inspected for quality.',
            Icons.verified,
          ),
          _buildInfoTile(
            'Customer Support',
            '24/7 support to assist you with your accommodation needs.',
            Icons.support_agent,
          ),
          const SizedBox(height: 32),
          const Text(
            'Connect With Us',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(Icons.facebook, 'Facebook'),
              _buildSocialButton(Icons.link, 'Website'),
              _buildSocialButton(Icons.email, 'Email'),
            ],
          ).animate().fadeIn().slideY(),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String description, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E3A8A)),
      title: Text(title),
      subtitle: Text(description),
    ).animate().fadeIn().slideX();
  }

  Widget _buildSocialButton(IconData icon, String label) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: () {},
          color: const Color(0xFF1E3A8A),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
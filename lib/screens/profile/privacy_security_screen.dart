import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _twoFactorAuth = false;
  bool _biometricLogin = true;
  bool _locationSharing = true;
  bool _profileVisibility = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Security Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('Change Password'),
            leading: const Icon(Icons.lock_outline),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ).animate().fadeIn().slideX(),
          SwitchListTile(
            value: _twoFactorAuth,
            onChanged: (value) => setState(() => _twoFactorAuth = value),
            title: const Text('Two-Factor Authentication'),
            subtitle: const Text('Add an extra layer of security'),
            secondary: const Icon(Icons.security),
          ).animate().fadeIn().slideX(),
          SwitchListTile(
            value: _biometricLogin,
            onChanged: (value) => setState(() => _biometricLogin = value),
            title: const Text('Biometric Login'),
            subtitle: const Text('Use fingerprint or face recognition'),
            secondary: const Icon(Icons.fingerprint),
          ).animate().fadeIn().slideX(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Privacy Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            value: _locationSharing,
            onChanged: (value) => setState(() => _locationSharing = value),
            title: const Text('Location Sharing'),
            subtitle: const Text('Share your location with property owners'),
            secondary: const Icon(Icons.location_on_outlined),
          ).animate().fadeIn().slideX(),
          SwitchListTile(
            value: _profileVisibility,
            onChanged: (value) => setState(() => _profileVisibility = value),
            title: const Text('Profile Visibility'),
            subtitle: const Text('Make your profile visible to others'),
            secondary: const Icon(Icons.visibility),
          ).animate().fadeIn().slideX(),
          ListTile(
            title: const Text('Blocked Users'),
            leading: const Icon(Icons.block),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ).animate().fadeIn().slideX(),
          ListTile(
            title: const Text('Delete Account'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () {
              // Show delete account confirmation dialog
            },
          ).animate().fadeIn().slideX(),
        ],
      ),
    );
  }
}
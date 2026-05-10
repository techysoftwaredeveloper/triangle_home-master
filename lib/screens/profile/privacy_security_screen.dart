import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';

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
  bool _showNumberToHosters = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSectionHeader('Security Settings'),
            _buildSettingsGroup([
              _buildActionTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Update your security credentials',
                onTap: () {},
              ),
              _buildSwitchTile(
                icon: Icons.security_rounded,
                title: 'Two-Factor Authentication',
                subtitle: 'Enhanced security via OTP verification',
                value: _twoFactorAuth,
                onChanged: (v) => setState(() => _twoFactorAuth = v),
              ),
              _buildSwitchTile(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric Security',
                subtitle: 'Use Face ID or Fingerprint to unlock',
                value: _biometricLogin,
                onChanged: (v) => setState(() => _biometricLogin = v),
              ),
            ]),

            _buildSectionHeader('Privacy Preferences'),
            _buildSettingsGroup([
              _buildSwitchTile(
                icon: Icons.location_on_outlined,
                title: 'Real-time Location',
                subtitle: 'Helps in showing nearby accommodations',
                value: _locationSharing,
                onChanged: (v) => setState(() => _locationSharing = v),
              ),
              _buildSwitchTile(
                icon: Icons.visibility_outlined,
                title: 'Profile Visibility',
                subtitle: 'Allow hosters to see your verified profile',
                value: _profileVisibility,
                onChanged: (v) => setState(() => _profileVisibility = v),
              ),
              _buildSwitchTile(
                icon: Icons.phone_android_rounded,
                title: 'Contact Privacy',
                subtitle: 'Show my number to verified hosters only',
                value: _showNumberToHosters,
                onChanged: (v) => setState(() => _showNumberToHosters = v),
              ),
              _buildActionTile(
                icon: Icons.block_rounded,
                title: 'Blocked Hosters',
                subtitle: 'Manage restricted profiles',
                onTap: () {},
              ),
            ]),

            _buildSectionHeader('Account Actions'),
            _buildSettingsGroup([
              _buildActionTile(
                icon: Icons.download_for_offline_rounded,
                title: 'Download My Data',
                subtitle: 'Get a copy of your personal records',
                onTap: () {},
              ),
              _buildActionTile(
                icon: Icons.delete_forever_rounded,
                title: 'Deactivate Account',
                subtitle: 'Permanently remove your profile',
                titleColor: AppTheme.errorColor,
                iconColor: AppTheme.errorColor,
                showTrailing: false,
                onTap: () => _showDeleteConfirmation(context),
              ),
            ]),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.shield_rounded, size: 64, color: Colors.white.withOpacity(0.9)),
          const SizedBox(height: 16),
          const Text(
            'Your Security, Our Priority',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage how your information is used and secured',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          fontFamily: AppTheme.fontFamily,
          color: AppTheme.textDarkColor,
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final widget = entry.value;
          return Column(
            children: [
              widget,
              if (index < children.length - 1)
                const Divider(height: 1, indent: 64, endIndent: 16, color: AppTheme.dividerColor),
            ],
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
    bool showTrailing = true,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryColor).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppTheme.textColor,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textMutedColor,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
      trailing: showTrailing ? const Icon(Icons.chevron_right_rounded, color: AppTheme.textMutedColor, size: 20) : null,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textColor,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textMutedColor,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete Account?',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        content: const Text(
          'This action is permanent. All your bookings, wishlist items, and personal data will be erased from our servers.',
          style: TextStyle(fontFamily: 'Outfit', color: AppTheme.textLightColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontFamily: 'Outfit')),
          ),
          ElevatedButton(
            onPressed: () {
              // Implementation for account deletion
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontFamily: 'Outfit')),
          ),
        ],
      ),
    );
  }
}

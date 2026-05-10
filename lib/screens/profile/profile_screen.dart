import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/screens/hoster/hoster_dashboard_screen.dart';
import 'package:triangle_home/screens/home_screen.dart';
import 'package:triangle_home/screens/profile/about_screen.dart';
import 'package:triangle_home/screens/profile/edit_profile_screen.dart';
import 'package:triangle_home/screens/profile/help_support_screen.dart';
import 'package:triangle_home/screens/profile/notifications_screen.dart';
import 'package:triangle_home/screens/profile/privacy_policy_screen.dart';
import 'package:triangle_home/screens/profile/privacy_security_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
import 'package:triangle_home/widgets/logout_confirmation_dialog.dart';
import 'package:triangle_home/splash_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBottomNav;
  const ProfileScreen({super.key, this.showBottomNav = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? name;
  String? email;
  String? profileImageUrl;
  bool _isHoster = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final uid = user.uid;
    final phone = user.phoneNumber;
    final collectionNames = ['hoster', 'student', 'guest'];

    try {
      for (final collection in collectionNames) {
        // Try by uid first
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(uid)
            .get();

        // If not found by uid, try by phone if available
        if (!doc.exists && phone != null) {
          doc = await FirebaseFirestore.instance
              .collection(collection)
              .doc(phone)
              .get();
        }

        if (doc.exists) {
          final data = doc.data()! as Map<String, dynamic>;
          final info = (data['info'] as Map?)?.cast<String, dynamic>() ?? {};
          if (mounted) {
            setState(() {
              name = info['name'] as String? ?? data['name'] as String?;
              email = info['email'] as String? ?? data['email'] as String?;
              profileImageUrl = info['profileImage'] as String? ??
                  data['profileImage'] as String?;
              _isHoster = (collection == 'hoster');
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _handleSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LogoutConfirmationDialog(
        onConfirm: () async {
          await FirebaseAuth.instance.signOut();
          if (!context.mounted) return;
          Fluttertoast.showToast(
            msg: 'Signed out successfully',
            backgroundColor: AppTheme.textDarkColor,
            textColor: Colors.white,
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: AppTheme.spaceMD),
                  _buildSection(
                    title: 'Account Settings',
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit Profile',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen()),
                        ),
                      ),
                      if (_isHoster)
                        _MenuItem(
                          icon: Icons.dashboard_outlined,
                          title: 'Hoster Dashboard',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HosterDashboardScreen()),
                          ),
                        ),
                      _MenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen()),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.lock_outline_rounded,
                        title: 'Privacy & Security',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacySecurityScreen()),
                        ),
                      ),
                    ],
                  ),
                  _buildSection(
                    title: 'Support & About',
                    items: [
                      _MenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HelpSupportScreen()),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        title: 'About Us',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AboutScreen()),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: OutlinedButton.icon(
                      onPressed: () => _handleSignOut(context),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 40),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: AppTheme.textMutedColor,
                      fontSize: AppTheme.fontSM,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXL),
                ],
              ),
            ),
      bottomNavigationBar:
          widget.showBottomNav ? const HomeBottomNavBar(selectedIndex: 0) : null,
    );
  }

  Widget _buildProfileHeader() {
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
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profileImageUrl ??
                          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name ?? "U")}&background=random',
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.person, size: 50, color: AppTheme.primaryColor),
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ).animate().scale(delay: 400.ms),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name ?? 'Guest User',
            style: const TextStyle(
              fontSize: AppTheme.font2XL,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: AppTheme.fontFamily,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 4),
          Text(
            email ?? (FirebaseAuth.instance.currentUser?.phoneNumber ?? ''),
            style: TextStyle(
              fontSize: AppTheme.fontMD,
              color: Colors.white.withOpacity(0.8),
              fontFamily: AppTheme.fontFamily,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: AppTheme.fontMD,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: AppTheme.primaryColor, size: 22),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: AppTheme.fontBase,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMutedColor),
                      onTap: item.onTap,
                    ),
                    if (index < items.length - 1)
                      const Divider(height: 1, indent: 56, endIndent: 16, color: AppTheme.dividerColor),
                  ],
                );
              }).toList(),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

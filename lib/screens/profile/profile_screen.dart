import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/screens/admin/admin_dashboard_screen.dart';
import 'package:triangle_home/screens/hoster/hoster_dashboard_screen.dart';
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
  bool _isAdmin = false;
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

          // Check for admin role in custom claims
          final idTokenResult = await user.getIdTokenResult(true);
          final role = idTokenResult.claims?['role'];
          if (mounted) {
            setState(() {
              _isAdmin = (role == 'admin' || role == 'superadmin');
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
                      if (_isAdmin)
                        _MenuItem(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Admin Dashboard',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminDashboardScreen()),
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
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    final initial = (name?.isNotEmpty == true) ? name![0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
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
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFE879F9), // Design-matched pink
                  child: ClipOval(
                    child: profileImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: profileImageUrl!,
                            placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            errorWidget: (context, url, error) => Text(
                              initial,
                              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Outfit'),
                            ),
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          )
                        : Text(
                            initial,
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Outfit'),
                          ),
                  ),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentColor, // Bright blue
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ).animate().scale(delay: 400.ms),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            name ?? 'Guest User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Outfit',
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 6),
          Text(
            phone.isNotEmpty ? phone : (email ?? 'No contact info'),
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.8),
              fontFamily: 'Outfit',
              letterSpacing: 0.5,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkColor,
                fontFamily: 'Outfit',
              ),
            ),
          ).animate().fadeIn().slideX(begin: -0.05, end: 0),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9), // DESIGN: light blue/gray tint
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: AppTheme.primaryColor, size: 20),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                      onTap: item.onTap,
                    ),
                    if (index < items.length - 1)
                      const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
                  ],
                );
              }).toList(),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),
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

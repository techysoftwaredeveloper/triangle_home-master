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
import 'package:triangle_home/screens/profile/my_suggestions_screen.dart';
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

  int savedCount = 0;
  int activeBookingsCount = 0;
  int suggestionsCount = 0;
  int pointsEarned = 250; // Mock data

  Map<String, dynamic>? activeStay;
  Map<String, dynamic>? latestPayment;

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
    final collectionNames = ['users', 'hoster', 'student', 'guest'];

    try {
      // 1. Fetch Basic Profile
      bool profileFound = false;
      for (final collection in collectionNames) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(uid)
            .get();

        if (!doc.exists && phone != null) {
          doc = await FirebaseFirestore.instance
              .collection(collection)
              .doc(phone)
              .get();
        }

        if (doc.exists) {
          final data = doc.data()! as Map<String, dynamic>;
          final info = (data['info'] as Map?)?.cast<String, dynamic>() ?? {};

          String? foundName = info['name'] as String? ??
                             info['fullName'] as String? ??
                             data['name'] as String? ??
                             data['fullName'] as String? ??
                             data['displayName'] as String? ??
                             user.displayName;

          if (mounted) {
            setState(() {
              name = foundName;
              email = info['email'] as String? ?? data['email'] as String? ?? user.email;
              profileImageUrl = info['profileImage'] as String? ??
                  data['profileImage'] as String? ?? user.photoURL;
              _isHoster = (collection == 'hoster' || data['role'] == 'hoster');
            });
          }
          profileFound = true;
          break;
        }
      }

      if (!profileFound && mounted) {
          setState(() {
              name = user.displayName;
              email = user.email;
              profileImageUrl = user.photoURL;
          });
      }

      // 2. Fetch Stats
      final wishlistSnapshot = await FirebaseFirestore.instance
          .collection('wishlists')
          .where('user_id', isEqualTo: uid)
          .get();

      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('user_id', isEqualTo: uid)
          .get();

      // 3. Fetch Active Stay (Confirmed/CheckedIn)
      final activeStaySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('user_id', isEqualTo: uid)
          .where('status', whereIn: ['confirmed', 'checkedIn'])
          .limit(1)
          .get();

      if (activeStaySnapshot.docs.isNotEmpty) {
        final bookingData = activeStaySnapshot.docs.first.data();
        activeStay = {
          'id': activeStaySnapshot.docs.first.id,
          ...bookingData,
        };

        // Fetch latest payment for this booking
        final paymentSnapshot = await FirebaseFirestore.instance
            .collection('payments')
            .where('booking_id', isEqualTo: activeStaySnapshot.docs.first.id)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (paymentSnapshot.docs.isNotEmpty) {
          latestPayment = paymentSnapshot.docs.first.data();
        }
      }

      // Check for admin role in custom claims
      final idTokenResult = await user.getIdTokenResult(true);
      final role = idTokenResult.claims?['role'];

      if (mounted) {
        setState(() {
          _isAdmin = (role == 'admin' || role == 'superadmin');
          savedCount = wishlistSnapshot.size;
          activeBookingsCount = bookingsSnapshot.docs
              .where((doc) => doc.data()['status'] != 'cancelled' && doc.data()['status'] != 'checkedOut')
              .length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) setState(() => _isLoading = false);
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
      backgroundColor: const Color(0xFFF8FAFC), // DESIGN: Very light blue-gray background
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 46), // Extra space for the floating card offset
                  if (activeStay != null) ...[
                    _buildCurrentlyStaying(),
                    const SizedBox(height: 16),
                    _buildPaymentSummary(),
                    const SizedBox(height: 16),
                  ],
                  _buildSection(
                    title: 'Contributions',
                    items: [
                      _MenuItem(
                        icon: Icons.home_work_outlined,
                        title: 'Suggest a Property',
                        subtitle: 'Help others find a great place',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.lightbulb_outline_rounded,
                        title: 'My Suggestions',
                        subtitle: 'Track status of your suggestions',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MySuggestionsScreen()),
                        ),
                      ),
                      if (!_isHoster)
                        _MenuItem(
                          icon: Icons.person_add_alt_1_outlined,
                          title: 'Become a Host',
                          subtitle: 'List your property and earn',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HosterDashboardScreen()),
                          ),
                        ),
                    ],
                  ),
                  _buildSection(
                    title: 'Account',
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit Profile',
                        subtitle: 'Update your personal information',
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
                        subtitle: 'Manage your preferences',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen()),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.shield_outlined,
                        title: 'Privacy & Security',
                        subtitle: 'Manage your privacy and security',
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
                        subtitle: 'Get help and contact support',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HelpSupportScreen()),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        title: 'About Us',
                        subtitle: 'Learn more about Triangle Homes',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AboutScreen()),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.description_outlined,
                        title: 'Terms & Conditions',
                        subtitle: 'Read our terms and policies',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen()),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: InkWell(
                      onTap: () => _handleSignOut(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFEE2E2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Logout',
                                    style: TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                  Text(
                                    'Sign out from your account',
                                    style: TextStyle(
                                      color: const Color(0xFFDC2626).withOpacity(0.7),
                                      fontSize: 13,
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFFDC2626), size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background illustration
        Container(
          width: double.infinity,
          height: 280, // Reduced height for tighter fit
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A), // Dark navy
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: 20,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(Icons.home_work_rounded, size: 200, color: Colors.white),
                ),
              ),
            ],
          ),
        ),

        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        const Text(
                          'Profile',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: const Color(0xFFE879F9),
                                child: ClipOval(
                                  child: profileImageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: profileImageUrl!,
                                          fit: BoxFit.cover,
                                          width: 80,
                                          height: 80,
                                        )
                                      : Text(
                                          initial,
                                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
                                        ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt_outlined, size: 14, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name ?? 'Guest User',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 14),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Verified Mobile',
                                      style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                phone.isNotEmpty ? phone : (email ?? 'No contact info'),
                                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Stats Card (Floating)
            Transform.translate(
              offset: const Offset(0, 30),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(Icons.favorite_border_rounded, savedCount.toString(), 'Saved\nProperties', const Color(0xFFEC4899)),
                    _buildStatItem(Icons.calendar_today_outlined, activeBookingsCount.toString(), 'Bookings\nActive', const Color(0xFF22C55E)),
                    _buildStatItem(Icons.lightbulb_outline_rounded, suggestionsCount.toString(), 'Suggestions\nSubmitted', const Color(0xFFF59E0B)),
                    _buildStatItem(Icons.emoji_events_outlined, pointsEarned.toString(), 'Points\nEarned', const Color(0xFF8B5CF6)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A), fontFamily: 'Outfit')),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.2),
        ),
      ],
    );
  }

  Widget _buildCurrentlyStaying() {
    final propertyData = activeStay?['propertyData'] as Map? ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.home_outlined, color: Color(0xFF3B82F6), size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Currently Staying', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A), fontFamily: 'Outfit')),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(20)),
                child: const Text('Active Stay', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: propertyData['image'] ?? 'https://via.placeholder.com/150',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      propertyData['title'] ?? 'Hostel Name',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A), fontFamily: 'Outfit'),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(propertyData['location'] ?? 'Location', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStayingInfo('Room No.', 'A-203'),
                        _buildStayingInfo('Monthly Rent', '₹6,500'),
                        _buildStayingInfo('Next Payment', '18 May 2026', isDate: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Pay Rent', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.visibility_outlined, color: Color(0xFF0F172A), size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.phone_outlined, color: Color(0xFF0F172A), size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStayingInfo(String label, String value, {bool isDate = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: isDate ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Payment Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A), fontFamily: 'Outfit')),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Row(
                  children: const [
                    Text('View History', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPaymentDetail('Paid This Month', '₹6,500', icon: Icons.check_circle, iconColor: const Color(0xFF22C55E)),
              _buildPaymentDetail('Payment Status', 'Paid', isStatus: true),
              _buildPaymentDetail('Payment Method', 'UPI', isMethod: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetail(String label, String value, {IconData? icon, Color? iconColor, bool isStatus = false, bool isMethod = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: iconColor),
            ],
            if (isStatus) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                child: const Text('Paid', style: TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
            if (isMethod) ...[
              const SizedBox(width: 6),
              const Icon(Icons.flash_on_rounded, size: 12, color: Color(0xFFF59E0B)),
            ],
          ],
        ),
      ],
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
                color: Color(0xFF0F172A),
                fontFamily: 'Outfit',
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
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
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: const Color(0xFF64748B), size: 20),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          fontFamily: 'Outfit',
                        ),
                      ),
                      subtitle: item.subtitle != null
                        ? Text(item.subtitle!, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
                        : null,
                      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
                      onTap: item.onTap,
                    ),
                    if (index < items.length - 1)
                      const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}

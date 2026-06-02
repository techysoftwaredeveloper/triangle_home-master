import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/hoster/hoster_profile_details_screen.dart';
import 'package:triangle_home/screens/hoster/hoster_profile_extra_screens.dart';
import 'package:triangle_home/screens/hoster/owner_profile_edit_screen.dart';
import 'package:triangle_home/services/hoster_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/logout_confirmation_dialog.dart';
import 'package:triangle_home/splash_screen.dart';

class HosterProfileScreen extends StatefulWidget {
  const HosterProfileScreen({super.key});

  @override
  State<HosterProfileScreen> createState() => _HosterProfileScreenState();
}

class _HosterProfileScreenState extends State<HosterProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final HosterService _hosterService = HosterService();
  
  Stream<Map<String, dynamic>>? _profileDataStream;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _profileDataStream = _hosterService.getHosterProfileStatsStream(user.uid);
    }
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (context) => LogoutConfirmationDialog(
        onConfirm: () async {
          await _auth.signOut();
          if (!context.mounted) return;
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
    return StreamBuilder<Map<String, dynamic>>(
      stream: _profileDataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final stats = snapshot.data ?? {};
        final user = _auth.currentUser;
        final name = stats['hosterName'] ?? 'Hoster Name';
        final profileImage = stats['profileImage'];

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Hoster Profile',
              style: TextStyle(
                color: AppTheme.textDarkColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textDarkColor),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProfileHeader(stats),
                const SizedBox(height: 24),
                _buildVerificationStatus(stats),
                const SizedBox(height: 24),
                _buildProfileCompletionCard(stats),
                const SizedBox(height: 24),
                _buildMenuOptions(),
                const SizedBox(height: 32),
                _buildLogoutButton(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> stats) {
    final name = stats['hosterName'] ?? 'Jibin';
    final imageUrl = stats['profileImage'];
    final rating = stats['rating'] ?? 4.7;
    final reviews = stats['reviewCount'] ?? 128;
    final isVerified = stats['hosterVerified'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isVerified)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.shield_rounded, color: AppTheme.successColor, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Hoster Verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white10,
                  backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
                  child: imageUrl == null ? const Icon(Icons.person_rounded, size: 45, color: Colors.white54) : null,
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryColor, width: 3),
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Individual Owner',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white38, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                '$rating ($reviews)',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat(stats['totalProperties']?.toString() ?? '0', 'Properties'),
              _buildHeaderStat(stats['totalRooms']?.toString() ?? '0', 'Rooms'),
              _buildHeaderStat(stats['activeListings']?.toString() ?? '0', 'Active Listings'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeaderStat(String val, String label) {
    IconData icon;
    switch (label) {
      case 'Properties': icon = Icons.home_work_rounded; break;
      case 'Rooms': icon = Icons.meeting_room_rounded; break;
      default: icon = Icons.list_alt_rounded;
    }

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 16),
            const SizedBox(width: 6),
            Text(
              val,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildVerificationStatus(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Verification Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit'),
              ),
              const Icon(Icons.verified_user_rounded, color: AppTheme.successColor, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          _buildVerifItem('Email Verified', stats['emailVerified'] == true),
          _buildVerifItem('Phone Verified', stats['phoneVerified'] == true),
          _buildVerifItem('Identity Verified', stats['identityVerified'] == true),
          _buildVerifItem('Hoster Approved', stats['hosterVerified'] == true),
        ],
      ),
    );
  }

  Widget _buildVerifItem(String label, bool isVerified) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (isVerified ? AppTheme.successColor : AppTheme.warningColor).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVerified ? Icons.check_rounded : Icons.pending_rounded,
              color: isVerified ? AppTheme.successColor : AppTheme.warningColor,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textLightColor, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            isVerified ? 'Verified' : 'Pending',
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: isVerified ? AppTheme.successColor : AppTheme.warningColor
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletionCard(Map<String, dynamic> stats) {
    final completion = (stats['profileCompletion'] as num? ?? 0.0).toDouble();
    final percentage = (completion * 100).toInt();

    if (percentage == 100) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: completion,
                      strokeWidth: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor, fontFamily: 'Outfit'),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Completion',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDarkColor, fontFamily: 'Outfit'),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Complete your profile to build trust with tenants.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textLightColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerProfileEditScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: const Text('Complete Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildMenuTile(Icons.person_outline_rounded, 'Basic Information', color: Colors.blue, page: const HosterBasicInfoScreen()),
          _buildMenuTile(Icons.assignment_ind_outlined, 'Identity & Compliance', color: Colors.purple, page: const HosterIdentityScreen()),
          _buildMenuTile(Icons.business_center_outlined, 'Business Information', color: Colors.orange, page: const HosterBusinessInfoScreen()),
          _buildMenuTile(Icons.account_balance_outlined, 'Banking & Payouts', color: Colors.green, page: const HosterBankingScreen()),
          _buildMenuTile(Icons.home_work_outlined, 'Property Summary', color: Colors.indigo, page: const HosterPropertySummaryScreen()),
          _buildMenuTile(Icons.insights_rounded, 'Performance', color: Colors.red, page: const HosterPerformanceScreen()),
          _buildMenuTile(Icons.star_outline_rounded, 'Reviews & Ratings', color: Colors.amber, page: const HosterReviewsScreen()),
          _buildMenuTile(Icons.speed_rounded, 'Trust Score', color: Colors.teal, page: const HosterTrustScoreScreen()),
          _buildMenuTile(Icons.tune_rounded, 'Preferences', color: Colors.cyan, page: const HosterPreferencesScreen()),
          _buildMenuTile(Icons.contact_phone_outlined, 'Emergency Contact', color: Colors.deepOrange, page: const HosterEmergencyContactScreen()),
          _buildMenuTile(Icons.security_outlined, 'Security Center', color: Colors.blueGrey, page: const HosterSecurityCenterScreen()),
          _buildMenuTile(Icons.notifications_none_rounded, 'Notification Settings', isLast: true, color: Colors.pink, page: const HosterNotificationsScreen()),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String label, {bool isLast = false, required Color color, Widget? page}) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDarkColor, fontFamily: 'Outfit'),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMutedColor, size: 20),
            onTap: () {
              if (page != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => page));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HosterProfileDetailsScreen()));
              }
            },
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: _handleSignOut,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.errorColor.withOpacity(0.1)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.errorColor, size: 20),
            SizedBox(width: 12),
            Text(
              'Logout Account',
              style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

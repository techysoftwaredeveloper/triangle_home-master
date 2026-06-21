import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/screens/profile/edit_profile_screen.dart';
import 'package:triangle_home/screens/profile/stay_info_screen.dart';
import 'package:triangle_home/screens/profile/my_suggestions_screen.dart';
import 'package:triangle_home/screens/profile/notifications_screen.dart';
import 'package:triangle_home/screens/profile/privacy_security_screen.dart';
import 'package:triangle_home/screens/profile/help_support_screen.dart';
import 'package:triangle_home/screens/profile/about_screen.dart';
import 'package:triangle_home/screens/profile/profile_details_screen.dart';
import 'package:triangle_home/screens/profile/verification_center_screen.dart';
import 'package:triangle_home/screens/profile/terms_conditions_screen.dart';
import 'package:triangle_home/screens/profile/saved_payments_screen.dart';
import 'package:triangle_home/screens/list_property/intro_screen.dart';
import 'package:triangle_home/screens/auth/login_screen.dart';
import 'package:triangle_home/screens/hoster/partner_onboarding_screen.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';
import 'package:triangle_home/widgets/logout_confirmation_dialog.dart';
import 'package:triangle_home/splash_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBottomNav;
  const ProfileScreen({super.key, this.showBottomNav = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;
  Map<String, dynamic>? activeStay;
  int savedCount = 0;
  int bookingsCount = 0;

  final Color _primaryBlue = AppTheme.primaryColor;
  final Color _accentBlue = AppTheme.accentColor;
  final Color _bgGray = AppTheme.scaffoldBgColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final user = _auth.currentUser;
    if (user != null) {
      _userStream = _firestore.collection('users').doc(user.uid).snapshots();
      _loadInitialData();
      _reloadAndSyncStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadAndSyncStatus();
    }
  }

  Future<void> _reloadAndSyncStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed == null) return;

      Map<String, dynamic> updates = {};
      if (refreshed.emailVerified) updates['emailVerified'] = true;
      if (refreshed.phoneNumber != null) updates['phoneVerified'] = true;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(refreshed.uid).set({
          'verification': updates,
        }, SetOptions(merge: true));
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<void> _loadInitialData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final uid = user.uid;

      // Load stay info (one-time or could be stream, keeping fetch for now)
      final wishlistSnapshot =
          await _firestore
              .collection('wishlists')
              .where('user_id', isEqualTo: uid)
              .get();
      final bookingsSnapshot =
          await _firestore
              .collection('bookings')
              .where('user_id', isEqualTo: uid)
              .get();

      if (mounted) {
        setState(() {
          savedCount = wishlistSnapshot.size;
          bookingsCount = bookingsSnapshot.size;
        });
      }

      // Fetch Active Stay
      final activeStaySnapshot =
          await _firestore
              .collection('bookings')
              .where('user_id', isEqualTo: uid)
              .where('status', whereIn: ['confirmed', 'checkedIn'])
              .limit(1)
              .get();

      if (activeStaySnapshot.docs.isNotEmpty) {
        final stayData = activeStaySnapshot.docs.first.data();
        activeStay = {
          'id': activeStaySnapshot.docs.first.id,
          ...stayData,
        };

        // Fetch Hoster Details
        final hosterId = stayData['hoster_id'] ?? stayData['hosterId'];
        if (hosterId != null) {
          final hosterDoc =
              await _firestore.collection('users').doc(hosterId).get();
          if (hosterDoc.exists) {
            final hosterData = hosterDoc.data()!;
            final info = hosterData['info'] as Map? ?? {};
            activeStay!['hosterName'] = info['name'] ?? 'Property Manager';
            activeStay!['hosterPhone'] = info['phoneNumber'] ?? 'N/A';
          }
        }
      } else {
        activeStay = null;
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading initial profile data: $e');
    }
  }

  double _calculateProfileCompletion(Map<String, dynamic>? userData) {
    if (userData == null) return 0.0;
    double score = 0;

    final info = userData['info'] as Map? ?? {};
    final sInfo = userData['student_info'] as Map? ?? {};
    final pInfo = userData['professional_info'] as Map? ?? {};
    final prefs = userData['housing_preferences'] as Map? ?? {};
    final emergency = userData['emergency_contact'] as Map? ?? {};
    final role = userData['role'] ?? 'student';

    // Personal Info (20%)
    if (info['name'] != null && info['name'].toString().isNotEmpty) score += 10;
    if (info['dob'] != null && info['gender'] != null) score += 10;

    // Professional/Student Info (20%)
    if (role == 'student') {
      if (sInfo['college'] != null && sInfo['college'].toString().isNotEmpty) {
        score += 10;
      }
      if (sInfo['course'] != null && sInfo['course'].toString().isNotEmpty) {
        score += 10;
      }
    } else {
      if (pInfo['companyName'] != null &&
          pInfo['companyName'].toString().isNotEmpty) {
        score += 10;
      }
      if (pInfo['jobTitle'] != null && pInfo['jobTitle'].toString().isNotEmpty) {
        score += 10;
      }
    }

    // Housing Preferences (20%)
    if (prefs['preferredCity'] != null) score += 5;
    if (prefs['budgetMax'] != null) score += 5;
    if (prefs['lookingFor'] != null && (prefs['lookingFor'] as List).isNotEmpty) {
      score += 5;
    }
    if (prefs['stayDuration'] != null) score += 5;

    // Emergency Contact (20%)
    if (emergency['name'] != null && emergency['name'].toString().isNotEmpty) {
      score += 10;
    }
    if (emergency['phone'] != null && emergency['phone'].toString().isNotEmpty) {
      score += 10;
    }

    // Profile Photo (20%)
    if (info['profileImage'] != null) score += 20;

    return (score / 100).clamp(0.0, 1.0);
  }

  int _calculateTrustScore(Map<String, dynamic>? userData) {
    if (userData == null) return 0;
    double score = 0;
    final verif = userData['verification'] as Map? ?? {};

    if (verif['govIdVerified'] == true) score += 25;
    if (verif['roleIdVerified'] == true) score += 20;
    if (verif['addressVerified'] == true) score += 15;
    if (verif['emergencyContactVerified'] == true) score += 10;
    score += _calculateProfileCompletion(userData) * 10;
    if (bookingsCount > 0) score += 10;
    score += 10;

    return score.toInt();
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      builder:
          (context) => LogoutConfirmationDialog(
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
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data?.data();
        final user = _auth.currentUser;
        final info = userData?['info'] as Map? ?? {};
        final role = userData?['role'] ?? 'student';
        final verif = userData?['verification'] as Map? ?? {};

        final double completion = _calculateProfileCompletion(userData);
        final int trustScore = _calculateTrustScore(userData);

        return Scaffold(
          backgroundColor: _bgGray,
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                elevation: 0,
                backgroundColor: _primaryBlue,
                automaticallyImplyLeading: false,
                centerTitle: false,
                title: const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
                    child: _buildHeaderContent(user, info, role, trustScore),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    children: [
                      // Hoster Application Status Hook
                      if (role != 'hoster')
                        FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('hoster_requests')
                                  .doc(user?.uid)
                                  .get(),
                          builder: (context, reqSnapshot) {
                            if (reqSnapshot.hasData &&
                                reqSnapshot.data!.exists) {
                              final reqData =
                                  reqSnapshot.data!.data()
                                      as Map<String, dynamic>;
                              final status = reqData['status'] ?? 'pending';
                              return Container(
                                margin: const EdgeInsets.only(top: 24),
                                decoration: BoxDecoration(
                                  color:
                                      status == 'pending'
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        status == 'pending'
                                            ? Colors.orange.withValues(
                                              alpha: 0.3,
                                            )
                                            : Colors.red.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    leading: Icon(
                                      status == 'pending'
                                          ? Icons.hourglass_empty_rounded
                                          : Icons.error_outline_rounded,
                                      color:
                                          status == 'pending'
                                              ? Colors.orange
                                              : Colors.red,
                                    ),
                                    title: Text(
                                      'Hoster Application: ${status[0].toUpperCase() + status.substring(1)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color:
                                            status == 'pending'
                                                ? Colors.orange[800]
                                                : Colors.red[800],
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Tap to view details or manage application',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => const PartnerOnboardingScreen(),
                                          ),
                                        ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                      if (completion < 1.0) ...[
                        const SizedBox(height: 24),
                        _buildHeaderCompletionCard(completion),
                      ],
                      const SizedBox(height: 24),
                      _buildQuickStatsRow(completion),
                      if (activeStay != null) ...[
                        const SizedBox(height: 24),
                        _buildCurrentlyStaying(),
                      ],
                      if (role != 'hoster' &&
                          _calculateBookingReadiness(userData) < 1.0) ...[
                        const SizedBox(height: 24),
                        _buildBookingReadinessCard(userData, role),
                      ],
                      const SizedBox(height: 24),
                      _buildAboutMeCard(userData, role),
                      const SizedBox(height: 24),
                      _buildHousingPreferencesCard(userData),
                      const SizedBox(height: 24),
                      _buildEmergencyContactCard(userData, verif),
                      if (role != 'hoster' && !_isFullyVerified(verif)) ...[
                        const SizedBox(height: 24),
                        _buildVerificationCenterCard(verif),
                      ],
                      const SizedBox(height: 24),
                      _buildContributionsEarningsCard(),
                      const SizedBox(height: 24),
                      _buildInviteFriendsCard(),
                      const SizedBox(height: 24),
                      _buildAccountCenterCard(),
                      const SizedBox(height: 24),
                      _buildSupportAboutCard(),
                      const SizedBox(height: 32),
                      _buildLogoutCard(),
                      const SizedBox(height: 20),
                      const Text(
                        'BETA 1.1.1',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar:
              widget.showBottomNav
                  ? const HomeBottomNavBar(selectedIndex: 3)
                  : null,
        );
      },
    );
  }

  Widget _buildHeaderContent(
    User? user,
    Map info,
    String role,
    int trustScore,
  ) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundImage:
                    info['profileImage'] != null
                        ? CachedNetworkImageProvider(info['profileImage'])
                        : null,
                child:
                    info['profileImage'] == null
                        ? const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
                        )
                        : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 12,
                  color: _primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info['name'] ?? user?.displayName ?? 'Guest User',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _accentBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: Colors.white,
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      role[0].toUpperCase() + role.substring(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _buildMiniBadge(
                Icons.check_circle,
                'Verified Mobile',
                info['phoneNumber'] != null
                    ? AppTheme.successGreen
                    : Colors.white24,
              ),
              const SizedBox(height: 2),
              _buildMiniBadge(
                Icons.check_circle,
                'Verified Email',
                user?.emailVerified == true
                    ? AppTheme.successGreen
                    : Colors.white24,
              ),
            ],
          ),
        ),
        _buildTrustScoreWidget(trustScore),
      ],
    );
  }

  Widget _buildMiniBadge(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color == Colors.white24 ? Colors.white38 : color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }

  Widget _buildTrustScoreWidget(int score) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.shield, color: AppTheme.successGreen, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Trust\nScore',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '/100',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
          child: Text(
            score > 80
                ? 'Excellent'
                : score > 60
                ? 'Good'
                : 'Fair',
            style: TextStyle(
              color: AppTheme.successGreen,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCompletionCard(double value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Completion',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textColor,
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: AppTheme.secondaryColor,
              valueColor: AlwaysStoppedAnimation<Color>(_accentBlue),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Almost there! Complete your profile to unlock bookings.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightColor,
                  ),
                ),
              ),
              TextButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
                child: Row(
                  children: [
                    Text(
                      'Complete Now',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: AppTheme.accentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(double completion) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatBox(
          Icons.favorite_outline,
          '$savedCount',
          'Wishlist',
          const Color(0xFFEC4899),
        ),
        const SizedBox(width: 12),
        _buildStatBox(
          Icons.calendar_today_outlined,
          '$bookingsCount',
          'Bookings',
          AppTheme.successGreen,
        ),
        const SizedBox(width: 12),
        _buildStatBox(
          Icons.verified_user_outlined,
          '${(completion * 100).toInt()}%',
          'Verified',
          AppTheme.warningColor,
        ),
        const SizedBox(width: 12),
        _buildStatBox(
          Icons.emoji_events_outlined,
          '0',
          'Points',
          const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _buildStatBox(IconData icon, String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              val,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: AppTheme.textLightColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentlyStaying() {
    final propertyData = activeStay?['propertyData'] as Map? ?? {};
    final hosterName = activeStay?['hosterName'] ?? 'Property Manager';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Icon(
                  Icons.home_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Your Current Stay',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textColor,
                  fontFamily: 'Outfit',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: AppTheme.successGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Hero(
                tag: 'stay_image',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  child: CachedNetworkImage(
                    imageUrl:
                        propertyData['image'] ??
                        'https://via.placeholder.com/150',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorWidget:
                        (context, url, error) => Container(
                          width: 90,
                          height: 90,
                          color: AppTheme.secondaryColor,
                          child: Icon(
                            Icons.business_rounded,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      propertyData['title'] ?? 'Sunrise Residency',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppTheme.textColor,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.textLightColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            propertyData['location'] ?? 'Kozhikode, Kerala',
                            style: TextStyle(
                              color: AppTheme.textLightColor,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStayDetail(
                          'Room',
                          activeStay?['roomNumber'] ?? activeStay?['selectedRoomNumber'] ?? 'N/A',
                        ),
                        const SizedBox(width: 24),
                        _buildStayDetail('Hoster', hosterName),
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
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Pay Rent',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StayInfoScreen(booking: activeStay!),
                      ),
                    ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.dividerColor),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  minimumSize: const Size(54, 52),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppTheme.textColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStayDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  double _calculateBookingReadiness(Map<String, dynamic>? userData) {
    if (userData == null) return 0.0;
    final verif = userData['verification'] as Map? ?? {};
    final user = _auth.currentUser;

    int totalSteps = 6;
    int completedSteps = 0;

    if (verif['phoneVerified'] == true || user?.phoneNumber != null) completedSteps++;
    if (verif['emailVerified'] == true || user?.emailVerified == true) completedSteps++;
    if (verif['roleIdVerified'] == true) completedSteps++;
    if (verif['govIdVerified'] == true) completedSteps++;
    if (verif['addressVerified'] == true) completedSteps++;
    if (verif['selfieVerified'] == true) completedSteps++;

    return (completedSteps / totalSteps).clamp(0.0, 1.0);
  }

  bool _isFullyVerified(Map verif) {
    final user = _auth.currentUser;
    return (verif['phoneVerified'] == true || user?.phoneNumber != null) &&
        (verif['emailVerified'] == true || user?.emailVerified == true) &&
        verif['roleIdVerified'] == true &&
        verif['govIdVerified'] == true &&
        verif['addressVerified'] == true;
  }

  Widget _buildBookingReadinessCard(
    Map<String, dynamic>? userData,
    String role,
  ) {
    final verif = userData?['verification'] as Map? ?? {};
    double readiness = _calculateBookingReadiness(userData);

    return _buildSectionCard(
      title: 'Booking Readiness',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Complete remaining steps to start booking.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightColor,
                  ),
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: readiness,
                      strokeWidth: 5,
                      backgroundColor: AppTheme.secondaryColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.accentColor,
                      ),
                    ),
                  ),
                  Text(
                    '${(readiness * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReadinessItem(
            verif['phoneVerified'] ?? false,
            'Mobile Verified',
          ),
          _buildReadinessItem(
            verif['emailVerified'] ?? false,
            'Email Verified',
          ),
          _buildReadinessItem(
            verif['roleIdVerified'] ?? false,
            role == 'student'
                ? 'Student Verification'
                : 'Employment Verification',
          ),
          _buildReadinessItem(
            verif['govIdVerified'] ?? false,
            'Government ID',
            isPending: verif['govIdStatus'] == 'pending',
          ),
          _buildReadinessItem(
            verif['addressVerified'] ?? false,
            'Address Verification',
            isPending: verif['addressStatus'] == 'pending',
          ),
          _buildReadinessItem(
            verif['selfieVerified'] ?? false,
            'Selfie Verification',
            isPending: verif['selfieStatus'] == 'pending',
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerificationCenterScreen(),
                  ),
                ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
            child: const Text(
              'Complete Verification',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessItem(
    bool isDone,
    String label, {
    bool isPending = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isDone
                ? Icons.check_circle
                : (isPending
                    ? Icons.access_time_filled
                    : Icons.circle_outlined),
            size: 20,
            color:
                isDone
                    ? AppTheme.successGreen
                    : (isPending
                        ? AppTheme.warningColor
                        : AppTheme.textMutedColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: AppTheme.textColor),
          ),
          const Spacer(),
          if (isPending)
            Text(
              'Pending',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.warningColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAboutMeCard(Map<String, dynamic>? userData, String role) {
    final sInfo = userData?['student_info'] as Map? ?? {};
    final pInfo = userData?['professional_info'] as Map? ?? {};

    return _buildSectionCard(
      title: 'About Me',
      trailing: TextButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ).then((_) => _loadInitialData()),
        child: const Text(
          'Edit',
          style: TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Column(
        children: [
          if (role == 'student') ...[
            _buildInfoTile(
              Icons.account_balance_outlined,
              'College / University',
              sInfo['college'] ?? 'N/A',
            ),
            _buildInfoTile(
              Icons.book_outlined,
              'Course',
              sInfo['course'] ?? 'N/A',
            ),
            _buildInfoTile(
              Icons.timer_outlined,
              'Semester',
              sInfo['semester'] ?? 'N/A',
            ),
            _buildInfoTile(
              Icons.badge_outlined,
              'Student ID',
              sInfo['studentId'] ?? 'N/A',
            ),
          ] else ...[
            _buildInfoTile(
              Icons.business_outlined,
              'Company',
              pInfo['companyName'] ?? 'N/A',
            ),
            _buildInfoTile(
              Icons.work_outline,
              'Designation',
              pInfo['jobTitle'] ?? 'N/A',
            ),
            _buildInfoTile(
              Icons.location_on_outlined,
              'Work Location',
              pInfo['workLocation'] ?? 'N/A',
            ),
            _buildInfoTile(
              Icons.history,
              'Experience',
              pInfo['experience'] ?? 'N/A',
            ),
          ],
          const SizedBox(height: 16),
          InkWell(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileDetailsScreen()),
                ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Full Details',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFF2563EB)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHousingPreferencesCard(Map<String, dynamic>? userData) {
    final prefs = userData?['housing_preferences'] as Map? ?? {};

    List<String> locations = [];
    if (prefs['preferredLocations'] is List) {
      locations = List<String>.from(prefs['preferredLocations']);
    } else if (prefs['preferredLocations'] is String) {
      locations = [prefs['preferredLocations']];
    } else if (prefs['preferredCity'] != null) {
      locations = [prefs['preferredCity']];
    }

    return _buildSectionCard(
      title: 'Housing Preferences',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoTile(
            Icons.home_outlined,
            'Looking For',
            prefs['propertyType'] ?? 'PG',
          ),
          _buildInfoTile(
            Icons.payments_outlined,
            'Budget Range',
            '₹${prefs['budgetMin'] ?? 10000} - ₹${prefs['budgetMax'] ?? 20000}',
          ),
          _buildInfoTile(
            Icons.location_on_outlined,
            'Preferred Locations',
            locations.isEmpty ? 'N/A' : locations.join(', '),
          ),
          _buildInfoTile(
            Icons.people_outline,
            'Family Size',
            prefs['familySize'] == 5
                ? '5+'
                : (prefs['familySize'] ?? 1).toString(),
          ),
          _buildInfoTile(
            Icons.calendar_today_outlined,
            'Move-in Date',
            prefs['moveInDate'] != null
                ? DateFormat(
                  'MMMM yyyy',
                ).format((prefs['moveInDate'] as Timestamp).toDate())
                : 'N/A',
          ),
          _buildInfoTile(
            Icons.timer_outlined,
            'Stay Duration',
            prefs['stayDuration'] ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(Map<String, dynamic>? userData, Map verif) {
    final emergency = userData?['emergency_contact'] as Map? ?? {};
    return _buildSectionCard(
      title: 'Emergency Contact',
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Icon(
              Icons.phone_in_talk_outlined,
              color: AppTheme.errorColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      emergency['name'] ?? 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (verif['emergencyContactVerified'] == true)
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                Text(
                  emergency['relationship'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightColor,
                  ),
                ),
                Text(
                  emergency['phone'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCenterCard(Map verif) {
    return _buildSectionCard(
      title: 'Verification Center',
      child: Column(
        children: [
          _buildVerifLinkTile(
            Icons.phone_android_outlined,
            'Mobile Number',
            verif['phoneVerified'] == true ? 'Verified' : 'Pending',
            verif['phoneVerified'] == true
                ? AppTheme.successGreen
                : AppTheme.warningColor,
          ),
          _buildVerifLinkTile(
            Icons.email_outlined,
            'Email Address',
            verif['emailVerified'] == true ? 'Verified' : 'Pending',
            verif['emailVerified'] == true
                ? AppTheme.successGreen
                : AppTheme.warningColor,
          ),
          _buildVerifLinkTile(
            Icons.school_outlined,
            'Professional ID',
            verif['roleIdVerified'] == true ? 'Verified' : 'Pending',
            verif['roleIdVerified'] == true
                ? AppTheme.successGreen
                : AppTheme.warningColor,
          ),
          _buildVerifLinkTile(
            Icons.assignment_ind_outlined,
            'Government ID',
            verif['govIdVerified'] == true ? 'Verified' : 'Pending',
            verif['govIdVerified'] == true
                ? AppTheme.successGreen
                : AppTheme.warningColor,
          ),
          _buildVerifLinkTile(
            Icons.location_on_outlined,
            'Address Verification',
            verif['addressVerified'] == true ? 'Verified' : 'Pending',
            verif['addressVerified'] == true
                ? AppTheme.successGreen
                : AppTheme.warningColor,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerificationCenterScreen(),
                  ),
                ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              side: BorderSide(color: AppTheme.dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Go to Verification Center',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward, size: 16, color: AppTheme.textColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionsEarningsCard() {
    return _buildSectionCard(
      title: 'Contributions & Earnings',
      child: Column(
        children: [
          _buildLinkRow(
            Icons.person_add_alt_1_outlined,
            'Become a Host',
            'List your property and earn',
            const Color(0xFF8B5CF6),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ListPropertyIntroScreen(
                        onGetStarted: () {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null || user.isAnonymous) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LoginScreen(isStudent: false),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PartnerOnboardingScreen(),
                              ),
                            );
                          }
                        },
                      ),
                ),
              );
            },
          ),
          _buildLinkRow(
            Icons.home_work_outlined,
            'Suggest a Property',
            'Help others find a great place',
            const Color(0xFF10B981),
          ),
          _buildLinkRow(
            Icons.lightbulb_outline_rounded,
            'My Suggestions',
            'Track status of your suggestions',
            const Color(0xFFE11D48),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MySuggestionsScreen(),
                  ),
                ),
          ),
          _buildLinkRow(
            Icons.emoji_events_outlined,
            'Rewards & Points',
            'View points, history & offers',
            const Color(0xFFF59E0B),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '250 pts',
                style: TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteFriendsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite Friends & Earn',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Earn 100 points for every\nsuccessful booking.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Image.network(
                'https://cdn-icons-png.flaticon.com/512/3233/3233486.png',
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people_outline, color: Color(0xFF94A3B8), size: 36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE9FE)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Referral Code',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'TRIANGLE250',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: 'TRIANGLE250'));
                    Fluttertoast.showToast(msg: 'Referral code copied!');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.share_outlined,
              size: 18,
              color: Colors.white,
            ),
            label: const Text(
              'Share & Invite Friends',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCenterCard() {
    return _buildSectionCard(
      title: 'Account Center',
      child: Column(
        children: [
          _buildAccountLink(
            Icons.person_outline_rounded,
            'Edit Profile',
            'Update your personal information',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
          ),
          _buildAccountLink(
            Icons.notifications_none_rounded,
            'Notifications',
            'Manage your preferences',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
          ),
          _buildAccountLink(
            Icons.payment_outlined,
            'Saved Payments',
            'Manage cards & payment methods',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SavedPaymentsScreen(),
                  ),
                ),
          ),
          _buildAccountLink(
            Icons.shield_outlined,
            'Privacy & Security',
            'Manage your privacy and security',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacySecurityScreen(),
                  ),
                ),
          ),
          _buildAccountLink(
            Icons.settings_outlined,
            'Settings',
            'App settings and preferences',
          ),
        ],
      ),
    );
  }

  Widget _buildSupportAboutCard() {
    return _buildSectionCard(
      title: 'Support & About',
      child: Column(
        children: [
          _buildAccountLink(
            Icons.help_outline_rounded,
            'Help & Support',
            'Get help and contact support',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                ),
          ),
          _buildAccountLink(
            Icons.info_outline_rounded,
            'About Triangle Homes',
            'Learn more about us',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
          ),
          _buildAccountLink(
            Icons.description_outlined,
            'Terms & Conditions',
            'Read our terms and policies',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermsConditionsScreen(),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard() {
    return InkWell(
      onTap: _handleSignOut,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: AppTheme.errorColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  Text(
                    'Sign out from your account',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.errorColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.errorColor, size: 20),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---
  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                  fontFamily: 'Outfit',
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String val, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textMutedColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLightColor,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      val,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifLinkTile(
    IconData icon,
    String label,
    String status,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textMutedColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 16, color: color),
        ],
      ),
    );
  }

  Widget _buildLinkRow(
    IconData icon,
    String title,
    String sub,
    Color color, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textColor,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textLightColor,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(Icons.chevron_right, size: 20, color: AppTheme.dividerColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountLink(
    IconData icon,
    String title,
    String sub, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.textLightColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textColor,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textLightColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppTheme.dividerColor),
          ],
        ),
      ),
    );
  }
}

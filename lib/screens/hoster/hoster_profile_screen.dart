import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triangle_home/screens/hoster/partner_onboarding_screen.dart';
import 'package:triangle_home/screens/hoster/hoster_profile_detail_screen.dart';
import 'package:triangle_home/services/hoster_service.dart';
import 'package:triangle_home/widgets/logout_confirmation_dialog.dart';
import 'package:triangle_home/splash_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';


class HosterProfileScreen extends StatefulWidget {
  const HosterProfileScreen({super.key});

  @override
  State<HosterProfileScreen> createState() => _HosterProfileScreenState();
}

class _HosterProfileScreenState extends State<HosterProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final HosterService _hosterService = HosterService();

  Stream<Map<String, dynamic>>? _profileDataStream;
  bool _isUploading = false;

  static const _green = Color(0xFF1B4332);
  static const _greenMid = Color(0xFF2D6A4F);
  static const _accent = Color(0xFF40916C);
  static const _verified = Color(0xFF16A34A);
  static const _verifiedBg = Color(0xFFDCFCE7);
  static const _amber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _profileDataStream =
          _hosterService.getHosterProfileStatsStream(user.uid);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
        await ref.putFile(File(picked.path));
        final url = await ref.getDownloadURL();
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'info.profileImage': url,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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
    if (_profileDataStream == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: _profileDataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final stats = snapshot.data ?? {};

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header SliverAppBar ───────────────────────────────
              SliverAppBar(
                expandedHeight: 290,
                pinned: true,
                backgroundColor: _green,
                elevation: 0,
                title: const Text(
                  'Hoster Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Outfit',
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded,
                        color: Colors.white),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(stats),
                ),
              ),

              // ── Content ───────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildVerificationStatus(stats),
                    const SizedBox(height: 14),
                    _buildProfileCompletion(stats),
                    const SizedBox(height: 14),
                    _buildMenuTiles(stats),
                    const SizedBox(height: 14),
                    _buildLogoutButton(),
                    const SizedBox(height: 90),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Dark green header ───────────────────────────────────────────────────────
  Widget _buildHeader(Map<String, dynamic> stats) {
    final imageUrl = stats['profileImage'] as String?;
    final isVerified = stats['hosterVerified'] == true;
    final name = (stats['hosterName'] ?? 'Host').toString();
    final role = (stats['hosterRole'] ?? 'Individual Owner').toString();
    final rating = (stats['rating'] as num?)?.toDouble() ?? 0.0;
    final reviews = (stats['reviewCount'] as num?)?.toInt() ?? 0;
    final totalProps = stats['totalProperties']?.toString() ?? '0';
    final totalRooms = stats['totalRooms']?.toString() ?? '0';
    final activeListings = stats['activeListings']?.toString() ?? '0';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_green, _greenMid],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadImage,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.white24,
                            backgroundImage: imageUrl != null && !_isUploading
                                ? CachedNetworkImageProvider(imageUrl)
                                : null,
                            child: _isUploading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : (imageUrl == null
                                    ? const Icon(Icons.person_rounded,
                                        size: 42, color: Colors.white)
                                    : null),
                          ),
                        ),
                        // Edit button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              '$rating ($reviews)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _verifiedBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: _verified, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Hoster Verified',
                            style: TextStyle(
                              color: _verified,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statPill(Icons.home_work_outlined, totalProps,
                        'Properties'),
                    _vDivider(),
                    _statPill(Icons.meeting_room_outlined, totalRooms, 'Rooms'),
                    _vDivider(),
                    _statPill(
                        Icons.list_alt_rounded, activeListings, 'Active Listings'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statPill(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(val,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
        Text(label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 10,
            )),
      ],
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 48,
        color: Colors.white.withValues(alpha: 0.2),
      );

  // ── Verification Status (list rows with ticks) ──────────────────────────────
  Widget _buildVerificationStatus(Map<String, dynamic> stats) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          _verifRow('Email Verified', stats['emailVerified'] == true),
          _verifRow('Phone Verified', stats['phoneVerified'] == true),
          _verifRow('Identity Verified', stats['identityVerified'] == true),
          if (stats['accountStatus'] == 'pending')
            _verifRow('Final Approval', false, isPending: true),
          _verifRow('Hoster Verified', stats['hosterVerified'] == true,
              isLast: true),
        ],
      ),
    );
  }

  Widget _verifRow(String label, bool done, {bool isLast = false, bool isPending = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : isPending ? Icons.access_time_filled_rounded : Icons.radio_button_unchecked_rounded,
                color: done ? AppTheme.forestGreen : isPending ? _amber : const Color(0xFFCBD5E1),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (done)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.forestGreen,
                  size: 18,
                ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1),
      ],
    );
  }

  // ── Profile Completion (circular ring) ──────────────────────────────────────
  Widget _buildProfileCompletion(Map<String, dynamic> stats) {
    final double pct = ((stats['profileCompletion'] ?? 0.0) as num).toDouble();
    final int pctInt = (pct * 100).toInt();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Completion',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circular ring
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _RingPainter(pct),
                  child: Center(
                    child: Text(
                      '$pctInt%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pctInt >= 90
                          ? 'Almost done!'
                          : pctInt >= 60
                              ? 'Almost there!'
                              : 'Getting started',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Complete your profile\nto build more trust.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PartnerOnboardingScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Complete Now',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 12 separate menu cards with real data subtitles ──────────────────────────
  Widget _buildMenuTiles(Map<String, dynamic> s) {
    // helpers
    String masked(String acc) {
      if (acc.length > 4) return '•••• ${acc.substring(acc.length - 4)}';
      return acc.isEmpty ? 'Not added' : acc;
    }

    String kycStatus() {
      int count = 0;
      if (s['aadhaarVerified'] == true) count++;
      if (s['panVerified'] == true) count++;
      if (s['drivingLicenseVerified'] == true) count++;
      if (s['passportVerified'] == true) count++;
      return count == 0 ? 'No documents' : '$count doc${count > 1 ? 's' : ''} verified';
    }

    String bankSubtitle() {
      final name = (s['bankName'] as String?) ?? '';
      final acc = (s['bankAccountNo'] as String?) ?? '';
      if (name.isNotEmpty) return '$name  ${masked(acc)}';
      if (acc.isNotEmpty) return masked(acc);
      return 'Not configured';
    }

    String prefSubtitle() {
      final tenants = s['prefTenants'];
      if (tenants is List && tenants.isNotEmpty) {
        return tenants.take(2).join(', ');
      }
      final gender = (s['prefGender'] as String?) ?? '';
      return gender.isNotEmpty ? gender : 'Not set';
    }

    String emergencySubtitle() {
      final name = (s['emergencyContactName'] as String?) ?? '';
      final phone = (s['emergencyContactPhone'] as String?) ?? '';
      if (name.isNotEmpty) return name;
      if (phone.isNotEmpty) return phone;
      return 'Not added';
    }

    final name = (s['hosterName'] as String?) ?? '';
    final email = (s['email'] as String?) ?? '';
    final phone = (s['phone'] as String?) ?? '';
    final basicSub = [name, email.isNotEmpty ? email : phone]
        .where((v) => v.isNotEmpty)
        .take(1)
        .join(' · ');

    final tiles = [
      (
        icon: Icons.person_outline_rounded,
        color: const Color(0xFF6366F1),
        title: 'Basic Information',
        sub: basicSub.isNotEmpty ? basicSub : 'Name, gender, address',
        section: HosterProfileSection.basicInfo,
      ),
      (
        icon: Icons.shield_outlined,
        color: const Color(0xFF0EA5E9),
        title: 'Identity & Compliance',
        sub: kycStatus(),
        section: HosterProfileSection.identity,
      ),
      (
        icon: Icons.business_center_outlined,
        color: const Color(0xFF8B5CF6),
        title: 'Business Information',
        sub: (s['hosterRole'] as String?)?.isNotEmpty == true
            ? s['hosterRole'] as String
            : 'Host type & experience',
        section: HosterProfileSection.business,
      ),
      (
        icon: Icons.account_balance_outlined,
        color: const Color(0xFF10B981),
        title: 'Banking & Payouts',
        sub: bankSubtitle(),
        section: HosterProfileSection.banking,
      ),
      (
        icon: Icons.home_work_outlined,
        color: const Color(0xFF3B82F6),
        title: 'Property Summary',
        sub: '${s['totalProperties'] ?? 0} properties · ${s['activeListings'] ?? 0} active',
        section: HosterProfileSection.propertySummary,
      ),
      (
        icon: Icons.analytics_outlined,
        color: const Color(0xFFF59E0B),
        title: 'Performance',
        sub: '${s['occupancy'] ?? 0}% occupancy · ${s['activeResidents'] ?? 0} residents',
        section: HosterProfileSection.performance,
      ),
      (
        icon: Icons.star_outline_rounded,
        color: const Color(0xFFEF4444),
        title: 'Reviews & Ratings',
        sub: '${(s['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'} ★  (${s['reviewCount'] ?? 0} reviews)',
        section: HosterProfileSection.reviews,
      ),
      (
        icon: Icons.verified_user_outlined,
        color: const Color(0xFF06B6D4),
        title: 'Trust Score',
        sub: 'Score: ${s['trustScore'] ?? (s['hosterVerified'] == true ? 91 : 45)}/100 · ${s['hosterVerified'] == true ? 'Verified' : 'Pending'}',
        section: HosterProfileSection.trustScore,
      ),
      (
        icon: Icons.tune_rounded,
        color: const Color(0xFF84CC16),
        title: 'Preferences',
        sub: prefSubtitle(),
        section: HosterProfileSection.preferences,
      ),
      (
        icon: Icons.contact_emergency_outlined,
        color: const Color(0xFFF97316),
        title: 'Emergency Contact',
        sub: emergencySubtitle(),
        section: HosterProfileSection.emergency,
      ),
      (
        icon: Icons.security_outlined,
        color: const Color(0xFF6B7280),
        title: 'Security Center',
        sub: 'Password & 2FA settings',
        section: HosterProfileSection.security,
      ),
      (
        icon: Icons.notifications_none_rounded,
        color: const Color(0xFFEC4899),
        title: 'Notification Settings',
        sub: 'Manage alerts & reminders',
        section: HosterProfileSection.notifications,
      ),
    ];

    return Column(
      children: tiles.map((t) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _infoTile(
            _circleIcon(t.icon, t.color),
            t.title,
            t.sub,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HosterProfileDetailScreen(
                  section: t.section,
                  stats: s,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _infoTile(Widget leading, String title, String subtitle,
      VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  // ── Logout ───────────────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return InkWell(
      onTap: _handleSignOut,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFEE2E2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared card wrapper ───────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: child,
    );
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 10) / 2;
    const startAngle = -math.pi / 2;

    // Track
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = const Color(0xFFF1F5F9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      2 * math.pi * progress.clamp(0, 1),
      false,
      Paint()
        ..color = const Color(0xFF1B4332)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

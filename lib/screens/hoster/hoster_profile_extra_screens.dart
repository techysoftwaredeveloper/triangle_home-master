import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/services/hoster_service.dart';
import 'package:triangle_home/screens/profile/verification_otp_screen.dart';
import 'package:triangle_home/screens/hoster/hoster_verification_center_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

// --- Helper for consistent Page Layout ---
class _HosterDetailScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool isLoading;

  const _HosterDetailScaffold({
    required this.title,
    required this.child,
    this.actions,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textDarkColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textDarkColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        actions: actions,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: child,
              ),
    );
  }
}

// --- Realtime Wrapper ---
class _RealtimeProfileWrapper extends StatelessWidget {
  final String title;
  final Widget Function(Map<String, dynamic> data) builder;
  final List<Widget>? actions;

  const _RealtimeProfileWrapper({required this.title, required this.builder})
    : actions = null;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final hosterService = HosterService();

    return StreamBuilder<Map<String, dynamic>>(
      stream: hosterService.getUserProfileStream(uid),
      builder: (context, snapshot) {
        return _HosterDetailScaffold(
          title: title,
          isLoading:
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData,
          actions: actions,
          child: builder(snapshot.data ?? {}),
        );
      },
    );
  }
}

// --- Common UI Components ---
Widget _buildCard({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

Widget _buildDetailRow(
  IconData icon,
  String label, {
  String? value,
  bool isVerified = false,
  VoidCallback? onVerify,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.successColor,
                      size: 14,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value ?? 'Not Provided',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkColor,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        ),
        if (!isVerified && onVerify != null)
          TextButton(
            onPressed: onVerify,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Verify',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
          ),
      ],
    ),
  );
}

// --- Specific Screens ---

class HosterBasicInfoScreen extends StatelessWidget {
  const HosterBasicInfoScreen({super.key});

  Future<void> _handlePhoneVerify(BuildContext context, String? phone) async {
    if (phone == null || phone.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please update phone number in edit profile first',
      );
      return;
    }

    final auth = FirebaseAuth.instance;
    await auth.verifyPhoneNumber(
      phoneNumber: phone.startsWith('+') ? phone : '+91$phone',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.currentUser?.linkWithCredential(credential);
        FirebaseFirestore.instance
            .collection('users')
            .doc(auth.currentUser?.uid)
            .set({
              'verification': {'phoneVerified': true},
            }, SetOptions(merge: true));
      },
      verificationFailed:
          (e) => Fluttertoast.showToast(msg: 'Failed: ${e.message}'),
      codeSent:
          (id, token) => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => VerificationOtpScreen(
                    verificationId: id,
                    phoneNumber: phone,
                  ),
            ),
          ),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _handleEmailVerify(String? email) async {
    if (email == null || email.isEmpty) return;
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      Fluttertoast.showToast(msg: 'Verification email sent to $email');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RealtimeProfileWrapper(
      title: 'Basic Information',
      builder: (data) {
        final info = data['info'] as Map? ?? {};
        final verif = data['verification'] as Map? ?? {};
        final dob = info['dob'];
        String dobStr = 'Not set';
        if (dob != null) {
          try {
            if (dob is Timestamp) {
              dobStr = DateFormat('dd MMM yyyy').format(dob.toDate());
            } else {
              final date = DateTime.tryParse(dob.toString()) ?? DateTime.now();
              dobStr = DateFormat('dd MMM yyyy').format(date);
            }
          } catch (e) {
            dobStr = 'Not set';
          }
        }

        final emailVerified =
            FirebaseAuth.instance.currentUser?.emailVerified ?? false;
        final phoneVerified = verif['phoneVerified'] == true;

        return _buildCard(
          child: Column(
            children: [
              _buildDetailRow(
                Icons.person_outline_rounded,
                'Full Name',
                value: info['name'],
              ),
              _buildDetailRow(
                Icons.cake_outlined,
                'Gender & DOB',
                value: '${info['gender'] ?? 'Not set'} • $dobStr',
              ),
              _buildDetailRow(
                Icons.phone_android_outlined,
                'Phone Number',
                value: info['phone'],
                isVerified: phoneVerified,
                onVerify: () => _handlePhoneVerify(context, info['phone']),
              ),
              _buildDetailRow(
                Icons.email_outlined,
                'Email Address',
                value: info['email'],
                isVerified: emailVerified,
                onVerify: () => _handleEmailVerify(info['email']),
              ),
              _buildDetailRow(
                Icons.location_on_outlined,
                'Address',
                value:
                    '${info['addressLine1'] ?? ""}, ${info['city'] ?? ""}, ${info['state'] ?? ""} - ${info['pincode'] ?? ""}',
              ),
            ],
          ),
        );
      },
    );
  }
}

class HosterIdentityScreen extends StatelessWidget {
  const HosterIdentityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _RealtimeProfileWrapper(
      title: 'Identity & Compliance',
      builder: (data) {
        final verif = data['verification'] as Map? ?? {};
        return Column(
          children: [
            _buildCard(
              child: Column(
                children: [
                  _buildDocRow(
                    Icons.badge_outlined,
                    'Aadhaar Card',
                    verif['govIdVerified'] == true
                        ? 'Verified'
                        : (verif['govIdStatus'] == 'pending'
                            ? 'In Review'
                            : 'Required'),
                    verif['govIdVerified'] == true
                        ? Colors.green
                        : (verif['govIdStatus'] == 'pending'
                            ? Colors.orange
                            : Colors.grey),
                  ),
                  const Divider(height: 32),
                  _buildDocRow(
                    Icons.credit_card_rounded,
                    'PAN Card',
                    verif['panVerified'] == true ? 'Verified' : 'Required',
                    verif['panVerified'] == true ? Colors.green : Colors.grey,
                  ),
                  const Divider(height: 32),
                  _buildDocRow(
                    Icons.home_work_outlined,
                    'Property Proof',
                    verif['propertyProofVerified'] == true
                        ? 'Verified'
                        : (verif['propertyProofStatus'] == 'pending'
                            ? 'In Review'
                            : 'Required'),
                    verif['propertyProofVerified'] == true
                        ? Colors.green
                        : (verif['propertyProofStatus'] == 'pending'
                            ? Colors.orange
                            : Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildCard(
              child: InkWell(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HosterVerificationCenterScreen(),
                      ),
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Verification Center',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Manage Documents',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDocRow(IconData icon, String label, String status, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Outfit',
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Outfit',
            ),
          ),
        ),
      ],
    );
  }
}

class HosterBusinessInfoScreen extends StatelessWidget {
  const HosterBusinessInfoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _RealtimeProfileWrapper(
      title: 'Business Information',
      builder: (data) {
        final business = data['business'] as Map? ?? {};
        return _buildCard(
          child: Column(
            children: [
              _buildDetailRow(
                Icons.person_pin_outlined,
                'Host Type',
                value: business['hostType'] ?? 'Individual Owner',
              ),
              _buildDetailRow(
                Icons.business_outlined,
                'Business Name',
                value: business['businessName'] ?? 'Not set',
              ),
              _buildDetailRow(
                Icons.star_outline_rounded,
                'Experience',
                value: business['experience'] ?? '3-5 Years',
              ),
              _buildDetailRow(
                Icons.description_outlined,
                'Tax Registration',
                value: business['taxId'] ?? 'Not provided',
              ),
            ],
          ),
        );
      },
    );
  }
}

class HosterBankingScreen extends StatelessWidget {
  const HosterBankingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _RealtimeProfileWrapper(
      title: 'Banking & Payouts',
      builder: (data) {
        final bank = data['bank_info'] as Map? ?? {};
        final isVerified = bank.isNotEmpty;

        return _buildCard(
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    bank['bankName'] ?? 'No Bank Linked',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  subtitle: Text(
                    bank['accountNumber'] != null
                        ? '**** ${bank['accountNumber'].toString().substring(bank['accountNumber'].toString().length - 4)}'
                        : 'Add account to receive payouts',
                    style: const TextStyle(fontSize: 13, fontFamily: 'Outfit'),
                  ),
                ),
              ),
              if (isVerified) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildSmallBadge(
                      Icons.check_circle_rounded,
                      'Bank Verified',
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildSmallBadge(
                      Icons.check_circle_rounded,
                      'Auto-Payout Active',
                      Colors.blue,
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmallBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }
}

class HosterPropertySummaryScreen extends StatelessWidget {
  const HosterPropertySummaryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final hosterService = HosterService();

    return StreamBuilder<Map<String, dynamic>>(
      stream: hosterService.getDetailedHosterStatsStream(uid),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        return _HosterDetailScaffold(
          title: 'Property Summary',
          isLoading:
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData,
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2,
            children: [
              _buildGridStat(
                'Total Properties',
                stats['totalProperties']?.toString() ?? '0',
                Colors.blue,
              ),
              _buildGridStat(
                'Active Listings',
                stats['activeListings']?.toString() ?? '0',
                Colors.green,
              ),
              _buildGridStat(
                'Total Rooms',
                stats['totalRooms']?.toString() ?? '0',
                Colors.purple,
              ),
              _buildGridStat(
                'Active Residents',
                stats['activeResidents']?.toString() ?? '0',
                Colors.orange,
              ),
              _buildGridStat(
                'Occupancy Rate',
                '${stats['occupancy'] ?? 0}%',
                Colors.teal,
              ),
              _buildGridStat(
                'Monthly Revenue',
                '₹${stats['monthlyRevenue'] ?? 0}',
                Colors.indigo,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }
}

class HosterPerformanceScreen extends StatelessWidget {
  const HosterPerformanceScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _RealtimeProfileWrapper(
      title: 'Performance',
      builder: (data) {
        return _buildCard(
          child: Column(
            children: [
              _buildPerformanceRow(
                Icons.chat_bubble_outline_rounded,
                'Response Rate',
                '${data['responseRate'] ?? "98"}%',
                Colors.green,
              ),
              _buildPerformanceRow(
                Icons.timer_outlined,
                'Avg. Response Time',
                '${data['responseTime'] ?? "12"} mins',
                Colors.blue,
              ),
              _buildPerformanceRow(
                Icons.check_circle_outline_rounded,
                'Acceptance Rate',
                '${data['acceptanceRate'] ?? "95"}%',
                Colors.green,
              ),
              _buildPerformanceRow(
                Icons.cancel_outlined,
                'Cancellation Rate',
                '${data['cancellationRate'] ?? "3"}%',
                Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textLightColor,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }
}

class HosterReviewsScreen extends StatelessWidget {
  const HosterReviewsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _HosterDetailScaffold(
      title: 'Reviews & Ratings',
      child: Column(
        children: [
          _buildReviewItem(
            'Amit Verma',
            '12 May 2024',
            5.0,
            'Stayed in Green Park House',
            'Great place, very clean and exactly as shown in photos. Host was very responsive and helpful.',
            'https://randomuser.me/api/portraits/men/32.jpg',
          ),
          const SizedBox(height: 16),
          _buildReviewItem(
            'Neha Iyer',
            '2 May 2024',
            4.0,
            'Stayed in Sunrise PG',
            'Safe and comfortable stay. Food is excellent and the host is cooperative.',
            'https://randomuser.me/api/portraits/women/44.jpg',
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(
    String name,
    String date,
    double rating,
    String stay,
    String comment,
    String imageUrl,
  ) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundImage: NetworkImage(imageUrl)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Outfit',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.orange,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            stay,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }
}

class HosterTrustScoreScreen extends StatelessWidget {
  const HosterTrustScoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _RealtimeProfileWrapper(
      title: 'Trust Score',
      builder: (data) {
        final score = (data['trustScore'] ?? 91) / 100.0;
        return _buildCard(
          child: Column(
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 70,
                      child: CustomPaint(
                        painter: HalfGaugePainter(score: score),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Column(
                        children: [
                          Text(
                            (score * 100).toInt().toString(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              fontFamily: 'Outfit',
                            ),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Excellent Host',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.1),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: Colors.green, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You're doing great! Keep providing excellent service.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HosterPreferencesScreen extends StatelessWidget {
  const HosterPreferencesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _RealtimeProfileWrapper(
      title: 'Preferences',
      builder: (data) {
        final prefs = data['host_preferences'] as Map? ?? {};
        return _buildCard(
          child: Column(
            children: [
              _buildPrefRow(
                'Booking Type',
                prefs['bookingType'] ?? 'Approval Required',
              ),
              _buildPrefRow(
                'Preferred Tenants',
                (prefs['tenantTypes'] as List?)?.join(", ") ??
                    'Students, Professionals',
              ),
              _buildPrefRow(
                'Preferred Gender',
                prefs['genderPreference'] ?? 'Any',
              ),
              _buildPrefRow(
                'Preferred Duration',
                prefs['durationPreference'] ?? 'Long Term',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrefRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textLightColor,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkColor,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }
}

class HosterEmergencyContactScreen extends StatelessWidget {
  const HosterEmergencyContactScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return _RealtimeProfileWrapper(
      title: 'Emergency Contact',
      builder: (data) {
        final contact = data['emergency_contact'] as Map? ?? {};
        return _buildCard(
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                contact['name'] != null
                    ? '${contact['name']} (${contact['relation']})'
                    : 'No Contact Added',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Outfit',
                ),
              ),
              subtitle: Text(
                contact['phone'] ?? 'Add a contact for safety',
                style: const TextStyle(fontSize: 13, fontFamily: 'Outfit'),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HosterSecurityCenterScreen extends StatelessWidget {
  const HosterSecurityCenterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const _HosterDetailScaffold(
      title: 'Security Center',
      child: Center(child: Text('Security & Privacy Settings coming soon')),
    );
  }
}

class HosterNotificationsScreen extends StatelessWidget {
  const HosterNotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const _HosterDetailScaffold(
      title: 'Notification Settings',
      child: Center(child: Text('Notification Preferences coming soon')),
    );
  }
}

// --- Gauge Painter ---
class HalfGaugePainter extends CustomPainter {
  final double score;
  HalfGaugePainter({required this.score});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final paintBase =
        Paint()
          ..color = const Color(0xFFF1F5F9)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final paintScore =
        Paint()
          ..color = const Color(0xFF10B981)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159,
      3.14159,
      false,
      paintBase,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159,
      3.14159 * score,
      false,
      paintScore,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

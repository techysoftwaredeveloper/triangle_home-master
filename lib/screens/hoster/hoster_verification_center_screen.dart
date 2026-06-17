import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:triangle_home/widgets/document_capture_camera.dart';
import 'dart:io';
import 'package:triangle_home/screens/profile/verification_otp_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:triangle_home/theme/app_theme.dart';

class HosterVerificationCenterScreen extends StatefulWidget {
  const HosterVerificationCenterScreen({super.key});

  @override
  State<HosterVerificationCenterScreen> createState() =>
      _HosterVerificationCenterScreenState();
}

class _HosterVerificationCenterScreenState
    extends State<HosterVerificationCenterScreen> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  final Color _successGreen = AppTheme.successColor;
  final Color _accentBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reloadAndSyncEmail();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadAndSyncEmail();
    }
  }

  /// Reload Firebase Auth token (picks up email verification done in browser)
  /// then syncs the verified flag into Firestore if needed.
  Future<void> _reloadAndSyncEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed != null && refreshed.emailVerified) {
        await _firestore.collection('users').doc(refreshed.uid).set({
          'emailVerified': true, // top-level field (read by hoster_service)
          'verification': {'emailVerified': true},
        }, SetOptions(merge: true));
      }
      
      // Also sync phone if present
      if (refreshed != null && refreshed.phoneNumber != null) {
        await _firestore.collection('users').doc(refreshed.uid).set({
          'verification': {'phoneVerified': true},
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // non-blocking
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login first')));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data?.data();
        final verif = userData?['verification'] as Map? ?? {};
        final info = userData?['info'] as Map? ?? {};

        // Safety-net sync in case user just verified email in background
        if (user.emailVerified && verif['emailVerified'] != true) {
          _updateVerification('emailVerified', true);
          // Also write top-level field
          _firestore.collection('users').doc(user.uid).set(
            {'emailVerified': true},
            SetOptions(merge: true),
          );
        }

        if (user.phoneNumber != null && verif['phoneVerified'] != true) {
          _updateVerification('phoneVerified', true);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textDarkColor,
                size: 20,
              ),
              onPressed: () {
                if (!mounted) return;
                Navigator.pop(context);
              },
            ),
            title: const Text(
              'Partner Verification',
              style: TextStyle(
                color: AppTheme.textDarkColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusHeader(verif),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Contact Verification'),
                    _buildVerificationTile(
                      icon: Icons.phone_android_rounded,
                      title: 'Mobile Number',
                      subtitle:
                          info['phoneNumber'] ?? info['phone'] ?? user.phoneNumber ?? 'Not provided',
                      isVerified: verif['phoneVerified'] == true,
                      onTap: verif['phoneVerified'] == true ? null : () => _verifyPhone(info['phoneNumber'] ?? user.phoneNumber),
                    ),
                    _buildEmailVerificationTile(user, verif),

                    const SizedBox(height: 32),
                    _buildSectionTitle('Identity Documents'),

                    _buildDocumentUploadCard(
                      title: 'Aadhaar Card',
                      subtitle: 'Front and Back side of your Aadhaar',
                      fieldPrefix: 'govId',
                      verifData: verif,
                      icon: Icons.assignment_ind_rounded,
                    ),

                    _buildDocumentUploadCard(
                      title: 'PAN Card',
                      subtitle: 'Front side of your PAN Card',
                      fieldPrefix: 'pan',
                      verifData: verif,
                      icon: Icons.credit_card_rounded,
                      showBackSide: false,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle('Business & Property Proof'),

                    _buildDocumentUploadCard(
                      title: 'Business Proof',
                      subtitle: 'GST, Trade License or Shop Act',
                      fieldPrefix: 'businessProof',
                      verifData: verif,
                      icon: Icons.business_center_rounded,
                      showBackSide: false,
                      onTypeTap: () => _showBusinessProofOptions(),
                      selectedType: verif['businessProofType'],
                    ),

                    _buildDocumentUploadCard(
                      title: 'Property Ownership',
                      subtitle: 'Electricity Bill, Tax Receipt or Lease',
                      fieldPrefix: 'propertyProof',
                      verifData: verif,
                      icon: Icons.home_work_rounded,
                      showBackSide: false,
                      onTypeTap: () => _showPropertyProofOptions(),
                      selectedType: verif['propertyProofType'],
                    ),

                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: _successGreen.withValues(alpha: 0.5),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Verified Partner Badge',
                            style: TextStyle(
                              color: _successGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Earn trust from potential tenants',
                            style: TextStyle(
                              color: AppTheme.textLightColor,
                              fontSize: 12,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.white.withValues(alpha: 0.7),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.successColor,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDarkColor,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required String subtitle,
    required String fieldPrefix,
    required Map verifData,
    required IconData icon,
    bool showBackSide = true,
    VoidCallback? onTypeTap,
    String? selectedType,
  }) {
    final status = verifData['${fieldPrefix}Status'];
    final isVerified = verifData['${fieldPrefix}Verified'] == true;
    final rejectReason = verifData['${fieldPrefix}RejectReason'] as String?;

    Color statusColor = AppTheme.warningColor;
    String statusText = 'Pending';

    if (isVerified) {
      statusColor = _successGreen;
      statusText = 'Verified';
    } else if (status == 'pending') {
      statusColor = const Color(0xFF2563EB);
      statusText = 'In Review';
    } else if (status == 'rejected') {
      statusColor = AppTheme.errorColor;
      statusText = 'Rejected';
    } else if (verifData['${fieldPrefix}FrontUrl'] == null) {
      statusColor = Colors.grey;
      statusText = 'Not Started';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isVerified ? _successGreen : _accentBlue).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isVerified ? _successGreen : _accentBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textDarkColor,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    Text(
                      selectedType ?? subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLightColor,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
            ],
          ),
          if (!isVerified && status == 'rejected' && rejectReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason: $rejectReason',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onTypeTap != null && !isVerified) ...[
            const SizedBox(height: 16),
            Material(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onTypeTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedType ?? 'Select Document Type',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSideUpload(
                  'Front View',
                  fieldPrefix,
                  'Front',
                  verifData['${fieldPrefix}FrontUrl'],
                  isVerified,
                ),
              ),
              if (showBackSide) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSideUpload(
                    'Back View',
                    fieldPrefix,
                    'Back',
                    verifData['${fieldPrefix}BackUrl'],
                    isVerified,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideUpload(
    String label,
    String fieldPrefix,
    String side,
    String? url,
    bool isDisabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLightColor,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: isDisabled ? null : () => _uploadDocument(fieldPrefix, side),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                image:
                    url != null
                        ? DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  url == null
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            color:
                                isDisabled
                                    ? Colors.grey
                                    : AppTheme.successColor,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Upload',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDisabled
                                      ? Colors.grey
                                      : AppTheme.successColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      )
                      : Container(
                        alignment: Alignment.bottomRight,
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: _successGreen,
                            size: 18,
                          ),
                        ),
                      ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusHeader(Map verif) {
    int totalSteps = 6; // Phone, Email, Aadhaar, PAN, Business, Property
    int verifiedCount = 0;

    if (verif['phoneVerified'] == true) verifiedCount++;
    if (_auth.currentUser?.emailVerified == true || verif['emailVerified'] == true) verifiedCount++;
    if (verif['govIdVerified'] == true) verifiedCount++;
    if (verif['panVerified'] == true) verifiedCount++;
    if (verif['businessProofVerified'] == true) verifiedCount++;
    if (verif['propertyProofVerified'] == true) verifiedCount++;

    double progress = verifiedCount / totalSteps;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.successColor, Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trust Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Complete these steps to become a Verified Partner.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isVerified,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isVerified ? _successGreen : _accentBlue).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isVerified ? _successGreen : _accentBlue,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textDarkColor,
              fontFamily: 'Outfit',
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textLightColor,
              fontFamily: 'Outfit',
            ),
          ),
          trailing: Icon(
            isVerified ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: isVerified ? _successGreen : AppTheme.warningColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  // ── Email Verification Tile ───────────────────────────────────────────────
  Widget _buildEmailVerificationTile(User user, Map verif) {
    final isVerified = user.emailVerified || verif['emailVerified'] == true;
    final email = user.email ?? 'Not provided';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerified
              ? _successGreen.withValues(alpha: 0.3)
              : const Color(0xFFFED7AA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isVerified ? _successGreen : const Color(0xFFF97316))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.email_rounded,
                  color: isVerified ? _successGreen : const Color(0xFFF97316),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email Address',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textDarkColor,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLightColor,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    if (!isVerified) ...
                      [
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showEmailVerificationSheet(email),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF97316),
                                  Color(0xFFEA580C),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_outlined,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Verify Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                  ],
                ),
              ),
              Icon(
                isVerified
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: isVerified ? _successGreen : const Color(0xFFF97316),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Full Email Verification Sheet ─────────────────────────────────────────
  void _showEmailVerificationSheet(String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmailVerificationSheet(
        email: email,
        auth: _auth,
        firestore: _firestore,
        onVerified: () {
          // Trigger UI rebuild via stream (already listening)
          Navigator.pop(context);
          Fluttertoast.showToast(
            msg: '✅ Email verified successfully!',
            backgroundColor: AppTheme.successColor,
            textColor: Colors.white,
          );
        },
      ),
    );
  }

  Future<void> _showBusinessProofOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Proof Document',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select one document to verify your professional status',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLightColor,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 24),
                _buildOptionTile(
                  'GST Certificate',
                  'businessProof',
                  'GST Certificate',
                ),
                _buildOptionTile(
                  'Trade License',
                  'businessProof',
                  'Trade License',
                ),
                _buildOptionTile(
                  'Shop Act / MSME',
                  'businessProof',
                  'Shop Act / MSME',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Future<void> _showPropertyProofOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Property Ownership Proof',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select one document to verify property control',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLightColor,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 24),
                _buildOptionTile(
                  'Electricity Bill',
                  'propertyProof',
                  'Electricity Bill',
                ),
                _buildOptionTile(
                  'Property Tax Receipt',
                  'propertyProof',
                  'Property Tax',
                ),
                _buildOptionTile(
                  'Lease / Rent Agreement',
                  'propertyProof',
                  'Lease Agreement',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildOptionTile(String title, String fieldPrefix, String type) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Outfit',
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () async {
          Navigator.pop(context);
          await _firestore.collection('users').doc(_auth.currentUser?.uid).set({
            'verification': {'${fieldPrefix}Type': type},
          }, SetOptions(merge: true));
        },
      ),
    );
  }

  Future<void> _uploadDocument(String fieldPrefix, String side) async {
    final userDoc =
        await _firestore.collection('users').doc(_auth.currentUser?.uid).get();
    final verif = userDoc.data()?['verification'] as Map? ?? {};

    if ((fieldPrefix == 'businessProof' || fieldPrefix == 'propertyProof') &&
        verif['${fieldPrefix}Type'] == null) {
      Fluttertoast.showToast(msg: 'Please select document type first');
      return;
    }

    final picker = ImagePicker();
    if (!mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Upload Document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(context, ImageSource.camera),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: AppTheme.successColor,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Camera',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap:
                            () => Navigator.pop(context, ImageSource.gallery),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.photo_library_rounded,
                                color: Color(0xFF2563EB),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Gallery',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
    if (source == null) return;

    // Check permissions
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        Fluttertoast.showToast(msg: 'Camera permission is required');
        if (status.isPermanentlyDenied) openAppSettings();
        return;
      }
    } else {
      final status = Platform.isIOS 
          ? await Permission.photos.request() 
          : await Permission.storage.request();
          
      if (status.isDenied || status.isPermanentlyDenied) {
        if (Platform.isAndroid) {
          final photoStatus = await Permission.photos.request();
          if (photoStatus.isDenied || photoStatus.isPermanentlyDenied) {
            Fluttertoast.showToast(msg: 'Gallery access is required');
            if (photoStatus.isPermanentlyDenied) openAppSettings();
            return;
          }
        } else {
          Fluttertoast.showToast(msg: 'Gallery access is required');
          if (status.isPermanentlyDenied) openAppSettings();
          return;
        }
      }
    }

    XFile? image;
    if (source == ImageSource.camera) {
      if (!mounted) return;
      image = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentCaptureCamera(title: 'Scan $side Side'),
        ),
      );
    } else {
      image = await picker.pickImage(source: source, imageQuality: 80);
    }

    if (image == null) {
      debugPrint('No image selected/captured');
      return;
    }

    if (!mounted) return;
    CroppedFile? croppedFile;
    try {
      croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 2),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Align Document',
            toolbarColor: AppTheme.successColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio3x2,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Align Document',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Cropping error: $e');
      Fluttertoast.showToast(msg: 'Error opening cropper: $e');
      return;
    }

    if (croppedFile == null) {
      debugPrint('Cropping cancelled');
      return;
    }

    if (!mounted) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Confirm Upload',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Is the document clearly readable?',
                    style: TextStyle(fontSize: 14, fontFamily: 'Outfit'),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(croppedFile!.path),
                      height: 180,
                      width: 280,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Retake',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm & Upload',
                  style: TextStyle(color: Colors.white, fontFamily: 'Outfit'),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    Fluttertoast.showToast(msg: 'Uploading document...');
    
    try {
      final File file = File(croppedFile.path);
      final userId = _auth.currentUser!.uid;

      final ref = FirebaseStorage.instance.ref().child(
        'verifications/$userId/${fieldPrefix}_${side}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();

      await _firestore.collection('users').doc(userId).set({
        'verification': {
          '$fieldPrefix${side}Url': url,
          '${fieldPrefix}Status': 'pending',
          '${fieldPrefix}Timestamp': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      
      Fluttertoast.showToast(msg: 'Document uploaded successfully!');
    } catch (e) {
      debugPrint('Upload error: $e');
      Fluttertoast.showToast(msg: 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateVerification(String field, dynamic value) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _firestore.collection('users').doc(userId).set({
      'verification': {
        field: value,
        '${field}Timestamp': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  Future<void> _verifyPhone(String? phone) async {
    if (phone == null || phone.isEmpty) {
      Fluttertoast.showToast(msg: 'Please add phone number in profile first');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone.startsWith('+') ? phone : '+91$phone',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.currentUser?.linkWithCredential(credential);
          await _updateVerification('phoneVerified', true);
        },
        verificationFailed: (FirebaseAuthException e) {
          Fluttertoast.showToast(msg: e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => VerificationOtpScreen(
                    verificationId: verificationId,
                    phoneNumber: phone,
                  ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// ── Email Verification Bottom Sheet ──────────────────────────────────────────
class _EmailVerificationSheet extends StatefulWidget {
  final String email;
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final VoidCallback onVerified;

  const _EmailVerificationSheet({
    required this.email,
    required this.auth,
    required this.firestore,
    required this.onVerified,
  });

  @override
  State<_EmailVerificationSheet> createState() =>
      _EmailVerificationSheetState();
}

class _EmailVerificationSheetState extends State<_EmailVerificationSheet>
    with TickerProviderStateMixin {
  // 0 = initial, 1 = email sent (waiting), 2 = success
  int _step = 0;
  bool _isLoading = false;
  bool _isChecking = false;
  String? _errorMsg;
  int _resendCountdown = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const _green = Color(0xFF1B4332);
  static const _orange = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Step 1: Send verification email ────────────────────────────────────────
  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final user = widget.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      await user.sendEmailVerification(
        ActionCodeSettings(
          url: 'https://trianglehome.page.link/verify-email',
          handleCodeInApp: false,
        ),
      );

      setState(() {
        _step = 1;
        _isLoading = false;
        _resendCountdown = 60;
      });
      _startResendTimer();
    } catch (e) {
      // Fallback without ActionCodeSettings if dynamic links not configured
      try {
        await widget.auth.currentUser?.sendEmailVerification();
        setState(() {
          _step = 1;
          _isLoading = false;
          _resendCountdown = 60;
        });
        _startResendTimer();
      } catch (e2) {
        setState(() {
          _isLoading = false;
          _errorMsg = e2.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendCountdown > 0) _resendCountdown--;
      });
      return _resendCountdown > 0;
    });
  }

  // ── Step 2: Check if user has clicked link ──────────────────────────────────
  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _errorMsg = null;
    });
    try {
      // Force-reload the Firebase Auth token to detect email verification
      await widget.auth.currentUser?.reload();
      final refreshed = widget.auth.currentUser;

      if (refreshed != null && refreshed.emailVerified) {
        // ✅ Write to Firestore — both paths that hoster_service reads
        await widget.firestore
            .collection('users')
            .doc(refreshed.uid)
            .set({
          'emailVerified': true, // top-level (read by hoster_service)
          'verification': {
            'emailVerified': true,
            'emailVerifiedAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));

        setState(() {
          _step = 2;
          _isChecking = false;
        });

        // Auto-close after showing success
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) widget.onVerified();
      } else {
        setState(() {
          _isChecking = false;
          _errorMsg =
              'Email not verified yet. Please click the link in your inbox.';
        });
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
        _errorMsg = 'Check failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildSendStep();
      case 1:
        return _buildWaitingStep();
      case 2:
        return _buildSuccessStep();
      default:
        return _buildSendStep();
    }
  }

  // ── Step 0: Initial send screen ─────────────────────────────────────────────
  Widget _buildSendStep() {
    return Column(
      key: const ValueKey('send'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _sheetHandle(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_unread_rounded,
              color: _orange, size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          'Verify Your Email',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll send a verification link to',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontFamily: 'Outfit',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.email,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1E293B),
              fontFamily: 'Outfit',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Click the link in the email to verify your address.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontFamily: 'Outfit',
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (_errorMsg != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendVerificationEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Send Verification Email',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Outfit',
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey, fontFamily: 'Outfit'),
          ),
        ),
      ],
    );
  }

  // ── Step 1: Waiting for user to click link ───────────────────────────────────
  Widget _buildWaitingStep() {
    return Column(
      key: const ValueKey('waiting'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _sheetHandle(),
        const SizedBox(height: 20),
        ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _green.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.email_outlined, color: _green, size: 44),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Check Your Inbox!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We sent a verification link to',
          style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'Outfit'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          widget.email,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: _green,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 20),
        // Steps
        _stepRow('1', 'Open your email app'),
        _stepRow('2', 'Find the email from Triangle Home'),
        _stepRow('3', 'Click the verification link'),
        _stepRow('4', 'Come back here and tap the button below'),
        if (_errorMsg != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: _orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(color: _orange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isChecking ? null : _checkVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isChecking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'I\'ve Verified My Email',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // Resend
        TextButton(
          onPressed: _resendCountdown == 0 ? _sendVerificationEmail : null,
          child: Text(
            _resendCountdown > 0
                ? 'Resend email in ${_resendCountdown}s'
                : 'Resend Verification Email',
            style: TextStyle(
              color: _resendCountdown == 0 ? _orange : Colors.grey,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _green,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Success ─────────────────────────────────────────────────────────
  Widget _buildSuccessStep() {
    return Padding(
      key: const ValueKey('success'),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: _green,
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Email Verified! 🎉',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _green,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your email address has been verified.\nProfile completion updated.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontFamily: 'Outfit',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

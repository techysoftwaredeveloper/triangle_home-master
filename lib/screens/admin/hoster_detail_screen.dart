import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:triangle_home/services/trust_service.dart';

class HosterDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  final AdminService adminService;

  const HosterDetailScreen({
    super.key,
    required this.request,
    required this.adminService,
  });

  @override
  State<HosterDetailScreen> createState() => _HosterDetailScreenState();
}

class _HosterDetailScreenState extends State<HosterDetailScreen> {
  bool _isProcessing = false;
  final TextEditingController _noteController = TextEditingController();

  Future<void> _handleUpdate(String status) async {
    setState(() => _isProcessing = true);
    try {
      final uid = widget.request['uid'];

      if (status == 'approved') {
        // Approve user in users collection (nested in permissions)
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'permissions.status': 'approved',
          'permissions.approvedAt': FieldValue.serverTimestamp(),
          'accountStatus': 'approved',
          'status': 'approved',
          'adminReviewNote': _noteController.text.trim(),
        });

        // Also update the request if it exists
        await FirebaseFirestore.instance
            .collection('hoster_requests')
            .doc(uid)
            .set({
              'status': 'approved',
              'reviewedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        // Update Trust Score
        await TrustService().calculateAndUpdateTrustScore(uid);
      } else {
        // Reject / Request Info
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'permissions.status': 'rejected',
          'accountStatus': 'rejected',
          'status': 'rejected',
          'adminReviewNote': _noteController.text.trim(),
        });

        await FirebaseFirestore.instance
            .collection('hoster_requests')
            .doc(uid)
            .set({
              'status': 'rejected',
              'reviewNote': _noteController.text.trim(),
            }, SetOptions(merge: true));
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Account $status successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.request['info'] as Map? ?? {};

    // In our system, doc verification for hosters is stored in 'users' collection
    // because it's shared across features. Let's fetch it live.
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.request['uid'])
              .snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final verif = userData['verification'] as Map? ?? {};

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Partner Verification',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textDarkColor,
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(info, userData, verif),
                    const SizedBox(height: 16),
                    _buildCompletionBar(info, userData, verif),
                    const SizedBox(height: 16),
                    _buildContactVerification(userData, verif),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Identity Documents'),
                    _buildDocCard(
                      'Aadhaar Card',
                      verif['govIdFrontUrl'] ?? verif['aadhaarFrontUrl'],
                      verif['govIdBackUrl'] ?? verif['aadhaarBackUrl'],
                      'govId',
                      verif['govIdVerified'] == true || verif['aadhaarVerified'] == true,
                    ),
                    _buildDocCard(
                      'PAN Card',
                      verif['panFrontUrl'] ?? verif['panUrl'],
                      null,
                      'pan',
                      verif['panVerified'] == true,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Business Documents'),
                    _buildDocCard(
                      'Business Proof (${verif['businessProofType'] ?? 'Not selected'})',
                      verif['businessProofFrontUrl'] ?? verif['businessProofUrl'],
                      null,
                      'business',
                      verif['businessProofVerified'] == true,
                    ),
                    _buildDocCard(
                      'Property Ownership (${verif['propertyProofType'] ?? 'Not selected'})',
                      verif['propertyProofFrontUrl'] ?? verif['propertyProofUrl'],
                      null,
                      'property',
                      verif['propertyProofVerified'] == true,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Admin Action'),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Add a note or specify what info is missing...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              _buildBottomActions(),
              if (_isProcessing)
                Container(
                  color: Colors.white.withValues(alpha: 0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
      Map info, Map<String, dynamic> userData, Map verif) {
    final isApproved = userData['status'] == 'approved' ||
        (userData['permissions'] as Map?)?['status'] == 'approved';
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
              backgroundImage: info['profileImage'] != null
                  ? CachedNetworkImageProvider(info['profileImage'])
                  : null,
              child: info['profileImage'] == null
                  ? const Icon(Icons.person, size: 40, color: AppTheme.successColor)
                  : null,
            ),
            if (isApproved)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info['name'] ?? 'Unknown',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit'),
              ),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 14,
                      color: AppTheme.textLightColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      info['email'] ?? 'No email',
                      style: const TextStyle(
                          color: AppTheme.textLightColor, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (userData['emailVerified'] == true ||
                      verif['emailVerified'] == true)
                    _adminBadge('Email ✓', Colors.green),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14,
                      color: AppTheme.textLightColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      info['phone'] ?? 'No phone',
                      style: const TextStyle(
                          color: AppTheme.textLightColor, fontSize: 13),
                    ),
                  ),
                  if (verif['phoneVerified'] == true)
                    _adminBadge('Phone ✓', Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _adminBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildCompletionBar(
      Map info, Map<String, dynamic> userData, Map verif) {
    int total = 10, filled = 0;
    if ((info['name'] ?? '').toString().isNotEmpty) filled++;
    if ((info['email'] ?? userData['email'] ?? '').toString().isNotEmpty) filled++;
    if ((info['phone'] ?? userData['phone'] ?? '').toString().isNotEmpty) filled++;
    if (info['profileImage'] != null) filled++;
    if (userData['emailVerified'] == true || verif['emailVerified'] == true) filled++;
    if (verif['phoneVerified'] == true) filled++;
    if (verif['govIdVerified'] == true || verif['aadhaarVerified'] == true ||
        (verif['govIdFrontUrl'] ?? verif['aadhaarFrontUrl']) != null) {
      filled++;
    }
    if (verif['panVerified'] == true ||
        (verif['panFrontUrl'] ?? verif['panUrl']) != null) {
      filled++;
    }
    if (userData['host_preferences'] != null) filled++;
    if (userData['bank_info'] != null ||
        (userData['onboardingData'] as Map?)?['bankAccNo'] != null) {
      filled++;
    }

    final pct = filled / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Profile Completion',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('${(pct * 100).toInt()}%  ($filled/$total)',
                style: TextStyle(
                    fontSize: 12,
                    color: pct >= 0.8 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 0.8 ? Colors.green : Colors.orange),
          ),
        ),
      ],
    );
  }

  Widget _buildContactVerification(Map<String, dynamic> userData, Map verif) {
    final emailVerified =
        userData['emailVerified'] == true || verif['emailVerified'] == true;
    final phoneVerified = verif['phoneVerified'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact Verification',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _contactChip(
                  Icons.email_outlined,
                  'Email',
                  emailVerified ? 'Verified' : 'Unverified',
                  emailVerified,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _contactChip(
                  Icons.phone_outlined,
                  'Phone',
                  phoneVerified ? 'Verified' : 'Unverified',
                  phoneVerified,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactChip(
      IconData icon, String label, String status, bool verified) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: verified
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: verified ? Colors.green : Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textLightColor)),
                Text(status,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: verified ? Colors.green : Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }

  Widget _buildDocCard(
    String title,
    String? frontUrl,
    String? backUrl,
    String field,
    bool isVerified,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (isVerified)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 18,
                )
              else
                _buildQuickAction(field),
            ],
          ),
          if (frontUrl != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildThumb(frontUrl, 'Front')),
                if (backUrl != null) ...[
                  const SizedBox(width: 12),
                  Expanded(child: _buildThumb(backUrl, 'Back')),
                ],
              ],
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'No documents uploaded',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumb(String url, String label) {
    return InkWell(
      onTap: () => _viewImage(url),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              height: 80,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String field) {
    return Row(
      children: [
        TextButton(
          onPressed: () => _verifyField(field, true),
          child: const Text(
            'Verify',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        TextButton(
          onPressed: () => _verifyField(field, false),
          child: const Text(
            'Reject',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _verifyField(String field, bool verified) async {
    final uid = widget.request['uid'];
    final Map<String, dynamic> update = {};

    String? reason;
    if (!verified) {
      reason = await _showRejectionReasonDialog(field);
      if (reason == null) return; // User cancelled
    }

    if (field == 'govId') {
      update['verification.govIdVerified'] = verified;
      update['verification.govIdStatus'] = verified ? 'verified' : 'rejected';
      update['verification.govIdRejectReason'] = reason;
      update['verification.aadhaarVerified'] = verified;
      update['verification.aadhaarStatus'] = verified ? 'verified' : 'rejected';
      update['verification.aadhaarRejectReason'] = reason;
    } else if (field == 'pan') {
      update['verification.panVerified'] = verified;
      update['verification.panStatus'] = verified ? 'verified' : 'rejected';
      update['verification.panRejectReason'] = reason;
      update['verification.panUrlStatus'] = verified ? 'verified' : 'rejected';
    } else if (field == 'business') {
      update['verification.businessProofVerified'] = verified;
      update['verification.businessProofStatus'] =
          verified ? 'verified' : 'rejected';
      update['verification.businessProofRejectReason'] = reason;
    } else if (field == 'property') {
      update['verification.propertyProofVerified'] = verified;
      update['verification.propertyProofStatus'] =
          verified ? 'verified' : 'rejected';
      update['verification.propertyProofRejectReason'] = reason;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update(update);
  }

  Future<String?> _showRejectionReasonDialog(String field) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Rejection Reason',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Explain why this document is being rejected...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Reject Document'),
              ),
            ],
          ),
    );
  }

  void _viewImage(String url) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
          ),
    );
  }

  Widget _buildBottomActions() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleUpdate('rejected'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  foregroundColor: Colors.red,
                  elevation: 0,
                ),
                child: const Text(
                  'Request Info',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleUpdate('approved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  elevation: 0,
                ),
                child: const Text(
                  'Approve Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

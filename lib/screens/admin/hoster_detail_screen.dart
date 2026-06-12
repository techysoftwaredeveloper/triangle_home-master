import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/services/audit_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

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
  final AuditService _auditService = AuditService();
  final TextEditingController _internalNotesController = TextEditingController();
  final TextEditingController _partnerMessageController = TextEditingController();
  bool _isProcessing = false;

  // Colors based on the screenshot
  static const Color bgColor = Color(0xFFF8FAFC);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color primaryBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _internalNotesController.text = widget.request['adminReviewNote'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.request['uid'] ?? widget.request['id'] ?? widget.request['userId'];
    debugPrint('HosterDetailScreen: Loading details for UID: $uid from request: ${widget.request}');

    return StreamBuilder<Map<String, dynamic>>(
      stream: Rx.combineLatest2(
        FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        FirebaseFirestore.instance.collection('hoster_requests').doc(uid).snapshots(),
        (userSnap, requestSnap) {
          debugPrint('HosterDetailScreen: userSnap exists: ${userSnap.exists}, requestSnap exists: ${requestSnap.exists}');
          return {
            'user': userSnap.data() ?? {},
            'request': requestSnap.data() ?? {},
          };
        },
      ).handleError((error) {
        debugPrint('HosterDetailScreen: Stream Error: $error');
      }),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: errorRed, size: 48),
                  const SizedBox(height: 16),
                  Text('Error loading data: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!;
        final user = data['user'] as Map<String, dynamic>;
        final request = data['request'] as Map<String, dynamic>;

        if (user.isEmpty && request.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text('Partner Verification', style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
              leading: IconButton(icon: const Icon(Icons.arrow_back, color: textDark), onPressed: () => Navigator.pop(context)),
            ),
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off_rounded, color: textLight, size: 64),
                    const SizedBox(height: 24),
                    const Text(
                      'Partner Data Not Found',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We couldn\'t find any active application or profile for UID:\n$uid\n\nPlease verify the ID or check if the user exists in Firestore.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: textLight, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Go Back', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final verif = user['verification'] as Map? ?? {};
        final info = user['info'] as Map? ?? {};

        return Scaffold(
          backgroundColor: bgColor,
          appBar: _buildAppBar(request, user),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopSummaryRow(user, verif, info, request),
                      const SizedBox(height: 24),
                      _buildProfileAndTimelineRow(user, verif, info),
                      const SizedBox(height: 24),
                      _buildDocumentSections(user, verif),
                      const SizedBox(height: 24),
                      _buildNotesSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              _buildStickyFooter(user, verif),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Map request, Map user) {
    // Enhanced fallbacks for submission date
    final submittedAt = request['requestedAt'] ?? 
                       user['createdAt'] ?? 
                       user['updatedAt'] ?? 
                       request['updatedAt'];
                       
    final dateStr = submittedAt is Timestamp 
        ? DateFormat('dd MMM yyyy, hh:mm a').format(submittedAt.toDate())
        : (submittedAt is String ? submittedAt : 'N/A');

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: textDark, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const Text(
            'Admin  >  Approvals  >  Hoster Requests  >  ',
            style: TextStyle(color: textLight, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Text(
            'Partner Verification',
            style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          _metadataBadge('Partner UID: ${request['id'] ?? widget.request['id'] ?? "N/A"}'),
          const SizedBox(width: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: textLight, fontSize: 12, fontFamily: 'Outfit'),
              children: [
                const TextSpan(text: 'Submitted on: '),
                TextSpan(text: dateStr, style: const TextStyle(color: textDark, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: borderColor, height: 1),
      ),
    );
  }

  Widget _metadataBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(text, style: const TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTopSummaryRow(Map user, Map verif, Map info, Map request) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: _buildVerificationSummaryCard(user, verif, info)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _buildOverallStatusCard(user, verif)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _buildDocumentProgressCard(verif, user)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _buildKeyInfoCard(user, request)),
        ],
      ),
    );
  }

  Widget _buildVerificationSummaryCard(Map user, Map verif, Map info) {
    final completion = _calculateCompletion(user, verif, info);
    return _card(
      child: Column(
        children: [
          const Text('Verification Summary', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: completion,
                  strokeWidth: 10,
                  backgroundColor: bgColor,
                  valueColor: AlwaysStoppedAnimation<Color>(completion >= 0.8 ? successGreen : warningOrange),
                ),
              ),
              Text('${(completion * 100).toInt()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Profile Completion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(completion >= 1.0 ? 'Fully Complete' : 'Partially Complete', style: TextStyle(color: completion >= 0.8 ? successGreen : textLight, fontSize: 12)),
        ],
      ),
    );
  }

  double _calculateCompletion(Map user, Map verif, Map info) {
    int total = 7;
    int filled = 0;
    if (info['name'] != null) filled++;
    if (user['emailVerified'] == true) filled++;
    if (verif['phoneVerified'] == true) filled++;
    if (verif['aadhaarStatus'] == 'approved' || verif['govIdStatus'] == 'approved') filled++;
    if (verif['panStatus'] == 'approved') filled++;
    if (verif['businessProofStatus'] == 'approved') filled++;
    if (verif['propertyProofStatus'] == 'approved') filled++;
    return filled / total;
  }

  Widget _buildOverallStatusCard(Map user, Map verif) {
    final status = user['accountStatus'] ?? user['status'] ?? 'pending';
    final isApproved = status == 'approved' || status == 'active';
    final isReady = _isReadyForApproval(user, verif);
    final missingCount = _getMissingCount(user, verif);

    final statusColor = isApproved ? successGreen : (status == 'rejected' ? errorRed : warningOrange);
    final statusIcon = isApproved ? Icons.check_circle : (status == 'rejected' ? Icons.cancel : Icons.access_time_filled);
    final actionLabel = isApproved ? 'Fully Approved' : 'Action Required';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overall Status', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.toString().toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 16)),
                  Text(actionLabel, style: const TextStyle(color: textLight, fontSize: 12)),
                ],
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ready for Approval', style: TextStyle(color: textLight, fontSize: 12)),
              Text(isReady ? 'Yes' : 'No', style: TextStyle(fontWeight: FontWeight.bold, color: isReady ? successGreen : errorRed, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          _actionButton('View Missing Items ($missingCount)', onPressed: missingCount > 0 ? () => _showMissingItems(user, verif) : null),
        ],
      ),
    );
  }

  int _getMissingCount(Map user, Map verif) {
    int missing = 0;
    if (verif['aadhaarStatus'] != 'approved' && verif['govIdStatus'] != 'approved') missing++;
    if (verif['panStatus'] != 'approved') missing++;
    if (verif['businessProofStatus'] != 'approved') missing++;
    if (verif['propertyProofStatus'] != 'approved') missing++;
    if (user['emailVerified'] != true) missing++;
    if (verif['phoneVerified'] != true) missing++;
    return missing;
  }

  void _showMissingItems(Map user, Map verif) {
    final List<String> items = [];
    if (verif['aadhaarStatus'] != 'approved' && verif['govIdStatus'] != 'approved') items.add('Aadhaar Document');
    if (verif['panStatus'] != 'approved') items.add('PAN Card');
    if (verif['businessProofStatus'] != 'approved') items.add('Business Proof');
    if (verif['propertyProofStatus'] != 'approved') items.add('Ownership Proof');
    if (user['emailVerified'] != true) items.add('Email Verification');
    if (verif['phoneVerified'] != true) items.add('Phone Verification');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Missing Requirements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [const Icon(Icons.error_outline, color: errorRed, size: 16), const SizedBox(width: 8), Text(i)]),
          )).toList(),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  bool _isReadyForApproval(Map user, Map verif) {
    return (verif['aadhaarStatus'] == 'approved' || verif['govIdStatus'] == 'approved') &&
           verif['panStatus'] == 'approved' &&
           verif['businessProofStatus'] == 'approved' &&
           verif['propertyProofStatus'] == 'approved' &&
           user['emailVerified'] == true &&
           verif['phoneVerified'] == true;
  }

  Widget _buildDocumentProgressCard(Map verif, Map user) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Document Progress', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 12),
          _progressItem('Identity Documents', _countApproved([verif['aadhaarStatus'], verif['panStatus']]), 2),
          _progressItem('Business Documents', _countApproved([verif['businessProofStatus']]), 1),
          _progressItem('Ownership Proof', _countApproved([verif['propertyProofStatus']]), 1),
          _progressItem('Contact Verification', _countApproved([user['emailVerified'], verif['phoneVerified']]), 2),
        ],
      ),
    );
  }

  int _countApproved(List<dynamic> statuses) {
    return statuses.where((s) => s == 'approved' || s == true).length;
  }

  Widget _progressItem(String label, int approved, int total) {
    final isComplete = approved == total;
    final isMissing = approved == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : (isMissing ? Icons.cancel : Icons.error),
            size: 14,
            color: isComplete ? successGreen : (isMissing ? errorRed : warningOrange),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('$approved/$total ${isComplete ? "Approved" : (isMissing ? "Missing" : "Pending")}', 
            style: TextStyle(color: isComplete ? successGreen : (isMissing ? errorRed : warningOrange), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildKeyInfoCard(Map user, Map request) {
    final submittedAt = request['requestedAt'] ?? user['createdAt'];
    final updatedAt = user['updatedAt'];
    final riskLevel = user['compliance']?['riskLevel'] ?? 'Low Risk';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Key Info', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 12),
          _keyInfoItem('Submitted On', _formatTs(submittedAt)),
          _keyInfoItem('Last Updated', _formatTs(updatedAt)),
          _keyInfoItem('Submitted By', user['info']?['name'] ?? 'Partner'),
          _keyInfoItem('Request Type', 'New Hoster Registration'),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Risk Level', style: TextStyle(color: textLight, fontSize: 12)),
              _statusBadge(riskLevel, riskLevel.toString().toLowerCase().contains('low') ? successGreen : errorRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keyInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: textLight, fontSize: 11)),
          const Spacer(),
          Text(value, style: const TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatTs(dynamic ts) {
    if (ts is Timestamp) return DateFormat('dd MMM 2026, hh:mm a').format(ts.toDate());
    if (ts is String) return ts;
    return 'N/A';
  }

  Widget _buildProfileAndTimelineRow(Map user, Map verif, Map info) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: _buildPartnerProfileCard(user, info, verif)),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _buildSystemValidationCard(user, verif)),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: _buildReviewTimelineCard(user['id'] ?? widget.request['uid'] ?? widget.request['id'])),
        ],
      ),
    );
  }

  Widget _buildPartnerProfileCard(Map user, Map info, Map verif) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Partner Profile', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: successGreen, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: bgColor,
                          backgroundImage: info['profileImage'] != null ? CachedNetworkImageProvider(info['profileImage']) : null,
                          child: info['profileImage'] == null ? const Icon(Icons.person, size: 50, color: textLight) : null,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.check_circle, color: successGreen, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _miniBadge('EMAIL VERIFIED', user['emailVerified'] == true),
                  const SizedBox(height: 6),
                  _miniBadge('PHONE UNVERIFIED', verif['phoneVerified'] == true, invert: true),
                  const SizedBox(height: 6),
                  _miniBadge('KYC PARTIAL', false, color: warningOrange),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3.5,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 10,
                  children: [
                    _profileField('Full Name', info['name']),
                    _profileField('PAN Number', verif['panNumber']),
                    _profileField('Partner Type', user['hosterRole'] ?? 'Individual Owner'),
                    _profileField('Business Name', info['businessName'] ?? '—'),
                    _profileField('Email', info['email']),
                    _profileField('GST Number', info['gstNumber'] ?? '—'),
                    _profileField('Phone', info['phone']),
                    _profileField('City', info['city']),
                    _profileField('Date of Birth', info['dob']),
                    _profileField('State', info['state']),
                    _profileField('Aadhaar Number', verif['aadhaarNumber']),
                    _profileField('Joined', _formatTs(user['createdAt'])),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileField(String label, dynamic value) {
    final displayValue = (value == null || value.toString().isEmpty) ? '—' : value.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: textLight, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(displayValue, style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _miniBadge(String text, bool active, {Color? color, bool invert = false}) {
    final finalColor = color ?? (active ? successGreen : (invert ? warningOrange : textLight));
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(color: finalColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Center(child: Text(text, style: TextStyle(color: finalColor, fontSize: 8, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildSystemValidationCard(Map user, Map verif) {
    final aadhaarMatch = _checkNameMatch(user['info']?['name'], verif['aadhaarName']);
    final panMatch = _checkNameMatch(verif['aadhaarName'], verif['panName']);
    
    // Unified verification check (Check both root and verification map for backwards compatibility)
    final phoneVerified = (user['verification']?['phoneVerified'] == true || verif['phoneVerified'] == true);
    final emailVerified = (user['emailVerified'] == true || user['verification']?['emailVerified'] == true || verif['emailVerified'] == true);

    final businessProofMissing = verif['businessProofUrl'] == null && verif['businessProofFrontUrl'] == null;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Validation', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 20),
          _validationItem('Aadhaar name matches profile', aadhaarMatch),
          _validationItem('PAN name matches Aadhaar', panMatch),
          _validationItem('Phone number net verified', phoneVerified ? 'Match' : 'Mismatch'),
          _validationItem('Business proof missing', businessProofMissing ? 'Mismatch' : 'Match', invert: true),
          _validationItem('Email verified', emailVerified ? 'Match' : 'Mismatch'),
          _validationItem('No watchlist or fraud record found', 'Match'),
          const Spacer(),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Risk Level', style: TextStyle(color: textLight, fontSize: 12, fontWeight: FontWeight.w500)),
              _statusBadge('Low Risk', successGreen),
            ],
          ),
        ],
      ),
    );
  }

  String _checkNameMatch(String? name1, String? name2) {
    if (name1 == null || name2 == null) return 'Unable To Verify';
    return name1.toLowerCase().trim() == name2.toLowerCase().trim() ? 'Match' : 'Mismatch';
  }

  Widget _validationItem(String text, String result, {bool invert = false}) {
    final isMatch = result == 'Match';
    final isUnable = result == 'Unable To Verify';
    final color = isMatch ? successGreen : (isUnable ? warningOrange : errorRed);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(isMatch ? Icons.check_circle : (isUnable ? Icons.help : Icons.cancel), size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: textDark, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildReviewTimelineCard(String targetId) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review Timeline', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _auditService.getLogs(),
              builder: (context, snapshot) {
                final allLogs = snapshot.data?.docs ?? [];
                final logs = allLogs.where((d) {
                  final data = d.data();
                  return data['targetId'] == targetId;
                }).toList();
                
                if (logs.isEmpty) return const Center(child: Text('No history found', style: TextStyle(color: textLight, fontSize: 12)));

                return ListView.builder(
                  itemCount: logs.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final log = logs[index].data();
                    return _timelineItem(
                      _formatTs(log['timestamp']),
                      log['action']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'ACTION',
                      log['reason'] ?? '',
                      isLatest: index == 0,
                      isLast: index == logs.length - 1,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(String time, String title, String subtitle, {bool isLatest = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isLatest ? successGreen : bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: isLatest ? successGreen : borderColor, width: 2),
                ),
                child: Icon(
                  isLatest ? Icons.check : Icons.history,
                  color: isLatest ? Colors.white : textLight,
                  size: 14,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: borderColor,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: const TextStyle(color: textLight, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.bold)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(color: textLight, fontSize: 11, height: 1.3)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSections(Map user, Map verif) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Identity Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildDocCard('Aadhaar Card', verif['aadhaarFrontUrl'] ?? verif['govIdFrontUrl'], verif['aadhaarStatus'] ?? verif['govIdStatus'], 'aadhaar', verifData: verif)),
            const SizedBox(width: 16),
            Expanded(child: _buildDocCard('PAN Card', verif['panFrontUrl'] ?? verif['panUrl'], verif['panStatus'], 'pan', verifData: verif)),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Business Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
                  const SizedBox(height: 16),
                  _buildDocCard('Business Proof', verif['businessProofFrontUrl'] ?? verif['businessProofUrl'], verif['businessProofStatus'], 'business', verifData: verif),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Property Ownership', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
                  const SizedBox(height: 16),
                  _buildDocCard('Ownership Proof', verif['propertyProofFrontUrl'] ?? verif['propertyProofUrl'], verif['propertyProofStatus'], 'property', verifData: verif),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocCard(String title, String? url, String? status, String type, {Map? verifData}) {
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';
    final isPending = status == 'pending';
    final color = isApproved ? successGreen : (isRejected ? errorRed : warningOrange);

    final uploadedAt = verifData?['${type}UploadedAt'];
    final verifiedAt = verifData?['${type}VerifiedAt'];
    final verifiedBy = verifData?['${type}VerifiedBy'] ?? '—';

    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(type == 'pan' ? Icons.badge : Icons.assignment_ind, color: textLight, size: 20),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14)),
                const Spacer(),
                _statusBadge(status?.toUpperCase() ?? 'MISSING', color),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20, color: textLight),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          if (url != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: borderColor)),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: bgColor, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor, style: BorderStyle.solid)),
              child: const Center(child: Text('No document uploaded', style: TextStyle(color: textLight, fontSize: 12, fontStyle: FontStyle.italic))),
            ),
          if (url != null) ...[
             const SizedBox(height: 20),
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 20),
               child: Row(
                 children: [
                   _metaInfo('Uploaded On', _formatTs(uploadedAt)),
                   const Spacer(),
                   _metaInfo('Verified At', _formatTs(verifiedAt)),
                   const Spacer(),
                   _metaInfo('Verified By', verifiedBy.toString()),
                 ],
               ),
             ),
             Padding(
               padding: const EdgeInsets.all(16),
               child: Row(
                 children: [
                   Expanded(
                     child: _outlineButton(
                       'Reject', 
                       onPressed: isRejected ? () {} : () => _showRejectionDialog(type), 
                       color: errorRed,
                       icon: Icons.close,
                     )
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: _actionButton(
                       'Approve', 
                       onPressed: isApproved ? null : () => _handleDocAction(type, 'approved'), 
                       color: successGreen,
                       icon: Icons.check,
                     )
                   ),
                 ],
               ),
             ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: errorRed.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: errorRed.withOpacity(0.1))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: errorRed, size: 16),
                        const SizedBox(width: 8),
                        Text('Missing Document', style: TextStyle(color: errorRed, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('$title is required to verify the hoster and unlock platform features.', style: const TextStyle(color: textLight, fontSize: 11, height: 1.4)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _outlineButton('Request Document', onPressed: () {}, color: errorRed, icon: Icons.mail_outline),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaInfo(String label, String value) {
    final displayValue = (value == '—' || value == 'N/A') ? '—' : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: textLight, fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(displayValue, style: const TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Admin Notes (Internal)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
              const SizedBox(height: 12),
              _textField(_internalNotesController, 'Add internal note for your team...'),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Message to Partner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
              const SizedBox(height: 12),
              _textField(_partnerMessageController, 'Add message for the partner. This will be visible to them...'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _textField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: textLight, fontSize: 12),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              suffixIcon: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '${controller.text.length}/500',
                      style: const TextStyle(fontSize: 10, color: textLight),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStickyFooter(Map user, Map verif) {
    final docsApproved = _countApproved([verif['aadhaarStatus'], verif['panStatus'], verif['businessProofStatus'], verif['propertyProofStatus']]);
    final checksPassed = _countApproved([
      _checkNameMatch(user['info']?['name'], verif['aadhaarName']) == 'Match',
      _checkNameMatch(verif['aadhaarName'], verif['panName']) == 'Match',
      user['verification']?['phoneVerified'] == true,
      verif['businessProofUrl'] != null,
      user['emailVerified'] == true,
      true, // watchlist check dummy
      true, // fraud record dummy
    ]);
    final isReady = _isReadyForApproval(user, verif);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          _footerStat(Icons.description, '$docsApproved / 4', 'Approved', successGreen),
          const SizedBox(width: 40),
          _footerStat(Icons.verified_user, '$checksPassed / 7', 'Passed', successGreen),
          const SizedBox(width: 40),
          _footerStat(Icons.info, 'Pending Review', 'Action Required', warningOrange),
          const Spacer(),
          SizedBox(
            width: 180,
            child: _outlineButton('Request Changes', onPressed: () => _handleRequestChanges(), color: errorRed, icon: Icons.message),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 220,
            child: _actionButton('Approve Account', 
              onPressed: isReady ? _handleFinalApproval : null, 
              color: isReady ? successGreen : textLight.withOpacity(0.5),
              icon: Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRequestChanges() async {
    final uid = widget.request['uid'] ?? widget.request['id'];
    final message = _partnerMessageController.text.trim();
    
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a message to the partner describing the changes required.')));
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'accountStatus': 'requires_information',
        'status': 'requires_information',
        'adminReviewNote': _internalNotesController.text.trim(),
        'partnerMessage': message,
      });

      await _auditService.logAction(
        action: 'changes_requested',
        targetId: uid,
        targetType: 'hoster',
        reason: message,
      );

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': uid,
        'title': 'Information Required',
        'body': 'Admin has requested changes to your verification documents.',
        'type': 'verification_update',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Widget _footerStat(IconData icon, String value, String label, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 16)),
            Text(label, style: TextStyle(color: textLight, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  // Helper UI Widgets
  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _actionButton(String label, {required VoidCallback? onPressed, Color color = primaryBlue, IconData? icon}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 18),
          if (icon != null) const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _outlineButton(String label, {required VoidCallback onPressed, Color color = primaryBlue, IconData? icon}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.2)),
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 18),
          if (icon != null) const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _showRejectionDialog(String type) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject ${type.toUpperCase()} Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejecting this document. This will be visible to the partner.', style: TextStyle(fontSize: 13, color: textLight)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorRed),
            child: const Text('Reject Document'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty) {
      await _handleDocAction(type, 'rejected', reason: controller.text.trim());
    }
  }

  // Logic Handlers
  Future<void> _handleDocAction(String type, String status, {String? reason}) async {
    final uid = widget.request['uid'] ?? widget.request['id'];
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'verification.${type}Status': status,
        'verification.${type}VerifiedAt': status == 'approved' ? FieldValue.serverTimestamp() : null,
        'verification.${type}VerifiedBy': status == 'approved' ? 'Admin User' : null,
        'verification.${type}RejectionReason': reason,
      });

      await _auditService.logAction(
        action: 'document_${status}',
        targetId: uid,
        targetType: 'hoster',
        reason: 'Admin ${status} ${type} document${reason != null ? ": $reason" : ""}',
        extraData: {'docType': type},
      );
      
      if (status == 'rejected' && reason != null) {
        // Send notification
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': uid,
          'title': 'Document Rejected',
          'body': 'Your ${type.toUpperCase()} document was rejected. Reason: $reason',
          'type': 'verification_update',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleFinalApproval() async {
    final uid = widget.request['uid'] ?? widget.request['id'];
    setState(() => _isProcessing = true);
    try {
      await widget.adminService.approveHoster(uid);
      
      await _auditService.logAction(
        action: 'hoster_approved',
        targetId: uid,
        targetType: 'hoster',
        reason: 'Partner verified and account approved',
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}

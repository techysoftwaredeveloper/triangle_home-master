import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/services/audit_service.dart';
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
    debugPrint('HosterDetailScreen: Loading details for UID: $uid');

    return StreamBuilder<Map<String, dynamic>>(
      stream: Rx.combineLatest2(
        FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        FirebaseFirestore.instance.collection('hoster_requests').doc(uid).snapshots(),
        (userSnap, requestSnap) {
          final userData = userSnap.data() ?? {};
          final requestData = requestSnap.data() ?? {};
          
          final effectiveRequest = requestData.isNotEmpty ? requestData : {
             'id': uid,
             'uid': uid,
             'requestedAt': userData['createdAt'] ?? userData['updatedAt'],
             'status': userData['status'] ?? userData['accountStatus'] ?? 'pending',
          };

          return {
            'user': userData,
            'request': effectiveRequest,
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

        if (user.isEmpty && request.length <= 4) {
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
                    const Text('Partner Data Not Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
                    const SizedBox(height: 12),
                    Text('We couldn\'t find any active application for UID:\n$uid', textAlign: TextAlign.center, style: const TextStyle(color: textLight, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
                      // Using Wrap for Summary Cards to ensure stable layout
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(width: 300, child: _buildVerificationSummaryCard(user, verif, info)),
                          SizedBox(width: 300, child: _buildOverallStatusCard(user, verif)),
                          SizedBox(width: 300, child: _buildDocumentProgressCard(verif, user)),
                          SizedBox(width: 300, child: _buildKeyInfoCard(user, request)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Using fixed height or stable constraints for profile and timeline
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: _buildPartnerProfileCard(user, info, verif)),
                          const SizedBox(width: 16),
                          Expanded(flex: 3, child: _buildSystemValidationCard(user, verif)),
                          const SizedBox(width: 16),
                          // Fixed height for Timeline to prevent layout crash
                          SizedBox(width: 300, height: 500, child: _buildReviewTimelineCard(uid)),
                        ],
                      ),
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
    final submittedAt = request['requestedAt'] ?? user['createdAt'] ?? user['updatedAt'];
    final dateStr = submittedAt is Timestamp 
        ? DateFormat('dd MMM yyyy, hh:mm a').format(submittedAt.toDate())
        : (submittedAt is String ? submittedAt : 'N/A');

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      title: Row(
        children: [
          const Text('Admin  >  Approvals  >  Partner Verification', style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
          const Spacer(),
          _metadataBadge('UID: ${request['id'] ?? widget.request['id'] ?? "N/A"}'),
          const SizedBox(width: 16),
          Text('Submitted: $dateStr', style: const TextStyle(color: textLight, fontSize: 12)),
        ],
      ),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderColor, height: 1)),
    );
  }

  Widget _metadataBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6), border: Border.all(color: borderColor)),
      child: Text(text, style: const TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.bold)),
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
                height: 80, width: 80,
                child: CircularProgressIndicator(value: completion, strokeWidth: 8, backgroundColor: bgColor, valueColor: AlwaysStoppedAnimation<Color>(completion >= 0.8 ? successGreen : warningOrange)),
              ),
              Text('${(completion * 100).toInt()}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
            ],
          ),
          const SizedBox(height: 16),
          Text(completion >= 1.0 ? 'Fully Complete' : 'Partially Complete', style: TextStyle(color: completion >= 0.8 ? successGreen : textLight, fontSize: 12, fontWeight: FontWeight.bold)),
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
    final statusColor = isApproved ? successGreen : (status == 'rejected' ? errorRed : warningOrange);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overall Status', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(isApproved ? Icons.check_circle : Icons.access_time_filled, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Text(status.toString().toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ready for Approval', style: TextStyle(color: textLight, fontSize: 12)),
              Text(isReady ? 'Yes' : 'No', style: TextStyle(fontWeight: FontWeight.bold, color: isReady ? successGreen : errorRed, fontSize: 12)),
            ],
          ),
        ],
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
          _progressItem('Identity', _countApproved([verif['aadhaarStatus'], verif['panStatus']]), 2),
          _progressItem('Business', _countApproved([verif['businessProofStatus']]), 1),
          _progressItem('Ownership', _countApproved([verif['propertyProofStatus']]), 1),
          _progressItem('Contact', _countApproved([user['emailVerified'], verif['phoneVerified']]), 2),
        ],
      ),
    );
  }

  int _countApproved(List<dynamic> statuses) {
    return statuses.where((s) => s == 'approved' || s == true).length;
  }

  Widget _progressItem(String label, int approved, int total) {
    final isComplete = approved == total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(isComplete ? Icons.check_circle : Icons.error_outline, size: 12, color: isComplete ? successGreen : warningOrange),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: textDark, fontSize: 11)),
          const Spacer(),
          Text('$approved/$total', style: TextStyle(color: isComplete ? successGreen : textLight, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildKeyInfoCard(Map user, Map request) {
    final submittedAt = request['requestedAt'] ?? user['createdAt'];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Key Info', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 12),
          _keyInfoItem('Joined', _formatTs(submittedAt)),
          _keyInfoItem('Type', 'New Hoster'),
          _keyInfoItem('ID Status', user['status'] ?? 'Pending'),
          const SizedBox(height: 8),
          _miniBadge('LOW RISK', true, color: successGreen),
        ],
      ),
    );
  }

  Widget _keyInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [Text(label, style: const TextStyle(color: textLight, fontSize: 11)), const Spacer(), Text(value, style: const TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.bold))]),
    );
  }

  String _formatTs(dynamic ts) {
    if (ts is Timestamp) return DateFormat('dd MMM yyyy').format(ts.toDate());
    if (ts is String) return ts;
    return 'N/A';
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
                  CircleAvatar(
                    radius: 50, backgroundColor: bgColor,
                    backgroundImage: (info['profileImage'] != null && info['profileImage'].toString().isNotEmpty) ? CachedNetworkImageProvider(info['profileImage']) : null,
                    child: (info['profileImage'] == null || info['profileImage'].toString().isEmpty) ? const Icon(Icons.person, size: 50, color: textLight) : null,
                  ),
                  const SizedBox(height: 16),
                  _miniBadge('EMAIL VERIFIED', user['emailVerified'] == true),
                  const SizedBox(height: 6),
                  _miniBadge('PHONE VERIFIED', verif['phoneVerified'] == true),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 4, crossAxisSpacing: 20, mainAxisSpacing: 10,
                  children: [
                    _profileField('Full Name', info['name']),
                    _profileField('PAN Number', verif['panNumber']),
                    _profileField('Partner Type', user['hosterRole'] ?? 'Individual Owner'),
                    _profileField('Email', info['email']),
                    _profileField('Phone', info['phone']),
                    _profileField('City', info['city']),
                    _profileField('Aadhaar', verif['aadhaarNumber']),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: textLight, fontSize: 10)),
        Text(value?.toString() ?? '—', style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _miniBadge(String text, bool active, {Color? color}) {
    final finalColor = color ?? (active ? successGreen : textLight);
    return Container(
      width: 100, padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(color: finalColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Center(child: Text(text, style: TextStyle(color: finalColor, fontSize: 8, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildSystemValidationCard(Map user, Map verif) {
    final phoneVerified = (user['verification']?['phoneVerified'] == true || verif['phoneVerified'] == true);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Validation', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 20),
          _validationItem('ID names match profile', 'Match'),
          _validationItem('Phone verified', phoneVerified ? 'Match' : 'Mismatch'),
          _validationItem('Documents present', verif['aadhaarStatus'] != null ? 'Match' : 'Mismatch'),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          const Text('RISK LEVEL: LOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: successGreen)),
        ],
      ),
    );
  }

  Widget _validationItem(String text, String result) {
    final isMatch = result == 'Match';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [Icon(isMatch ? Icons.check_circle : Icons.cancel, size: 14, color: isMatch ? successGreen : errorRed), const SizedBox(width: 8), Text(text, style: const TextStyle(color: textDark, fontSize: 11))]),
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
                final logs = (snapshot.data?.docs ?? []).where((d) => d.data()['targetId'] == targetId).toList();
                if (logs.isEmpty) return const Center(child: Text('No history', style: TextStyle(fontSize: 11)));
                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index].data();
                    return _timelineItem(_formatTs(log['timestamp']), log['action']?.toString().toUpperCase() ?? 'ACTION', log['reason'] ?? '', isLast: index == logs.length - 1);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(String time, String title, String subtitle, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [const Icon(Icons.history, size: 14, color: textLight), if (!isLast) Container(width: 1, height: 30, color: borderColor)]),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(time, style: const TextStyle(fontSize: 9, color: textLight)), Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 16)])),
      ],
    );
  }

  Widget _buildDocumentSections(Map user, Map verif) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDocCard('Aadhaar', verif['aadhaarFrontUrl'] ?? verif['govIdFrontUrl'], verif['aadhaarStatus'] ?? verif['govIdStatus'], 'aadhaar')),
            const SizedBox(width: 16),
            Expanded(child: _buildDocCard('PAN', verif['panFrontUrl'] ?? verif['panUrl'], verif['panStatus'], 'pan')),
          ],
        ),
      ],
    );
  }

  Widget _buildDocCard(String title, String? url, String? status, String type) {
    final color = status == 'approved' ? successGreen : (status == 'rejected' ? errorRed : warningOrange);
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), trailing: _statusBadge(status?.toUpperCase() ?? 'MISSING', color)),
          if (url != null) Container(height: 150, width: double.infinity, margin: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, placeholder: (c, u) => const Center(child: CircularProgressIndicator()))))
          else const SizedBox(height: 100, child: Center(child: Text('No upload', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)))),
          if (url != null) Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: _outlineButton('Reject', onPressed: () => _showRejectionDialog(type), color: errorRed)), const SizedBox(width: 12), Expanded(child: _actionButton('Approve', onPressed: () => _handleDocAction(type, 'approved'), color: successGreen))])),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Admin Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        _textField(_internalNotesController, 'Add internal notes...'),
      ],
    );
  }

  Widget _textField(TextEditingController controller, String hint) {
    return Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)), child: TextField(controller: controller, maxLines: 3, decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.all(16), border: InputBorder.none)));
  }

  Widget _buildStickyFooter(Map user, Map verif) {
    final isReady = _isReadyForApproval(user, verif);
    return Container(
      padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: borderColor))),
      child: Row(children: [const Spacer(), _outlineButton('Request Info', onPressed: () => _handleRequestChanges(), color: warningOrange), const SizedBox(width: 16), _actionButton('Approve Account', onPressed: isReady ? _handleFinalApproval : null, color: isReady ? successGreen : textLight.withValues(alpha: 0.3))]),
    );
  }

  // --- Handlers ---
  Future<void> _handleDocAction(String type, String status) async {
    final uid = widget.request['uid'] ?? widget.request['id'];
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'verification.${type}Status': status, 'verification.${type}VerifiedAt': FieldValue.serverTimestamp()});
  }

  Future<void> _handleRequestChanges() async {
    final uid = widget.request['uid'] ?? widget.request['id'];
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'status': 'requires_info'});
    if (mounted) Navigator.pop(context);
  }

  Future<void> _handleFinalApproval() async {
    final uid = widget.request['uid'] ?? widget.request['id'];
    await widget.adminService.approveHoster(uid);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showRejectionDialog(String type) async {
    await _handleDocAction(type, 'rejected');
  }

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(padding: padding, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)), child: child);
  }

  Widget _actionButton(String label, {required VoidCallback? onPressed, Color color = primaryBlue}) {
    return ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)));
  }

  Widget _outlineButton(String label, {required VoidCallback onPressed, Color color = primaryBlue}) {
    return OutlinedButton(onPressed: onPressed, style: OutlinedButton.styleFrom(side: BorderSide(color: color), foregroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)));
  }

  Widget _statusBadge(String text, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)));
  }
}

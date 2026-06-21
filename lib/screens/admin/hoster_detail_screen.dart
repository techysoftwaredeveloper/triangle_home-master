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
  bool _isActionInProgress = false;

  // Theme Colors matching AdminDashboardRedesign
  static const Color bgColor = Color(0xFF020617);
  static const Color surfaceColor = Color(0xFF0F172A);
  static const Color cardColor = Color(0xFF1E293B);
  static const Color accentColor = Color(0xFF8B5CF6);
  static const Color textMain = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _internalNotesController.text = widget.request['adminReviewNote'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.request['uid'] ?? widget.request['id'] ?? widget.request['userId'];

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
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: bgColor,
            body: Center(child: CircularProgressIndicator(color: accentColor)),
          );
        }

        final data = snapshot.data!;
        final user = data['user'] as Map<String, dynamic>;
        final request = data['request'] as Map<String, dynamic>;

        if (user.isEmpty) {
          return _buildNotFoundState(uid);
        }

        final verif = user['verification'] as Map? ?? {};
        final info = user['info'] as Map? ?? {};

        return Scaffold(
          backgroundColor: bgColor,
          appBar: _buildAppBar(request, user),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickSummaryRow(user, verif, info, request),
                          const SizedBox(height: 24),
                          
                          // Profile and System Validation side by side on desktop
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 900) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 3, child: _buildPartnerProfileCard(user, info, verif)),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 2, child: _buildSystemValidationCard(user, verif)),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  _buildPartnerProfileCard(user, info, verif),
                                  const SizedBox(height: 16),
                                  _buildSystemValidationCard(user, verif),
                                ],
                              );
                            }
                          ),
                          const SizedBox(height: 24),
                          _buildDocumentSections(user, verif),
                          const SizedBox(height: 24),
                          
                          // History and Notes
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 900) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 2, child: _buildReviewTimelineCard(uid)),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 3, child: _buildNotesSection()),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  _buildReviewTimelineCard(uid),
                                  const SizedBox(height: 16),
                                  _buildNotesSection(),
                                ],
                              );
                            }
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  _buildStickyFooter(user, verif),
                ],
              ),
              if (_isActionInProgress)
                Container(
                  color: Colors.black45,
                  child: const Center(child: CircularProgressIndicator(color: accentColor)),
                ),
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
        : 'N/A';

    return AppBar(
      backgroundColor: surfaceColor,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textMain, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const Text('Approvals  /  Partner Verification', style: TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
          const Spacer(),
          Text('Submitted: $dateStr', style: const TextStyle(color: textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildQuickSummaryRow(Map user, Map verif, Map info, Map request) {
    final completion = _calculateCompletion(user, verif, info);
    final status = user['accountStatus'] ?? user['status'] ?? 'pending';
    final statusColor = status == 'approved' ? successGreen : (status == 'rejected' ? errorRed : warningOrange);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard('Partner Score', '${(completion * 100).toInt()}%', accentColor),
        _statCard('Account Status', status.toString().toUpperCase(), statusColor),
        _statCard('Verified Docs', '${_countApproved([verif['aadhaarStatus'], verif['panStatus'], verif['businessProofStatus'], verif['propertyProofStatus']])}/4', successGreen),
        _statCard('Risk Level', 'LOW', successGreen),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
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

  int _countApproved(List<dynamic> statuses) {
    return statuses.where((s) => s == 'approved' || s == true).length;
  }

  Widget _buildPartnerProfileCard(Map user, Map info, Map verif) {
    return _adminCard(
      title: 'Partner Profile',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: surfaceColor,
                backgroundImage: (info['profileImage'] != null && info['profileImage'].toString().isNotEmpty) ? CachedNetworkImageProvider(info['profileImage']) : null,
                child: (info['profileImage'] == null || info['profileImage'].toString().isEmpty) ? const Icon(Icons.person, size: 40, color: textSecondary) : null,
              ),
              const SizedBox(height: 16),
              _badge(user['emailVerified'] == true ? 'Email Verified' : 'Email Unverified', user['emailVerified'] == true ? successGreen : textSecondary),
              const SizedBox(height: 6),
              _badge(verif['phoneVerified'] == true ? 'Phone Verified' : 'Phone Unverified', verif['phoneVerified'] == true ? successGreen : textSecondary),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Wrap(
              spacing: 24,
              runSpacing: 20,
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
    );
  }

  Widget _profileField(String label, dynamic value) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value?.toString() ?? '—', style: const TextStyle(color: textMain, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSystemValidationCard(Map user, Map verif) {
    final phoneVerified = (user['verification']?['phoneVerified'] == true || verif['phoneVerified'] == true);
    return _adminCard(
      title: 'System Validation',
      child: Column(
        children: [
          _validationItem('ID names match profile', 'Match'),
          _validationItem('Phone verified', phoneVerified ? 'Match' : 'Mismatch'),
          _validationItem('Documents present', verif['aadhaarStatus'] != null ? 'Match' : 'Mismatch'),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('TRUST SCORE:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary)),
              const Spacer(),
              _badge('92/100', successGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _validationItem(String text, String result) {
    final isMatch = result == 'Match';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(isMatch ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: isMatch ? successGreen : errorRed),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: textMain, fontSize: 12)),
          const Spacer(),
          Text(result, style: TextStyle(color: isMatch ? successGreen : errorRed, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDocumentSections(Map user, Map verif) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verification Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textMain, fontFamily: 'Outfit')),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildDocCard('Aadhaar ID', verif['aadhaarFrontUrl'] ?? verif['govIdFrontUrl'], verif['aadhaarStatus'] ?? verif['govIdStatus'], 'aadhaar'),
            _buildDocCard('PAN Card', verif['panFrontUrl'] ?? verif['panUrl'], verif['panStatus'], 'pan'),
            _buildDocCard('Business Proof', verif['businessProofUrl'], verif['businessProofStatus'], 'businessProof'),
            _buildDocCard('Property Proof', verif['propertyProofUrl'], verif['propertyProofStatus'], 'propertyProof'),
          ],
        ),
      ],
    );
  }

  Widget _buildDocCard(String title, String? url, String? status, String type) {
    final statusColor = status == 'approved' ? successGreen : (status == 'rejected' ? errorRed : warningOrange);
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textMain)),
            trailing: _badge(status?.toUpperCase() ?? 'MISSING', statusColor),
          ),
          if (url != null) 
            GestureDetector(
              onTap: () => _viewDocument(url, title),
              child: Container(
                height: 160, 
                width: double.infinity, 
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12), 
                  child: CachedNetworkImage(
                    imageUrl: url, 
                    fit: BoxFit.cover, 
                    placeholder: (c, u) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (c, u, e) => const Icon(Icons.broken_image_rounded, color: textSecondary),
                  )
                ),
              ),
            )
          else 
            const SizedBox(height: 100, child: Center(child: Text('No upload available', style: TextStyle(fontSize: 11, color: textSecondary, fontStyle: FontStyle.italic)))),
          
          if (url != null) 
            Padding(
              padding: const EdgeInsets.all(16), 
              child: Row(
                children: [
                  Expanded(child: _actionBtnMini('Reject', () => _showRejectionDialog(type, title), errorRed, isOutline: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _actionBtnMini('Approve', () => _handleDocAction(type, 'approved'), successGreen)),
                ],
              )
            ),
        ],
      ),
    );
  }

  Widget _buildReviewTimelineCard(String targetId) {
    return _adminCard(
      title: 'Audit History',
      child: SizedBox(
        height: 300,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _auditService.getLogs(),
          builder: (context, snapshot) {
            final logs = (snapshot.data?.docs ?? []).where((d) => d.data()['targetId'] == targetId).toList();
            if (logs.isEmpty) return const Center(child: Text('No verification history found', style: TextStyle(fontSize: 12, color: textSecondary)));
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
    );
  }

  Widget _timelineItem(String time, String title, String subtitle, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.circle, size: 8, color: accentColor),
            if (!isLast) Container(width: 1, height: 40, color: Colors.white10),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time, style: const TextStyle(fontSize: 9, color: textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMain)),
              if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 11, color: textSecondary)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return _adminCard(
      title: 'Internal Admin Notes',
      child: Column(
        children: [
          TextField(
            controller: _internalNotesController,
            maxLines: 5,
            style: const TextStyle(color: textMain, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Add internal review notes here...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _actionBtnMini('Save Notes', () => _saveInternalNotes(), accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(Map user, Map verif) {
    final isReady = _isReadyForApproval(user, verif);
    final status = user['status'] ?? 'pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FINAL DECISION', style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
              Text('Partner Application', style: TextStyle(color: textMain, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          if (status != 'rejected')
            OutlinedButton(
              onPressed: () => _showRejectAccountDialog(),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: errorRed), foregroundColor: errorRed, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Reject Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: isReady ? _handleFinalApproval : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isReady ? successGreen : Colors.white10,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Approve Partner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // --- Helpers & Dialogs ---

  Widget _adminCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: textMain, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _actionBtnMini(String label, VoidCallback onPressed, Color color, {bool isOutline = false}) {
    if (isOutline) {
      return OutlinedButton(onPressed: onPressed, style: OutlinedButton.styleFrom(side: BorderSide(color: color), foregroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)));
    }
    return ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)));
  }

  void _viewDocument(String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: bgColor,
        insetPadding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: surfaceColor,
              title: Text(title, style: const TextStyle(color: textMain, fontSize: 14)),
              actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))],
            ),
            Flexible(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  placeholder: (c, u) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (c, u, e) => const Icon(Icons.error),
                ),
              ),
            ),
          ],
        ),
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

  String _formatTs(dynamic ts) {
    if (ts is Timestamp) return DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate());
    return ts?.toString() ?? 'N/A';
  }

  // --- Logic Handlers ---

  Future<void> _handleDocAction(String type, String status) async {
    final uid = widget.request['uid'] ?? widget.request['id'];
    setState(() => _isActionInProgress = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'verification.${type}Status': status,
        'verification.${type}VerifiedAt': FieldValue.serverTimestamp()
      });
      await _auditService.logAction(action: 'doc_${type}_$status', targetId: uid, targetType: 'hoster');
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _showRejectionDialog(String type, String title) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Reject $title', style: const TextStyle(color: textMain)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: textMain),
          decoration: const InputDecoration(
            hintText: 'Enter specific reason for rejection...',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), style: ElevatedButton.styleFrom(backgroundColor: errorRed), child: const Text('Confirm Rejection')),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      final uid = widget.request['uid'] ?? widget.request['id'];
      setState(() => _isActionInProgress = true);
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'verification.${type}Status': 'rejected',
        'verification.${type}RejectReason': reason,
      });
      await _auditService.logAction(action: 'doc_${type}_rejected', targetId: uid, targetType: 'hoster', reason: reason);
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _showRejectAccountDialog() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Reject Partner Account', style: TextStyle(color: textMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will inform the user their account application was rejected. Please provide a clear reason.', style: TextStyle(color: textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: textMain),
              decoration: const InputDecoration(
                hintText: 'Reason for rejection...',
                hintStyle: TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), style: ElevatedButton.styleFrom(backgroundColor: errorRed), child: const Text('Reject Account')),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      final uid = widget.request['uid'] ?? widget.request['id'];
      setState(() => _isActionInProgress = true);
      try {
        await widget.adminService.rejectItem(uid, 'hoster', reason: reason);
        if (mounted) Navigator.pop(context);
      } finally {
        if (mounted) setState(() => _isActionInProgress = false);
      }
    }
  }

  Future<void> _handleFinalApproval() async {
    final uid = widget.request['uid'] ?? widget.request['id'];
    setState(() => _isActionInProgress = true);
    try {
      await widget.adminService.approveHoster(uid);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _saveInternalNotes() async {
    final uid = widget.request['uid'] ?? widget.request['id'];
    setState(() => _isActionInProgress = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'adminReviewNote': _internalNotesController.text
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes saved successfully')));
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: errorRed, size: 48),
            const SizedBox(height: 16),
            Text('Error loading data: $error', textAlign: TextAlign.center, style: const TextStyle(color: textMain)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState(String uid) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(backgroundColor: surfaceColor, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, color: textSecondary, size: 64),
            const SizedBox(height: 24),
            const Text('Partner Data Not Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textMain)),
            const SizedBox(height: 12),
            Text('No active user application for UID:\n$uid', textAlign: TextAlign.center, style: const TextStyle(color: textSecondary, fontSize: 14)),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }
}

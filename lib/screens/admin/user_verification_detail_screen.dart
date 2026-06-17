import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class UserVerificationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  final AdminService adminService;

  const UserVerificationDetailScreen({
    super.key,
    required this.request,
    required this.adminService,
  });

  @override
  State<UserVerificationDetailScreen> createState() => _UserVerificationDetailScreenState();
}

class _UserVerificationDetailScreenState extends State<UserVerificationDetailScreen> {
  bool _isProcessing = false;
  final TextEditingController _rejectionReasonController = TextEditingController();

  static const Color bgColor = Color(0xFF020617);
  static const Color cardColor = Color(0xFF0F172A);
  static const Color borderColor = Color(0xFF1E293B);
  static const Color accentPurple = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final uid = widget.request['uid'] ?? widget.request['id'];
    
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: bgColor,
            body: Center(child: CircularProgressIndicator(color: accentPurple)),
          );
        }

        final user = snapshot.data!.data() ?? {};
        final verif = user['verification'] as Map? ?? {};
        final info = user['info'] as Map? ?? {};
        final role = user['role'] ?? 'student';

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                const Text(
                  'Admin  >  Approvals  >  ',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                Text(
                  role == 'student' ? 'Student Verification' : 'User Verification',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserSummaryCard(user, info, role),
                      const SizedBox(height: 32),
                      _buildDocumentSection(verif, role),
                      const SizedBox(height: 32),
                      _buildMetadataSection(widget.request),
                    ],
                  ),
                ),
              ),
              _buildActionFooter(uid),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserSummaryCard(Map user, Map info, dynamic role) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: accentPurple.withValues(alpha: 0.1),
            child: Text(
              (info['name'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(color: accentPurple, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info['name'] ?? 'Anonymous User',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${role.toString().toUpperCase()}  •  ${info['email'] ?? 'No Email'}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.white38, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      info['phoneNumber'] ?? 'No Phone',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _StatusBadge(status: user['status'] ?? 'pending'),
        ],
      ),
    );
  }

  Widget _buildDocumentSection(Map verif, dynamic role) {
    final typeLabel = role == 'student' ? 'Student ID' : 'Professional ID';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.assignment_ind_outlined, color: accentPurple, size: 20),
            const SizedBox(width: 12),
            Text(
              '$typeLabel Review',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildDocCard('Front Side', verif['roleIdFrontUrl'])),
            const SizedBox(width: 20),
            Expanded(child: _buildDocCard('Back Side', verif['roleIdBackUrl'])),
          ],
        ),
      ],
    );
  }

  Widget _buildDocCard(String label, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: url != null ? () => _showFullScreenImage(url) : null,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: url != null 
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white24),
                  ),
                )
              : const Center(child: Text('Not Uploaded', style: TextStyle(color: Colors.white24))),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(Map request) {
    final date = request['createdAt'] as Timestamp?;
    final dateStr = date != null ? DateFormat('dd MMM yyyy, hh:mm a').format(date.toDate()) : 'N/A';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMetaRow('Submission Date', dateStr),
          const Divider(color: Colors.white10, height: 24),
          _buildMetaRow('Verification ID', request['id'] ?? 'N/A'),
          const Divider(color: Colors.white10, height: 24),
          _buildMetaRow('Request Type', 'Identity Verification'),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionFooter(String uid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: cardColor,
        border: const Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _handleApproval(uid, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Approve Document', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing ? null : () => _showRejectDialog(uid),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Reject Request', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApproval(String uid, bool approved) async {
    setState(() => _isProcessing = true);
    try {
      if (approved) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'verification': {
            'roleIdVerified': true,
            'roleIdStatus': 'approved',
            'roleIdApprovedAt': FieldValue.serverTimestamp(),
          },
          'status': 'approved', // Also set overall status if first verification
        }, SetOptions(merge: true));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document approved successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRejectDialog(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
        title: const Text('Reject Verification', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _rejectionReasonController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter reason for rejection...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(this.context);
              setState(() => _isProcessing = true);
              try {
                await FirebaseFirestore.instance.collection('users').doc(uid).set({
                  'verification': {
                    'roleIdVerified': false,
                    'roleIdStatus': 'rejected',
                    'roleIdRejectReason': _rejectionReasonController.text,
                    'roleIdRejectedAt': FieldValue.serverTimestamp(),
                  }
                }, SetOptions(merge: true));
                if (mounted) {
                  messenger.showSnackBar(const SnackBar(content: Text('Request rejected')));
                  Navigator.pop(this.context);
                }
              } catch (e) {
                if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Confirm Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.orange;
    if (status == 'approved' || status == 'active') color = Colors.green;
    if (status == 'rejected' || status == 'banned') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

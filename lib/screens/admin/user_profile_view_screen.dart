import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserProfileViewScreen extends StatefulWidget {
  final String userId;
  final AdminService adminService;
  final Map<String, dynamic>? initialData;

  const UserProfileViewScreen({
    super.key,
    required this.userId,
    required this.adminService,
    this.initialData,
  });

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  bool _isUpdating = false;

  String _formatRole(dynamic role) {
    final r = role?.toString().toLowerCase() ?? 'student';
    if (r == 'user' || r == 'student' || r.isEmpty) return 'Student';
    return r[0].toUpperCase() + r.substring(1);
  }

  Color _getRoleColor(String role) {
    final r = role.toLowerCase();
    if (r.contains('student')) return const Color(0xFF2563EB);
    if (r.contains('hoster')) return const Color(0xFFD97706);
    if (r.contains('professional')) return const Color(0xFF7C3AED);
    return Colors.grey;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp)
      return DateFormat('dd MMM yyyy, hh:mm a').format(date.toDate());
    return date.toString();
  }

  String _formatStatus(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'pending' || status == 'under review') return 'Pending';
    return status[0].toUpperCase() + status.substring(1);
  }

  Color _getStatusColor(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    switch (status) {
      case 'contacted':
        return const Color(0xFF7C3AED);
      case 'shortlisted':
        return const Color(0xFF2563EB);
      case 'converted':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFD97706);
    }
  }

  Future<void> _handleToggleStatus(bool isActive) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await widget.adminService.toggleUserStatus(widget.userId, !isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive
                  ? 'User deactivated successfully'
                  : 'User activated successfully',
            ),
            backgroundColor: isActive ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.adminService.getUsersStream(),
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];
        final user = users.firstWhere(
          (u) => u['id'] == widget.userId,
          orElse: () => widget.initialData ?? {},
        );

        if (user.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final info = user['info'] as Map<String, dynamic>? ?? {};
        final permissions = user['permissions'] as Map<String, dynamic>? ?? {};
        final role = _formatRole((user['role'] ?? permissions['role']));
        final isActive = user['is_active'] as bool? ?? true;
        final name = info['name'] ?? 'Unknown User';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        final profileImage = info['profileImage'] ?? user['profileImage'];

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'User Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontFamily: 'Outfit',
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_left_rounded,
                color: Color(0xFF1E293B),
                size: 32,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFFF1F5F9),
                              child: ClipOval(
                                child:
                                    profileImage != null
                                        ? CachedNetworkImage(
                                          imageUrl: profileImage,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                          placeholder:
                                              (context, url) =>
                                                  const CircularProgressIndicator(),
                                          errorWidget:
                                              (context, url, error) => Text(
                                                initial,
                                                style: const TextStyle(
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        )
                                        : Text(
                                          initial,
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              fontFamily: 'Outfit',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user['id']?.toString().toUpperCase() ?? 'USR-NEW',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              StatusBadge(
                                text: role,
                                color: _getRoleColor(role),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(
                                text: isActive ? 'ACTIVE' : 'INACTIVE',
                                color: isActive ? Colors.green : Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                    const SizedBox(height: 24),

                    // Contact Information
                    _buildSectionTitle('CONTACT INFORMATION'),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.email_outlined,
                      'Email Address',
                      info['email'] ?? 'No Email',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.phone_outlined,
                      'Phone Number',
                      info['phoneNumber'] ?? 'No Phone',
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                    const SizedBox(height: 24),

                    // Account Details
                    _buildSectionTitle('ACCOUNT DETAILS'),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.calendar_today_outlined,
                      'Joined On',
                      _formatDate(user['createdAt']),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.security_outlined,
                      'Account Status',
                      isActive ? 'Active' : 'Deactivated',
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                    const SizedBox(height: 24),

                    // Suggestion Activity
                    _buildSectionTitle('SUGGESTION ACTIVITY'),
                    const SizedBox(height: 16),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: widget.adminService.getUserSuggestionsStream(
                        widget.userId,
                      ),
                      builder: (context, suggestionSnapshot) {
                        final suggestions = suggestionSnapshot.data ?? [];
                        if (suggestions.isEmpty) {
                          return const Text(
                            'No suggestion activity yet.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          );
                        }

                        return Column(
                          children:
                              suggestions
                                  .map((s) => _buildSuggestionCard(s))
                                  .toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Actions
                    _buildActionBtn(
                      isActive ? 'Deactivate User' : 'Activate User',
                      isActive
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF0FDF4),
                      isActive
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                      isActive
                          ? Icons.block_flipped
                          : Icons.check_circle_outline,
                      () => _handleToggleStatus(isActive),
                    ),
                    const SizedBox(height: 12),
                    _buildActionBtn(
                      'Reset Password',
                      const Color(0xFFF8FAFC),
                      const Color(0xFF64748B),
                      Icons.lock_reset_rounded,
                      () {},
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
              if (_isUpdating)
                Container(
                  color: Colors.white.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> s) {
    final status = _formatStatus(s['status']);
    final statusColor = _getStatusColor(s['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  s['business_name'] ?? 'Untitled Property',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(text: status, color: statusColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s['category'] ?? 'Accommodation',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 10,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat(
                  'dd MMM yyyy',
                ).format((s['createdAt'] as Timestamp).toDate()),
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    String label,
    Color bg,
    Color text,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: text),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';

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

class _UserProfileViewScreenState extends State<UserProfileViewScreen>
    with SingleTickerProviderStateMixin {
  bool _isUpdating = false;
  late TabController _tabController;

  // Expanded state for sections
  bool _contactExpanded = true;
  bool _verificationExpanded = true;
  bool _hosterExpanded = true;
  bool _studentExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────── Formatters ───────────────────

  String _formatRole(dynamic role) {
    final r = role?.toString().toLowerCase() ?? 'student';
    if (r == 'user' || r == 'student' || r.isEmpty) return 'Student';
    if (r == 'professional') return 'Professional';
    if (r == 'hoster') return 'Hoster';
    if (r == 'owner') return 'Owner';
    if (r == 'manager') return 'Manager';
    if (r == 'agency') return 'Agency';
    if (r == 'admin') return 'Admin';
    if (r == 'superadmin') return 'Super Admin';
    return r[0].toUpperCase() + r.substring(1);
  }

  Color _getRoleColor(String role) {
    final r = role.toLowerCase();
    if (r.contains('student')) return const Color(0xFF2563EB);
    if (r.contains('hoster')) return const Color(0xFFD97706);
    if (r.contains('owner')) return const Color(0xFF10B981);
    if (r.contains('professional')) return const Color(0xFF7C3AED);
    if (r.contains('admin')) return const Color(0xFFDC2626);
    return Colors.grey;
  }

  String _formatDate(dynamic date, {bool withTime = false}) {
    if (date == null) return 'N/A';
    DateTime dt;
    if (date is Timestamp) {
      dt = date.toDate();
    } else if (date is String) {
      dt = DateTime.tryParse(date) ?? DateTime.now();
    } else {
      return 'N/A';
    }
    return withTime
        ? DateFormat('dd MMM yyyy, hh:mm a').format(dt)
        : DateFormat('dd MMM yyyy').format(dt);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'verified':
      case 'success':
        return const Color(0xFF16A34A);
      case 'pending':
      case 'under review':
        return const Color(0xFFD97706);
      case 'rejected':
      case 'banned':
      case 'blocked':
      case 'failed':
        return const Color(0xFFDC2626);
      case 'inactive':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  // ─────────────────── Actions ───────────────────

  Future<void> _handleToggleStatus(bool isActive) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await widget.adminService.toggleUserStatus(widget.userId, !isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive
                ? 'User deactivated successfully'
                : 'User activated successfully'),
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

  Future<void> _handleUpdateRole(String newRole) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await widget.adminService.updateUserRole(widget.userId, newRole);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Role updated to ${newRole[0].toUpperCase()}${newRole.substring(1)}'),
            backgroundColor: Colors.green,
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

  Future<void> _verifyDoc(String fieldKey) async {
    setState(() => _isUpdating = true);
    try {
      final Map<String, dynamic> update = {
        'verification.${fieldKey}Verified': true,
        'verification.${fieldKey}Status': 'verified',
        'verification.${fieldKey}VerifiedAt': FieldValue.serverTimestamp(),
        'verification.${fieldKey}RejectReason': FieldValue.delete(),
      };
      if (fieldKey == 'govId') {
        update['verification.aadhaarVerified'] = true;
        update['verification.aadhaarStatus'] = 'verified';
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(update);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document verified successfully'),
            backgroundColor: Color(0xFF16A34A),
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

  Future<void> _revokeDoc(String fieldKey) async {
    setState(() => _isUpdating = true);
    try {
      final Map<String, dynamic> update = {
        'verification.${fieldKey}Verified': false,
        'verification.${fieldKey}Status': 'pending',
      };
      if (fieldKey == 'govId') {
        update['verification.aadhaarVerified'] = false;
        update['verification.aadhaarStatus'] = 'pending';
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(update);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Revoke failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _showRejectDocDialog(String fieldKey) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x1AFFFFFF))),
        title: const Text('Reject Document', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Explain why this document is rejected...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Reject Document', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason == null) return;
    setState(() => _isUpdating = true);
    try {
      final Map<String, dynamic> update = {
        'verification.${fieldKey}Verified': false,
        'verification.${fieldKey}Status': 'rejected',
        'verification.${fieldKey}RejectReason': reason,
      };
      if (fieldKey == 'govId') {
        update['verification.aadhaarVerified'] = false;
        update['verification.aadhaarStatus'] = 'rejected';
        update['verification.aadhaarRejectReason'] = reason;
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(update);
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

  // ─────────────────── Build ───────────────────

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

        if (user.isEmpty && snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF020617),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFF020617),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('User Not Found', style: TextStyle(color: Colors.white)),
              leading: BackButton(color: Colors.white, onPressed: () => Navigator.pop(context)),
            ),
            body: const Center(child: Text('User data not available.', style: TextStyle(color: Colors.white54))),
          );
        }

        final info = Map<String, dynamic>.from(user['info'] ?? {});
        final permissions = Map<String, dynamic>.from(user['permissions'] ?? {});
        final verification = Map<String, dynamic>.from(user['verification'] ?? {});
        final rawRole = (user['role'] ?? permissions['role'])?.toString() ?? 'student';
        final role = _formatRole(rawRole);
        final isActive = user['is_active'] as bool? ?? true;
        final name = info['name']?.toString() ?? 'Unknown User';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        final profileImage = info['profileImage'] ?? user['profileImage'];
        final onboardingStatus = (user['status'] ?? user['accountStatus'] ?? permissions['status'] ?? '').toString();
        final isHoster = ['hoster', 'owner', 'manager', 'agency'].contains(rawRole.toLowerCase());

        return Scaffold(
          backgroundColor: const Color(0xFF020617),
          appBar: _buildAppBar(name, isActive, rawRole),
          body: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 1100;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar for Stats (Visible only on Wide screens)
                      if (isWide)
                        Container(
                          width: 320,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            border: Border(right: BorderSide(color: Color(0x0DFFFFFF))),
                          ),
                          child: _buildSidebar(user, isActive, onboardingStatus, isHoster),
                        ),

                      // Main Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isWide) _buildCompactHero(name, initial, profileImage, role, isActive),
                              
                              const SizedBox(height: 24),
                              _buildTabBar(),
                              const SizedBox(height: 32),
                              
                              _buildTabContent(
                                user,
                                info,
                                permissions,
                                verification,
                                isActive,
                                isHoster,
                                rawRole,
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (_isUpdating)
                Container(
                  color: Colors.black45,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
          bottomNavigationBar: _buildBottomActions(isActive, user, permissions),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(String name, bool isActive, String rawRole) {
    return AppBar(
      backgroundColor: const Color(0xFF020617),
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
          ),
          const SizedBox(width: 12),
          const _LiveBadge(),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        _buildActionBtn('Edit Profile', Icons.edit_outlined, () {}),
        const SizedBox(width: 12),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          color: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0x1AFFFFFF))),
          onSelected: (v) {
            if (v == 'role') {
              _showChangeRoleBottomSheet(context, rawRole.toLowerCase());
            } else if (v == 'toggle') {
              _handleToggleStatus(isActive);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'role', child: _popupItem(Icons.manage_accounts_outlined, 'Change Role', null)),
            PopupMenuItem(
              value: 'toggle',
              child: _popupItem(
                isActive ? Icons.block : Icons.check_circle_outline,
                isActive ? 'Deactivate User' : 'Activate User',
                isActive ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildActionBtn(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white70),
      label: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: const BorderSide(color: Color(0x1AFFFFFF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSidebar(Map<String, dynamic> user, bool isActive, String onboardingStatus, bool isHoster) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User Intelligence', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 32),
          _buildUserPrimaryInfo(user, isActive, onboardingStatus, isHoster),
          const SizedBox(height: 48),
          const Text('Quick Insights', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 20),
          _buildQuickStatsPanel(user),
          const SizedBox(height: 48),
          const Text('System Log', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 20),
          _buildMiniAuditLog(),
        ],
      ),
    );
  }

  Widget _buildUserPrimaryInfo(Map<String, dynamic> user, bool isActive, String onboardingStatus, bool isHoster) {
    final info = Map<String, dynamic>.from(user['info'] ?? {});
    final name = info['name']?.toString() ?? 'Unknown';
    final profileImage = info['profileImage'] ?? user['profileImage'];
    final rawRole = (user['role'] ?? user['permissions']?['role'])?.toString() ?? 'student';
    final role = _formatRole(rawRole);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _getRoleColor(role).withValues(alpha: 0.5), width: 3),
                  boxShadow: [BoxShadow(color: _getRoleColor(role).withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)],
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFF1E293B),
                  backgroundImage: profileImage != null ? CachedNetworkImageProvider(profileImage) : null,
                  child: profileImage == null ? Text(initial, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _getRoleColor(role))) : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: isActive ? Colors.green : Colors.red, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0F172A), width: 2)),
                child: Icon(isActive ? Icons.check : Icons.close, size: 12, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('ID: ${widget.userId.toString().toUpperCase()}', style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _darkBadge(role, _getRoleColor(role)),
            if (isHoster) _darkBadge(onboardingStatus.isEmpty ? 'Pending' : onboardingStatus, _statusColor(onboardingStatus)),
          ],
        ),
      ],
    );
  }

  Widget _darkBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildQuickStatsPanel(Map<String, dynamic> user) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.adminService.getUserPropertiesStream(widget.userId),
      builder: (context, propSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: widget.adminService.getUserBookingsStream(widget.userId),
          builder: (context, bookSnap) {
            final propCount = propSnap.data?.length ?? 0;
            final bookCount = bookSnap.data?.length ?? 0;

            return Column(
              children: [
                _insightRow('Total Properties', propCount.toString(), Icons.home_work_outlined, const Color(0xFF6366F1)),
                const SizedBox(height: 16),
                _insightRow('Total Bookings', bookCount.toString(), Icons.bookmark_outline_rounded, const Color(0xFFF59E0B)),
                const SizedBox(height: 16),
                _insightRow('Trust Score', '85%', Icons.shield_outlined, const Color(0xFF10B981)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _insightRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x0DFFFFFF))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMiniAuditLog() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.adminService.getUserAuditLogStream(widget.userId),
      builder: (context, snap) {
        final logs = snap.data?.take(5).toList() ?? [];
        if (logs.isEmpty) return const Text('No recent activity', style: TextStyle(color: Colors.white24, fontSize: 11));
        return Column(
          children: logs.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 4, height: 32, decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l['action']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'ACTION', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(_formatDate(l['timestamp'], withTime: false), style: const TextStyle(color: Colors.white38, fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildCompactHero(String name, String initial, dynamic profileImage, String role, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x0DFFFFFF)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: _getRoleColor(role).withValues(alpha: 0.1),
            backgroundImage: profileImage != null ? CachedNetworkImageProvider(profileImage) : null,
            child: profileImage == null ? Text(initial, style: TextStyle(color: _getRoleColor(role), fontWeight: FontWeight.bold)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _darkBadge(role, _getRoleColor(role)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF)))),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: const Color(0xFF475569),
        indicatorColor: const Color(0xFF6366F1),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Outfit'),
        tabs: const [
          Tab(text: 'OVERVIEW'),
          Tab(text: 'PROPERTIES'),
          Tab(text: 'BOOKINGS'),
          Tab(text: 'ACTIVITY LOG'),
        ],
        onTap: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildTabContent(
    Map<String, dynamic> user,
    Map<String, dynamic> info,
    Map<String, dynamic> permissions,
    Map<String, dynamic> verification,
    bool isActive,
    bool isHoster,
    String rawRole,
  ) {
    switch (_tabController.index) {
      case 1: return _buildPropertiesTab();
      case 2: return _buildBookingsTab();
      case 3: return _buildActivityTab();
      default: return _buildOverviewTab(user, info, permissions, verification, isActive, isHoster, rawRole);
    }
  }

  Widget _buildOverviewTab(Map<String, dynamic> user, Map<String, dynamic> info, Map<String, dynamic> permissions, Map<String, dynamic> verification, bool isActive, bool isHoster, String rawRole) {
    final studentInfo = Map<String, dynamic>.from(user['student_info'] ?? {});
    final hasStudentInfo = studentInfo.values.any((v) => v != null && v.toString().trim().isNotEmpty);

    return Column(
      children: [
        _buildSection(
          title: 'CONTACT INFORMATION',
          icon: Icons.contact_phone_outlined,
          expanded: _contactExpanded,
          onToggle: () => setState(() => _contactExpanded = !_contactExpanded),
          child: Column(
            children: [
              _detailRow(Icons.email_outlined, 'Email Address', info['email']?.toString() ?? 'No Email'),
              const Divider(height: 24, color: Color(0x0DFFFFFF)),
              _detailRow(Icons.phone_outlined, 'Phone Number', info['phone']?.toString() ?? info['phoneNumber']?.toString() ?? 'No Phone'),
              const Divider(height: 24, color: Color(0x0DFFFFFF)),
              _detailRow(Icons.location_city_outlined, 'City', info['city']?.toString() ?? 'Not provided'),
              const Divider(height: 24, color: Color(0x0DFFFFFF)),
              _detailRow(Icons.map_outlined, 'State', info['state']?.toString() ?? 'Not provided'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSection(
          title: 'ACCOUNT DETAILS',
          icon: Icons.manage_accounts_outlined,
          expanded: true,
          onToggle: null,
          child: Column(
            children: [
              _detailRow(Icons.fingerprint_outlined, 'User ID', widget.userId),
              const Divider(height: 24, color: Color(0x0DFFFFFF)),
              _detailRow(Icons.calendar_today_outlined, 'Joined On', _formatDate(user['createdAt'] ?? user['updatedAt'], withTime: false)),
              const Divider(height: 24, color: Color(0x0DFFFFFF)),
              _detailRow(Icons.update_outlined, 'Last Updated', _formatDate(user['updatedAt'], withTime: true)),
              const Divider(height: 24, color: Color(0x0DFFFFFF)),
              _detailRow(Icons.security_outlined, 'Account Status', isActive ? 'Active' : 'Deactivated'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (hasStudentInfo) ...[
          _buildSection(
            title: 'STUDENT INFORMATION',
            icon: Icons.school_outlined,
            expanded: _studentExpanded,
            onToggle: () => setState(() => _studentExpanded = !_studentExpanded),
            child: Column(
              children: [
                _detailRow(Icons.account_balance_outlined, 'College / University', studentInfo['college']?.toString() ?? 'Not provided'),
                const Divider(height: 24, color: Color(0x0DFFFFFF)),
                _detailRow(Icons.book_outlined, 'Course / Program', studentInfo['course']?.toString() ?? 'Not provided'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildVerificationDocumentsPanel(user, verification, rawRole),
        const SizedBox(height: 16),
        if (isHoster) _buildHosterOnboardingSection(),
      ],
    );
  }

  Widget _buildSection({required String title, required IconData icon, required bool expanded, required VoidCallback? onToggle, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0DFFFFFF)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: const Color(0xFF6366F1))),
                  const SizedBox(width: 16),
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.0))),
                  if (onToggle != null) Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: const Color(0xFF475569), size: 20),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: Color(0x0DFFFFFF)),
            Padding(padding: const EdgeInsets.all(20), child: child),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF475569)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHosterOnboardingSection() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: widget.adminService.getUserHosterRequestStream(widget.userId),
      builder: (context, hosterSnap) {
        final hReq = hosterSnap.data;
        return _buildSection(
          title: 'HOSTER ONBOARDING',
          icon: Icons.business_outlined,
          expanded: _hosterExpanded,
          onToggle: () => setState(() => _hosterExpanded = !_hosterExpanded),
          child: hReq == null
              ? const Text('No separate onboarding request found.', style: TextStyle(color: Colors.white38, fontSize: 12))
              : _buildHosterRequestDetails(hReq),
        );
      },
    );
  }

  Widget _buildHosterRequestDetails(Map<String, dynamic> req) {
    return Column(
      children: [
        _detailRow(Icons.business_outlined, 'Business Name', req['business_name']?.toString() ?? 'N/A'),
        const Divider(height: 24, color: Color(0x0DFFFFFF)),
        _detailRow(Icons.category_outlined, 'Category', req['category']?.toString() ?? 'N/A'),
        const Divider(height: 24, color: Color(0x0DFFFFFF)),
        _detailRow(Icons.verified_outlined, 'Approval Status', req['status']?.toString() ?? 'Pending'),
      ],
    );
  }

  Widget _buildPropertiesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.adminService.getUserPropertiesStream(widget.userId),
      builder: (context, snap) {
        final properties = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting && properties.isEmpty) return const Center(child: CircularProgressIndicator());
        if (properties.isEmpty) return _emptyState('No properties listed by this user');
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.4),
          itemCount: properties.length,
          itemBuilder: (_, i) => _buildPropertyCard(properties[i]),
        );
      },
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> p) {
    final status = p['status']?.toString() ?? 'pending';
    final name = p['name'] ?? 'Untitled Property';
    final location = p['location'] ?? 'No Address';
    final image = (p['images'] as List?)?.firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0DFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: image != null 
                  ? CachedNetworkImage(imageUrl: image, width: double.infinity, fit: BoxFit.cover)
                  : Container(color: Colors.white.withValues(alpha: 0.05), child: const Center(child: Icon(Icons.home_work_outlined, color: Colors.white24))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    _darkBadge(status, _statusColor(status)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(location, style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.adminService.getUserBookingsStream(widget.userId),
      builder: (context, snap) {
        final list = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting && list.isEmpty) return const Center(child: CircularProgressIndicator());
        if (list.isEmpty) return _emptyState('No bookings found for this user');
        
        return Column(
          children: list.map((b) => _buildBookingCard(b)).toList(),
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b) {
    final status = b['status']?.toString() ?? 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x0DFFFFFF))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.bookmark_outline, color: Color(0xFFF59E0B), size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b['propertyName'] ?? 'Unknown Property', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(_formatDate(b['createdAt']), style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          _darkBadge(status, _statusColor(status)),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return _buildMiniAuditLog();
  }

  Widget _buildVerificationDocumentsPanel(Map<String, dynamic> user, Map<String, dynamic> verif, String rawRole) {
    final isHosterRole = ['hoster', 'owner', 'manager', 'agency'].contains(rawRole.toLowerCase());

    return _buildSection(
      title: 'VERIFICATION DOCUMENTS',
      icon: Icons.verified_user_outlined,
      expanded: _verificationExpanded,
      onToggle: () => setState(() => _verificationExpanded = !_verificationExpanded),
      child: Column(
        children: [
          _adminDocCard(
            label: rawRole.toLowerCase().contains('student') ? 'Student ID' : 'Professional ID',
            icon: Icons.badge_outlined,
            frontUrl: verif['roleIdFrontUrl'],
            backUrl: verif['roleIdBackUrl'],
            isVerified: verif['roleIdVerified'] == true,
            status: verif['roleIdStatus']?.toString(),
            rejectReason: verif['roleIdRejectReason']?.toString(),
            fieldKey: 'roleId',
          ),
          const Divider(height: 32, color: Color(0x0DFFFFFF)),
          _adminDocCard(
            label: 'Aadhaar Card',
            icon: Icons.credit_card_outlined,
            frontUrl: verif['govIdFrontUrl'] ?? verif['aadhaarFrontUrl'],
            backUrl: verif['govIdBackUrl'] ?? verif['aadhaarBackUrl'],
            isVerified: verif['govIdVerified'] == true || verif['aadhaarVerified'] == true,
            status: verif['govIdStatus']?.toString() ?? verif['aadhaarStatus']?.toString(),
            rejectReason: verif['govIdRejectReason']?.toString() ?? verif['aadhaarRejectReason']?.toString(),
            fieldKey: 'govId',
          ),
          if (isHosterRole) ...[
            const Divider(height: 32, color: Color(0x0DFFFFFF)),
            _adminDocCard(
              label: 'PAN Card',
              icon: Icons.article_outlined,
              frontUrl: verif['panFrontUrl'] ?? verif['panUrl'],
              isVerified: verif['panVerified'] == true,
              status: verif['panStatus']?.toString(),
              rejectReason: verif['panRejectReason']?.toString(),
              fieldKey: 'pan',
            ),
          ],
        ],
      ),
    );
  }

  Widget _adminDocCard({
    required String label,
    required IconData icon,
    required String? frontUrl,
    String? backUrl,
    required bool isVerified,
    required String? status,
    String? rejectReason,
    required String fieldKey,
  }) {
    final statusColor = _statusColor(status ?? (frontUrl != null ? 'uploaded' : 'missing'));
    final statusText = isVerified ? 'Verified' : status?.toUpperCase() ?? (frontUrl != null ? 'UPLOADED' : 'MISSING');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white38, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
            _darkBadge(statusText, statusColor),
          ],
        ),
        if (rejectReason != null && rejectReason.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2))),
            child: Row(children: [const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 14), const SizedBox(width: 8), Expanded(child: Text('Reason: $rejectReason', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11)))]),
          ),
        ],
        if (frontUrl != null || backUrl != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (frontUrl != null) Expanded(child: _docThumb(frontUrl, 'Front')),
              if (frontUrl != null && backUrl != null) const SizedBox(width: 12),
              if (backUrl != null) Expanded(child: _docThumb(backUrl, 'Back')),
            ],
          ),
          if (!isVerified) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verifyDoc(fieldKey),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('APPROVE'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDocDialog(fieldKey),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('REJECT'),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444), side: const BorderSide(color: Color(0xFFEF4444)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _revokeDoc(fieldKey),
                icon: const Icon(Icons.undo_rounded, size: 14),
                label: const Text('REVOKE ACCESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: Colors.white24),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _docThumb(String url, String label) {
    return GestureDetector(
      onTap: () => _viewDocFullScreen(url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.white.withValues(alpha: 0.05), child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
              errorWidget: (_, __, ___) => Container(color: Colors.white.withValues(alpha: 0.05), child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white24))),
            ),
          ),
        ],
      ),
    );
  }

  void _viewDocFullScreen(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain)),
            IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32), onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.white10),
            const SizedBox(height: 16),
            Text(msg, style: const TextStyle(color: Colors.white24, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(bool isActive, Map<String, dynamic> user, Map<String, dynamic> permissions) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(color: Color(0xFF0F172A), border: Border(top: BorderSide(color: Color(0x0DFFFFFF)))),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showChangeRoleBottomSheet(context, (user['role'] ?? permissions['role'])?.toString().toLowerCase() ?? 'student'),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF6366F1)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('CHANGE ROLE', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleToggleStatus(isActive),
              style: ElevatedButton.styleFrom(backgroundColor: isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: Text(isActive ? 'DEACTIVATE ACCOUNT' : 'ACTIVATE ACCOUNT', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleBottomSheet(BuildContext context, String currentRole) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Change User Role', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ...[('student', 'Student', Icons.school_outlined), ('professional', 'Professional', Icons.business_center_outlined), ('hoster', 'Hoster', Icons.person_pin_outlined), ('owner', 'Owner', Icons.home_work_outlined)].map((r) => ListTile(
                leading: Icon(r.$3, color: currentRole == r.$1 ? const Color(0xFF6366F1) : Colors.white38),
                title: Text(r.$2, style: TextStyle(color: currentRole == r.$1 ? const Color(0xFF6366F1) : Colors.white70, fontWeight: FontWeight.bold)),
                onTap: () => _handleUpdateRole(r.$1),
                trailing: currentRole == r.$1 ? const Icon(Icons.check_circle, color: Color(0xFF6366F1)) : null,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _popupItem(IconData icon, String label, Color? color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color ?? Colors.white70, fontFamily: 'Outfit')),
      ],
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: const Color(0x1910B981), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x4D10B981))),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          const Text('Live', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

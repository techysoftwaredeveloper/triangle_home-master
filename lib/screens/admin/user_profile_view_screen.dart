import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:triangle_home/screens/admin/property_detail_screen.dart';

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
  bool _professionalExpanded = true;
  bool _emergencyExpanded = true;
  bool _bankExpanded = true;
  bool _housingPrefsExpanded = true;
  bool _hostPrefsExpanded = true;

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

  String _formatCurrency(dynamic amount) {
    final a = (amount as num?)?.toDouble() ?? 0;
    return '₹${NumberFormat('#,##0').format(a)}';
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

  Future<void> _handleBookingAction(String id, String action) async {
    setState(() => _isUpdating = true);
    try {
      if (action == 'confirm') {
        await widget.adminService.updateBookingStatus(id, 'confirmed');
      } else if (action == 'cancel') {
        await widget.adminService.updateBookingStatus(id, 'cancelled');
      } else if (action == 'checkout') {
        await widget.adminService.updateBookingStatus(id, 'checked_out');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking $action successfully'),
            backgroundColor: action == 'cancel' ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to perform $action: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleSuggestionAction(String id, String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance
          .collection('property_suggestions')
          .doc(id)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Suggestion status updated to $newStatus successfully'),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update suggestion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showBookingDetailsBottomSheet(Map<String, dynamic> b) {
    final status = b['status']?.toString() ?? 'pending';
    final statusColor = _statusColor(status);
    final bookingId = b['id']?.toString() ?? 'N/A';
    final amount = b['amount'] ?? b['price'];
    final propName = b['propertyName'] ?? b['name'] ?? 'Property #${b['propertyId']?.toString().substring(0, 6) ?? 'N/A'}';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Booking Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          fontFamily: 'Outfit',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status == 'confirmed'
                                ? Icons.check_circle_rounded
                                : status == 'pending'
                                    ? Icons.hourglass_top_rounded
                                    : Icons.cancel_rounded,
                            color: statusColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'PROPERTY DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _detailRow(Icons.business_outlined, 'Property Name', propName),
                        const Divider(height: 24, color: Color(0xFFE2E8F0)),
                        _detailRow(Icons.tag, 'Booking ID', bookingId.toUpperCase()),
                        const Divider(height: 24, color: Color(0xFFE2E8F0)),
                        _detailRow(Icons.calendar_today_outlined, 'Check-In Date', _formatDate(b['checkIn'] ?? b['startDate'])),
                        const Divider(height: 24, color: Color(0xFFE2E8F0)),
                        _detailRow(Icons.calendar_month_outlined, 'Check-Out Date', _formatDate(b['checkOut'] ?? b['endDate'])),
                        const Divider(height: 24, color: Color(0xFFE2E8F0)),
                        _detailRow(Icons.currency_rupee, 'Total Amount Paid', _formatCurrency(amount)),
                        if (b['sharingType'] != null || b['roomType'] != null) ...[
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _detailRow(Icons.people_outline, 'Room Sharing Type', b['sharingType']?.toString() ?? b['roomType']?.toString() ?? 'N/A'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'GUEST INFORMATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _detailRow(Icons.person_outline, 'Guest Name', b['guestName']?.toString() ?? 'N/A'),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        _detailRow(Icons.email_outlined, 'Guest Email', b['guestEmail']?.toString() ?? 'N/A'),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        _detailRow(Icons.phone_outlined, 'Guest Phone', b['guestPhone']?.toString() ?? 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (b['hosterName'] != null) ...[
                    const Text(
                      'HOST INFORMATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _detailRow(Icons.person_pin_outlined, 'Host Name', b['hosterName']?.toString() ?? 'N/A'),
                          if (b['hosterPhone'] != null) ...[
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),
                            _detailRow(Icons.phone_outlined, 'Host Phone', b['hosterPhone']?.toString() ?? 'N/A'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (status == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _handleBookingAction(bookingId, 'confirm');
                            },
                            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                            label: const Text('Confirm Booking', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _handleBookingAction(bookingId, 'cancel');
                            },
                            icon: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
                            label: const Text('Cancel Booking', style: TextStyle(color: Color(0xFFDC2626))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFDC2626)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (status == 'confirmed') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _handleBookingAction(bookingId, 'checkout');
                        },
                        icon: const Icon(Icons.logout_rounded, color: Colors.white),
                        label: const Text('Check Out Guest', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSuggestionDetailsBottomSheet(Map<String, dynamic> s) {
    final status = s['status']?.toString() ?? 'pending';
    final statusColor = _statusColor(status);
    final id = s['id']?.toString() ?? '';
    final businessName = s['business_name'] ?? s['name'] ?? 'Untitled Suggestion';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Suggestion Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          fontFamily: 'Outfit',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'PROPERTY DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _detailRow(Icons.business_outlined, 'Property Name', businessName),
                        const Divider(height: 24, color: Color(0xFFE2E8F0)),
                        _detailRow(Icons.location_on_outlined, 'Address', s['business_address']?.toString() ?? s['location']?.toString() ?? 'N/A'),
                        const Divider(height: 24, color: Color(0xFFE2E8F0)),
                        _detailRow(Icons.category_outlined, 'Category', s['category']?.toString() ?? 'N/A'),
                        if (s['monthly_rent'] != null && s['monthly_rent'].toString().isNotEmpty) ...[
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _detailRow(Icons.payments_rounded, 'Monthly Rent', '₹${s['monthly_rent']}'),
                        ],
                        if (s['deposit'] != null && s['deposit'].toString().isNotEmpty) ...[
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _detailRow(Icons.security_rounded, 'Security Deposit', '₹${s['deposit']}'),
                        ],
                        if (s['amenities'] != null && s['amenities'].toString().isNotEmpty) ...[
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _detailRow(Icons.settings_input_component_rounded, 'Amenities', s['amenities']?.toString() ?? 'N/A'),
                        ],
                        if (s['ambiance'] != null && s['ambiance'].toString().isNotEmpty) ...[
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _detailRow(Icons.mood_rounded, 'Ambiance', s['ambiance']?.toString() ?? 'N/A'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SUGGESTED BY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _detailRow(Icons.person_outline, 'Name', s['suggester_name']?.toString() ?? 'N/A'),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        _detailRow(Icons.email_outlined, 'Email', s['suggester_email']?.toString() ?? 'N/A'),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        _detailRow(Icons.phone_outlined, 'Phone', s['suggester_phone']?.toString() ?? 'N/A'),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        _detailRow(Icons.home_rounded, 'Is staying here?', s['is_staying_here'] == true ? 'Yes' : 'No'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (s['owner_name'] != null && s['owner_name'].toString().isNotEmpty) ...[
                    const Text(
                      'OWNER DETAILS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _detailRow(Icons.person_outline, 'Owner Name', s['owner_name']?.toString() ?? 'N/A'),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _detailRow(Icons.phone_outlined, 'Owner Phone', s['owner_phone']?.toString() ?? 'N/A'),
                          if (s['owner_email'] != null && s['owner_email'].toString().isNotEmpty) ...[
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),
                            _detailRow(Icons.email_outlined, 'Owner Email', s['owner_email']?.toString() ?? 'N/A'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (status == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _handleSuggestionAction(id, 'approved');
                            },
                            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                            label: const Text('Approve Suggestion', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _handleSuggestionAction(id, 'rejected');
                            },
                            icon: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
                            label: const Text('Reject Suggestion', style: TextStyle(color: Color(0xFFDC2626))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFDC2626)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
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
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('User Not Found'),
              leading: BackButton(onPressed: () => Navigator.pop(context)),
            ),
            body: const Center(child: Text('User data not available.')),
          );
        }

        final info = Map<String, dynamic>.from(user['info'] ?? {});
        final permissions = Map<String, dynamic>.from(user['permissions'] ?? {});
        final verification = Map<String, dynamic>.from(user['verification'] ?? {});
        final rawRole =
            (user['role'] ?? permissions['role'])?.toString() ?? 'student';
        final role = _formatRole(rawRole);
        final isActive = user['is_active'] as bool? ?? true;
        final name = info['name']?.toString() ?? 'Unknown User';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        final profileImage = info['profileImage'] ?? user['profileImage'];
        final onboardingStatus = (user['status'] ??
                user['accountStatus'] ??
                permissions['status'] ??
                '')
            .toString();
        final isHoster = ['hoster', 'owner', 'manager', 'agency']
            .contains(rawRole.toLowerCase());

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontFamily: 'Outfit',
                fontSize: 17,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1E293B), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                onSelected: (v) {
                  if (v == 'role') {
                    _showChangeRoleBottomSheet(context, rawRole.toLowerCase());
                  } else if (v == 'toggle') {
                    _handleToggleStatus(isActive);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'role',
                    child: _popupItem(Icons.manage_accounts_outlined,
                        'Change Role', null),
                  ),
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
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    // ─── Hero Header Card ───
                    _buildHeroCard(name, initial, profileImage, role, rawRole,
                        isActive, onboardingStatus, isHoster, user, permissions),

                    const SizedBox(height: 8),

          _buildTabBar(),
          _buildTabContent(
            user,
            info,
            permissions,
            verification,
            isActive,
            isHoster,
            rawRole,
          ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
              if (_isUpdating)
                Container(
                  color: Colors.white.withValues(alpha: 0.6),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
          bottomNavigationBar: _buildBottomActions(isActive, user, permissions),
        );
      },
    );
  }

  // ─────────────────── Hero Header ───────────────────

  Widget _buildHeroCard(
    String name, String initial, dynamic profileImage,
    String role, String rawRole, bool isActive, String onboardingStatus,
    bool isHoster, Map<String, dynamic> user, Map<String, dynamic> permissions,
  ) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _getRoleColor(role).withValues(alpha: 0.2),
                  _getRoleColor(role).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                  color: _getRoleColor(role).withValues(alpha: 0.3), width: 3),
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.transparent,
              child: profileImage != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profileImage,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const CircularProgressIndicator(strokeWidth: 2),
                        errorWidget: (_, __, ___) => Text(initial,
                            style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: _getRoleColor(role))),
                      ),
                    )
                  : Text(initial,
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _getRoleColor(role))),
            ),
          ),
          const SizedBox(height: 12),
          Text(name,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  fontFamily: 'Outfit')),
          const SizedBox(height: 4),
          Text(
            widget.userId.length > 16
                ? widget.userId.substring(0, 16).toUpperCase()
                : widget.userId.toUpperCase(),
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 1.2),
          ),
          const SizedBox(height: 14),
          // Badges row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _badge(role, _getRoleColor(role)),
              if (isHoster)
                _badge(
                  onboardingStatus.isEmpty ? 'Pending' : onboardingStatus,
                  _statusColor(onboardingStatus),
                ),
              _badge(
                isActive ? 'Active' : 'Inactive',
                isActive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick stats row
          _buildQuickStats(user),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> user) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.adminService
          .getUserPropertiesStream(widget.userId),
      builder: (context, propSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: widget.adminService
              .getUserBookingsStream(widget.userId),
          builder: (context, bookSnap) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.adminService
                  .getHosterReceivedBookingsStream(widget.userId),
              builder: (context, hostBookSnap) {
                final propCount = propSnap.data?.length ?? 0;
                final bookCount = bookSnap.data?.length ?? 0;
                final receivedCount = hostBookSnap.data?.length ?? 0;

                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _quickStat('Properties', propCount.toString(),
                          Icons.home_work_outlined, const Color(0xFF2563EB)),
                      _dividerV(),
                      _quickStat('My Bookings', bookCount.toString(),
                          Icons.calendar_month_outlined, const Color(0xFF7C3AED)),
                      _dividerV(),
                      _quickStat('Received', receivedCount.toString(),
                          Icons.person_pin_outlined, const Color(0xFFD97706)),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _dividerV() => Container(
      width: 1, height: 40, color: const Color(0xFFE2E8F0));

  Widget _quickStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Outfit')),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ─────────────────── Tab Bar ───────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: const Color(0xFF94A3B8),
        indicatorColor: const Color(0xFF2563EB),
        indicatorWeight: 3,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            fontFamily: 'Outfit'),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Properties'),
          Tab(text: 'Bookings'),
          Tab(text: 'Activity'),
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
      case 1:
        return _buildPropertiesTab();
      case 2:
        return _buildBookingsTab();
      case 3:
        return _buildActivityTab();
      default:
        return _buildOverviewTab(
            user, info, permissions, verification, isActive, isHoster, rawRole);
    }
  }

  // ─────────────────── OVERVIEW TAB ───────────────────

  Widget _buildOverviewTab(
    Map<String, dynamic> user,
    Map<String, dynamic> info,
    Map<String, dynamic> permissions,
    Map<String, dynamic> verification,
    bool isActive,
    bool isHoster,
    String rawRole,
  ) {
    final studentInfo = Map<String, dynamic>.from(user['student_info'] ?? {});
    final hasStudentInfo = studentInfo.values.any((v) => v != null && v.toString().trim().isNotEmpty);

    final professionalInfo = Map<String, dynamic>.from(user['professional_info'] ?? {});
    final hasProfessionalInfo = professionalInfo.values.any((v) => v != null && v.toString().trim().isNotEmpty);

    final emergencyContact = Map<String, dynamic>.from(user['emergency_contact'] ?? {});
    final hasEmergencyContact = emergencyContact.values.any((v) => v != null && v.toString().trim().isNotEmpty);

    final bankInfo = Map<String, dynamic>.from(user['bank_info'] ?? {});
    final bankName = bankInfo['bankName']?.toString() ?? user['bankName']?.toString() ?? '';
    final bankAccount = bankInfo['accountNumber']?.toString() ?? bankInfo['bankAccountNo']?.toString() ?? user['bankAccNo']?.toString() ?? '';
    final bankIfsc = bankInfo['ifsc']?.toString() ?? bankInfo['bankIfsc']?.toString() ?? user['bankIfsc']?.toString() ?? '';
    final bankVerified = bankInfo['verified'] == true || bankInfo['bankVerified'] == true || user['bankVerified'] == true;
    final hasBankInfo = bankName.isNotEmpty || bankAccount.isNotEmpty || bankIfsc.isNotEmpty;

    final housingPrefs = Map<String, dynamic>.from(user['housing_preferences'] ?? {});
    final hasHousingPrefs = housingPrefs.values.any((v) => v != null && v.toString().trim().isNotEmpty);

    final prefCity = housingPrefs['preferredCity']?.toString() ?? 'Not provided';
    final budgetMin = housingPrefs['budgetMin'];
    final budgetMax = housingPrefs['budgetMax'];
    final budgetStr = (budgetMin != null && budgetMax != null)
        ? '₹$budgetMin - ₹$budgetMax'
        : 'Not provided';
    final lookingForVal = housingPrefs['lookingFor'];
    final lookingForStr = lookingForVal is List
        ? lookingForVal.join(', ')
        : lookingForVal?.toString() ?? 'Not provided';
    final moveInVal = housingPrefs['moveInDate'];
    final moveInDateStr = _formatDate(moveInVal);
    final stayDuration = housingPrefs['stayDuration']?.toString() ?? 'Not provided';
    final familySize = housingPrefs['familySize']?.toString() ?? 'Not provided';

    final hostPrefs = Map<String, dynamic>.from(user['host_preferences'] ?? {});
    final hasHostPrefs = hostPrefs.values.any((v) => v != null && v.toString().trim().isNotEmpty);

    final bookingType = hostPrefs['bookingType'] ?? 'Approval Required';
    final prefTenantsVal = hostPrefs['tenantTypes'] ?? hostPrefs['preferredTenants'];
    final prefTenantsStr = prefTenantsVal is List
        ? prefTenantsVal.join(', ')
        : prefTenantsVal?.toString() ?? 'Students, Professionals';
    final prefGender = hostPrefs['genderPreference'] ?? hostPrefs['preferredGender'] ?? 'Any';
    final prefDuration = hostPrefs['durationPreference'] ?? hostPrefs['preferredDuration'] ?? 'Long Term';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Contact Info
          _buildSection(
            title: 'CONTACT INFORMATION',
            icon: Icons.contact_phone_outlined,
            expanded: _contactExpanded,
            onToggle: () =>
                setState(() => _contactExpanded = !_contactExpanded),
            child: Column(
              children: [
                _detailRow(Icons.email_outlined, 'Email Address',
                    info['email']?.toString() ?? 'No Email'),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _detailRow(Icons.phone_outlined, 'Phone Number',
                    info['phone']?.toString() ??
                        info['phoneNumber']?.toString() ??
                        'No Phone'),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _detailRow(Icons.location_city_outlined, 'City',
                    info['city']?.toString() ?? 'Not provided'),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _detailRow(Icons.map_outlined, 'State',
                    info['state']?.toString() ?? 'Not provided'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Account Details
          _buildSection(
            title: 'ACCOUNT DETAILS',
            icon: Icons.manage_accounts_outlined,
            expanded: true,
            onToggle: null,
            child: Column(
              children: [
                _detailRow(Icons.fingerprint_outlined, 'User ID',
                    widget.userId),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _detailRow(Icons.calendar_today_outlined, 'Joined On',
                    _formatDate(
                        user['createdAt'] ?? user['updatedAt'],
                        withTime: false)),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _detailRow(Icons.update_outlined, 'Last Updated',
                    _formatDate(user['updatedAt'], withTime: true)),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _detailRow(Icons.security_outlined, 'Account Status',
                    isActive ? 'Active' : 'Deactivated'),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _detailRow(Icons.badge_outlined, 'User Type',
                    _formatRole(rawRole)),
                if (info['dob'] != null) ...[
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.cake_outlined, 'Date of Birth',
                      _formatDate(info['dob'])),
                ],
                if (info['gender'] != null) ...[
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.person_outline, 'Gender',
                      info['gender']?.toString() ?? ''),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Student Info
          if ((rawRole.toLowerCase() == 'student' || rawRole.toLowerCase() == 'user' || rawRole.isEmpty) && hasStudentInfo) ...[
            _buildSection(
              title: 'STUDENT INFORMATION',
              icon: Icons.school_outlined,
              expanded: _studentExpanded,
              onToggle: () => setState(() => _studentExpanded = !_studentExpanded),
              child: Column(
                children: [
                  _detailRow(Icons.account_balance_outlined, 'College / University', studentInfo['college']?.toString() ?? 'Not provided'),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.book_outlined, 'Course / Program', studentInfo['course']?.toString() ?? 'Not provided'),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.timeline_outlined, 'Semester / Year', studentInfo['semester']?.toString() ?? 'Not provided'),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.badge_outlined, 'Student ID', studentInfo['studentId']?.toString() ?? 'Not provided'),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Professional Info
          if (rawRole.toLowerCase() == 'professional' && hasProfessionalInfo) ...[
            _buildSection(
              title: 'PROFESSIONAL INFORMATION',
              icon: Icons.business_center_outlined,
              expanded: _professionalExpanded,
              onToggle: () => setState(() => _professionalExpanded = !_professionalExpanded),
              child: Column(
                children: [
                  _detailRow(Icons.business_outlined, 'Company Name', professionalInfo['companyName']?.toString() ?? 'Not provided'),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.badge_outlined, 'Designation / Job Title', professionalInfo['jobTitle']?.toString() ?? 'Not provided'),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.work_outline, 'Work Location', professionalInfo['workLocation']?.toString() ?? 'Not provided'),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.badge_outlined, 'Employee ID', professionalInfo['employeeId']?.toString() ?? 'Not provided'),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.star_outline_rounded, 'Experience', professionalInfo['experience']?.toString() ?? 'Not provided'),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Emergency Contact
          if (hasEmergencyContact) ...[
            _buildSection(
              title: 'EMERGENCY CONTACT',
              icon: Icons.contacts_outlined,
              expanded: _emergencyExpanded,
              onToggle: () => setState(() => _emergencyExpanded = !_emergencyExpanded),
              child: Column(
                children: [
                  _detailRow(Icons.person_outline, 'Contact Person', emergencyContact['name']?.toString() ?? 'Not provided'),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.people_outline, 'Relationship', emergencyContact['relationship']?.toString() ?? emergencyContact['relation']?.toString() ?? 'Not provided'),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.phone_outlined, 'Phone Number', emergencyContact['phone']?.toString() ?? 'Not provided'),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Bank & Payout Details
          if (hasBankInfo) ...[
            _buildSection(
              title: 'BANK & PAYOUT DETAILS',
              icon: Icons.account_balance_outlined,
              expanded: _bankExpanded,
              onToggle: () => setState(() => _bankExpanded = !_bankExpanded),
              child: Column(
                children: [
                  _detailRow(Icons.account_balance_outlined, 'Bank Name', bankName.isNotEmpty ? bankName : 'Not provided'),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.credit_card_outlined, 'Account Number', bankAccount.isNotEmpty ? bankAccount : 'Not provided'),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.code_rounded, 'IFSC Code', bankIfsc.isNotEmpty ? bankIfsc : 'Not provided'),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(
                    Icons.verified_outlined,
                    'Verification Status',
                    bankVerified ? 'Verified' : 'Pending Verification',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Housing Preferences
          if (hasHousingPrefs) ...[
            _buildSection(
              title: 'HOUSING PREFERENCES',
              icon: Icons.tune_outlined,
              expanded: _housingPrefsExpanded,
              onToggle: () => setState(() => _housingPrefsExpanded = !_housingPrefsExpanded),
              child: Column(
                children: [
                  _detailRow(Icons.location_city_outlined, 'Preferred City', prefCity),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.currency_rupee, 'Monthly Budget Range', budgetStr),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.home_outlined, 'Looking For', lookingForStr),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.calendar_month_outlined, 'Preferred Move-in Date', moveInDateStr),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.schedule_outlined, 'Preferred Stay Duration', stayDuration),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.people_outline, 'Family Size / Sharing', familySize),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Hosting Preferences
          if (isHoster && hasHostPrefs) ...[
            _buildSection(
              title: 'HOSTING PREFERENCES',
              icon: Icons.home_work_outlined,
              expanded: _hostPrefsExpanded,
              onToggle: () => setState(() => _hostPrefsExpanded = !_hostPrefsExpanded),
              child: Column(
                children: [
                  _detailRow(Icons.bookmark_outline_rounded, 'Booking Flow Type', bookingType),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.people_outline, 'Preferred Tenant Types', prefTenantsStr),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.wc_outlined, 'Preferred Gender', prefGender),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _detailRow(Icons.schedule_outlined, 'Preferred Duration', prefDuration),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Verification Documents — full admin panel
          _buildVerificationDocumentsPanel(user, verification, rawRole),

          const SizedBox(height: 12),

          // Hoster Request Details
          if (isHoster)
            StreamBuilder<Map<String, dynamic>?>(
              stream: widget.adminService
                  .getUserHosterRequestStream(widget.userId),
              builder: (context, hosterSnap) {
                final hReq = hosterSnap.data;
                return _buildSection(
                  title: 'HOSTER ONBOARDING',
                  icon: Icons.business_outlined,
                  expanded: _hosterExpanded,
                  onToggle: () =>
                      setState(() => _hosterExpanded = !_hosterExpanded),
                  child: hReq == null
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(
                                  hosterSnap.connectionState ==
                                          ConnectionState.waiting
                                      ? Icons.hourglass_top_outlined
                                      : Icons.info_outline,
                                  color: const Color(0xFF94A3B8),
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                hosterSnap.connectionState ==
                                        ConnectionState.waiting
                                    ? 'Loading hoster request...'
                                    : 'No separate hoster_requests doc found.\nDetails are stored in the main user document.',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        )
                      : _buildHosterRequestDetails(hReq),
                );
              },
            ),

          if (isHoster) const SizedBox(height: 12),

          // Suggestions (from property_suggestions)
          _buildSection(
            title: 'PROPERTY SUGGESTIONS',
            icon: Icons.lightbulb_outlined,
            expanded: true,
            onToggle: null,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.adminService
                  .getUserSuggestionsStream(widget.userId),
              builder: (context, suggSnap) {
                final suggestions = suggSnap.data ?? [];
                if (suggestions.isEmpty) {
                  return _emptyState('No property suggestions submitted yet');
                }
                return Column(
                  children: suggestions
                      .map((s) => _buildSuggestionCard(s))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHosterRequestDetails(Map<String, dynamic> req) {
    final hReqInfo = Map<String, dynamic>.from(req['info'] ?? {});
    final docs = Map<String, dynamic>.from(req['documents'] ?? {});
    final verif = Map<String, dynamic>.from(req['verification'] ?? {});

    return Column(
      children: [
        _detailRow(Icons.business_outlined, 'Business Name',
            req['business_name']?.toString() ??
                hReqInfo['businessName']?.toString() ??
                'N/A'),
        const Divider(height: 24, color: Color(0xFFF1F5F9)),
        _detailRow(Icons.category_outlined, 'Category',
            req['category']?.toString() ?? 'N/A'),
        const Divider(height: 24, color: Color(0xFFF1F5F9)),
        _detailRow(Icons.location_city_outlined, 'Location',
            '${req['city'] ?? hReqInfo['city'] ?? ''}, ${req['state'] ?? hReqInfo['state'] ?? ''}'
                .trim()
                .replaceAll(RegExp(r'^,\s*|,\s*$'), '')),
        const Divider(height: 24, color: Color(0xFFF1F5F9)),
        _detailRow(Icons.schedule_outlined, 'Submitted On',
            _formatDate(req['createdAt'] ?? req['submittedAt'])),
        const Divider(height: 24, color: Color(0xFFF1F5F9)),
        _detailRow(Icons.verified_outlined, 'Approval Status',
            req['status']?.toString() ?? 'Pending'),
        if (req['rejectionReason'] != null) ...[
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _detailRow(Icons.info_outline, 'Rejection Reason',
              req['rejectionReason'].toString()),
        ],
        if (docs.isNotEmpty || verif.isNotEmpty) ...[
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          const Text('DOCUMENTS',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),
          ...['aadhaarUrl', 'panUrl', 'ownershipUrl', 'utilityUrl']
              .where((k) =>
                  docs[k] != null ||
                  verif[k] != null ||
                  req[k] != null)
              .map((k) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _docLabel(k),
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        _docStatusBadge(
                            docs[k] ?? verif[k] ?? req[k] != null),
                      ],
                    ),
                  )),
        ],
      ],
    );
  }

  String _docLabel(String key) {
    switch (key) {
      case 'aadhaarUrl': return 'Aadhaar Card';
      case 'panUrl': return 'PAN Card';
      case 'ownershipUrl': return 'Property Ownership Proof';
      case 'utilityUrl': return 'Utility Bill';
      default: return key.replaceAll('Url', '').replaceAll('_', ' ');
    }
  }

  Widget _docStatusBadge(bool uploaded) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: uploaded
            ? const Color(0xFFECFDF5)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        uploaded ? 'Uploaded' : 'Missing',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: uploaded
              ? const Color(0xFF16A34A)
              : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  // ─────────────────── PROPERTIES TAB ───────────────────

  Widget _buildPropertiesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.adminService.getUserPropertiesStream(widget.userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator()));
        }
        final properties = snap.data ?? [];
        if (properties.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _emptyState('No properties listed by this user'),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: properties.length,
          itemBuilder: (_, i) => _buildPropertyCard(properties[i]),
        );
      },
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> p) {
    final status = p['status']?.toString() ?? 'pending';
    final statusColor = _statusColor(status);

    // Resolve actual Firestore field names (multiple naming conventions in use)
    final basicInfo = Map<String, dynamic>.from(p['basicInfo'] as Map? ?? {});

    // Property name: basicInfo.collegeName > name > title > Untitled
    final propName = basicInfo['collegeName']?.toString().isNotEmpty == true
        ? basicInfo['collegeName'].toString()
        : (p['name'] ?? p['title'] ?? 'Untitled Property').toString();

    // Image: images[0] > propertyImage > null
    final imagesList = p['images'] as List?;
    final imageUrl = (imagesList?.isNotEmpty == true)
        ? imagesList!.first?.toString()
        : p['propertyImage']?.toString();

    // Location: locality + city > location > address
    final city = p['city']?.toString() ?? '';
    final locality = p['locality']?.toString() ?? '';
    final location = (locality.isNotEmpty && city.isNotEmpty)
        ? '$locality, $city'
        : (locality.isNotEmpty ? locality : city.isNotEmpty ? city : null) ??
            p['location']?.toString() ??
            p['address']?.toString() ??
            'No location';

    // Price: monthlyRent > price
    final rawRent = p['monthlyRent']?.toString().replaceAll(',', '') ??
        p['price']?.toString() ??
        '0';
    final rent = int.tryParse(rawRent) ?? 0;

    // Sharing / rooms from basicInfo
    final sharing = basicInfo['sharing']?.toString() ??
        p['sharing']?.toString() ??
        'N/A';
    final rooms = p['rooms']?.toString() ??
        basicInfo['totalRooms']?.toString() ??
        '—';

    // Property type
    final propType = p['propertyType']?.toString() ??
        basicInfo['propertyType']?.toString() ??
        p['category']?.toString() ??
        'Property';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDetailScreen(
                property: p,
                adminService: widget.adminService,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Image header
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _propertyPlaceholder(),
                  )
                : _propertyPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        propName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            fontFamily: 'Outfit'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _badge(status, statusColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(propType,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (rooms != '—')
                      _propChip(Icons.king_bed_outlined, '$rooms Rooms'),
                    _propChip(Icons.people_outline, sharing),
                    if (rent > 0)
                      _propChip(Icons.currency_rupee,
                          _formatCurrency(rent)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule_outlined,
                        size: 11, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      'Listed: ${_formatDate(p['createdAt'])}',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _propertyPlaceholder() => Container(
        height: 140,
        width: double.infinity,
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.home_work_outlined,
            color: Color(0xFFCBD5E1), size: 48),
      );

  Widget _propChip(IconData icon, String label) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  // ─────────────────── BOOKINGS TAB ───────────────────

  Widget _buildBookingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // As tenant
          _buildSectionTitle2('BOOKINGS AS TENANT'),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream:
                widget.adminService.getUserBookingsStream(widget.userId),
            builder: (context, snap) {
              final list = snap.data ?? [];
              if (snap.connectionState == ConnectionState.waiting &&
                  list.isEmpty) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator()));
              }
              if (list.isEmpty) {
                return _emptyState('No bookings made as tenant');
              }
              return Column(
                  children: list
                      .map((b) => _buildBookingCard(b, isTenant: true))
                      .toList());
            },
          ),
          const SizedBox(height: 20),
          // As hoster
          _buildSectionTitle2('BOOKINGS RECEIVED (AS HOST)'),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.adminService
                .getHosterReceivedBookingsStream(widget.userId),
            builder: (context, snap) {
              final list = snap.data ?? [];
              if (snap.connectionState == ConnectionState.waiting &&
                  list.isEmpty) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator()));
              }
              if (list.isEmpty) {
                return _emptyState('No bookings received as hoster');
              }
              return Column(
                  children: list
                      .map((b) => _buildBookingCard(b, isTenant: false))
                      .toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b,
      {required bool isTenant}) {
    final status = b['status']?.toString() ?? 'pending';
    final statusColor = _statusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: InkWell(
        onTap: () => _showBookingDetailsBottomSheet(b),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  b['propertyName']?.toString() ??
                      b['name']?.toString() ??
                      'Property #${b['propertyId']?.toString().substring(0, 6) ?? 'N/A'}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _badge(status, statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _bookingInfoChip(Icons.tag,
                  b['id']?.toString().substring(0, 8).toUpperCase() ??
                      'N/A'),
              const SizedBox(width: 8),
              _bookingInfoChip(Icons.currency_rupee,
                  _formatCurrency(b['amount'] ?? b['price'])),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                'Check-in: ${_formatDate(b['checkIn'] ?? b['startDate'])}',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              Text(
                'Check-out: ${_formatDate(b['checkOut'] ?? b['endDate'])}',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Booked: ${_formatDate(b['createdAt'], withTime: false)}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    ),
  ),
);
}


  Widget _bookingInfoChip(IconData icon, String label) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  // ─────────────────── ACTIVITY TAB ───────────────────

  Widget _buildActivityTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Suggestions
          _buildSectionTitle2('PROPERTY SUGGESTIONS'),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.adminService
                .getUserSuggestionsStream(widget.userId),
            builder: (context, suggSnap) {
              final suggestions = suggSnap.data ?? [];
              if (suggestions.isEmpty) {
                return _emptyState('No property suggestions submitted');
              }
              return Column(
                children: suggestions
                    .map((s) => _buildSuggestionCard(s))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // Admin Audit Log
          _buildSectionTitle2('ADMIN AUDIT LOG'),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.adminService
                .getUserAuditLogStream(widget.userId),
            builder: (context, logSnap) {
              final logs = logSnap.data ?? [];
              if (logSnap.connectionState == ConnectionState.waiting &&
                  logs.isEmpty) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator()));
              }
              if (logs.isEmpty) {
                return _emptyState('No admin actions recorded for this user');
              }
              return Column(
                children: logs.map((l) => _buildAuditCard(l)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuditCard(Map<String, dynamic> log) {
    final action =
        log['action']?.toString() ?? log['title']?.toString() ?? 'Action';
    final reason =
        log['reason']?.toString() ?? log['description']?.toString() ?? '';
    final time =
        log['timestamp'] ?? log['createdAt'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history_edu_outlined,
                size: 18, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((w) =>
                          w.isNotEmpty
                              ? w[0].toUpperCase() + w.substring(1)
                              : w)
                      .join(' '),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)),
                ),
                if (reason.isNotEmpty)
                  Text(reason,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(_formatDate(time, withTime: false),
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  // ─────────────────── Shared Components ───────────────────

  Widget _buildSection({
    required String title,
    required IconData icon,
    required bool expanded,
    required VoidCallback? onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8)),
                  ),
                  if (onToggle != null)
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────── Verification Documents Panel ───────────────────

  Widget _buildVerificationDocumentsPanel(
      Map<String, dynamic> user, Map<String, dynamic> verif, String rawRole) {
    final emailVerified = user['emailVerified'] == true ||
        verif['emailVerified'] == true;
    final phoneVerified = verif['phoneVerified'] == true;
    final isHosterRole = ['hoster', 'owner', 'manager', 'agency']
        .contains(rawRole.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contact Verification Chips
        _buildSection(
          title: 'CONTACT VERIFICATION',
          icon: Icons.contacts_outlined,
          expanded: true,
          onToggle: null,
          child: Row(
            children: [
              Expanded(
                child: _contactVerifChip(
                  Icons.email_outlined,
                  'Email',
                  emailVerified,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _contactVerifChip(
                  Icons.phone_outlined,
                  'Phone',
                  phoneVerified,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Documents
        _buildSection(
          title: 'VERIFICATION DOCUMENTS',
          icon: Icons.verified_user_outlined,
          expanded: _verificationExpanded,
          onToggle: () =>
              setState(() => _verificationExpanded = !_verificationExpanded),
          child: Column(
            children: [
              // Identity Document (Student/Professional ID)
              _adminDocCard(
                label: rawRole.toLowerCase().contains('student') 
                    ? 'Student ID' 
                    : 'Professional ID',
                icon: Icons.school_outlined,
                iconColor: const Color(0xFF8B5CF6),
                frontUrl: verif['roleIdFrontUrl'],
                backUrl: verif['roleIdBackUrl'],
                isVerified: verif['roleIdVerified'] == true,
                status: verif['roleIdStatus']?.toString(),
                rejectReason: verif['roleIdRejectReason']?.toString(),
                fieldKey: 'roleId',
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Address Verification
              _adminDocCard(
                label: 'Address Proof',
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFF10B981),
                frontUrl: verif['addressFrontUrl'],
                backUrl: verif['addressBackUrl'],
                isVerified: verif['addressVerified'] == true,
                status: verif['addressStatus']?.toString(),
                rejectReason: verif['addressRejectReason']?.toString(),
                fieldKey: 'address',
                subtitle: verif['addressType']?.toString(),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Selfie Verification
              _adminDocCard(
                label: 'Selfie Verification',
                icon: Icons.face_retouching_natural,
                iconColor: const Color(0xFFEC4899),
                frontUrl: verif['selfieUrl'],
                backUrl: null,
                isVerified: verif['selfieVerified'] == true,
                status: verif['selfieStatus']?.toString(),
                rejectReason: verif['selfieRejectReason']?.toString(),
                fieldKey: 'selfie',
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Government ID (Aadhaar)
              _adminDocCard(
                label: 'Aadhaar Card',
                icon: Icons.credit_card_rounded,
                iconColor: const Color(0xFF0EA5E9),
                frontUrl: verif['govIdFrontUrl'] ?? verif['aadhaarFrontUrl'],
                backUrl: verif['govIdBackUrl'] ?? verif['aadhaarBackUrl'],
                isVerified: verif['govIdVerified'] == true ||
                    verif['aadhaarVerified'] == true,
                status: verif['govIdStatus']?.toString() ??
                    verif['aadhaarStatus']?.toString(),
                rejectReason: verif['govIdRejectReason']?.toString(),
                fieldKey: 'govId',
              ),
              
              if (isHosterRole) ...[
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _adminDocCard(
                  label: 'PAN Card',
                  icon: Icons.article_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  frontUrl: verif['panFrontUrl'] ?? verif['panUrl'],
                  backUrl: null,
                  isVerified: verif['panVerified'] == true,
                  status: verif['panStatus']?.toString(),
                  rejectReason: verif['panRejectReason']?.toString(),
                  fieldKey: 'pan',
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _adminDocCard(
                  label: 'Business Proof',
                  icon: Icons.business_center_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  frontUrl: verif['businessProofFrontUrl'] ??
                      verif['businessProofUrl'],
                  backUrl: null,
                  isVerified: verif['businessProofVerified'] == true,
                  status: verif['businessProofStatus']?.toString(),
                  rejectReason: verif['businessProofRejectReason']?.toString(),
                  fieldKey: 'businessProof',
                  subtitle: verif['businessProofType']?.toString(),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _adminDocCard(
                  label: 'Property Ownership',
                  icon: Icons.home_work_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  frontUrl: verif['propertyProofFrontUrl'] ??
                      verif['propertyProofUrl'],
                  backUrl: null,
                  isVerified: verif['propertyProofVerified'] == true,
                  status: verif['propertyProofStatus']?.toString(),
                  rejectReason: verif['propertyProofRejectReason']?.toString(),
                  fieldKey: 'propertyProof',
                  subtitle: verif['propertyProofType']?.toString(),
                ),
                if (verif['registrationCertificateUrl'] != null) ...[
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _adminDocCard(
                    label: 'Registration Certificate',
                    icon: Icons.assignment_outlined,
                    iconColor: const Color(0xFF10B981),
                    frontUrl: verif['registrationCertificateUrl'],
                    backUrl: null,
                    isVerified: verif['registrationCertificateVerified'] == true,
                    status: verif['registrationCertificateStatus']?.toString(),
                    rejectReason: verif['registrationCertificateRejectReason']?.toString(),
                    fieldKey: 'registrationCertificate',
                  ),
                ],
                if (verif['agencyLicenseUrl'] != null) ...[
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _adminDocCard(
                    label: 'Agency License',
                    icon: Icons.card_membership_outlined,
                    iconColor: const Color(0xFF6366F1),
                    frontUrl: verif['agencyLicenseUrl'],
                    backUrl: null,
                    isVerified: verif['agencyLicenseVerified'] == true,
                    status: verif['agencyLicenseStatus']?.toString(),
                    rejectReason: verif['agencyLicenseRejectReason']?.toString(),
                    fieldKey: 'agencyLicense',
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _contactVerifChip(IconData icon, String label, bool verified) {
    final color = verified ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
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
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
                Text(
                  verified ? 'Verified' : 'Unverified',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ],
            ),
          ),
          Icon(
            verified
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: color,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _adminDocCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String? frontUrl,
    required String? backUrl,
    required bool isVerified,
    required String? status,
    required String? rejectReason,
    required String fieldKey,
    String? subtitle,
  }) {
    Color statusColor;
    String statusText;

    if (isVerified) {
      statusColor = const Color(0xFF16A34A);
      statusText = 'Verified';
    } else if (status == 'pending' || status == 'in_review') {
      statusColor = const Color(0xFF2563EB);
      statusText = 'In Review';
    } else if (status == 'rejected') {
      statusColor = const Color(0xFFDC2626);
      statusText = 'Rejected';
    } else if (frontUrl != null) {
      statusColor = const Color(0xFFD97706);
      statusText = 'Uploaded';
    } else {
      statusColor = const Color(0xFF94A3B8);
      statusText = 'Not Uploaded';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B))),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
              ),
            ],
          ),

          // Rejection reason
          if (rejectReason != null && rejectReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFDC2626), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reason: $rejectReason',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Document thumbnails
          if (frontUrl != null || backUrl != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (frontUrl != null)
                  Expanded(
                    child: _docThumb(frontUrl, 'Front'),
                  ),
                if (frontUrl != null && backUrl != null)
                  const SizedBox(width: 12),
                if (backUrl != null)
                  Expanded(
                    child: _docThumb(backUrl, 'Back'),
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: const Center(
                child: Text('No document uploaded',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF94A3B8))),
              ),
            ),
          ],

          // Admin action buttons
          if (!isVerified && frontUrl != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _verifyDoc(fieldKey),
                    icon: const Icon(Icons.check_circle_outline,
                        size: 16, color: Color(0xFF16A34A)),
                    label: const Text('Verify',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFF16A34A), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDocDialog(fieldKey),
                    icon: const Icon(Icons.cancel_outlined,
                        size: 16, color: Color(0xFFDC2626)),
                    label: const Text('Reject',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFDC2626), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (isVerified) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF16A34A), size: 16),
                const SizedBox(width: 6),
                const Text('Verified by admin',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                  onPressed: () => _revokeDoc(fieldKey),
                  style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: const Text('Revoke',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8))),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _docThumb(String url, String label) {
    return GestureDetector(
      onTap: () => _viewDocFullScreen(url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: url,
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 90,
                    color: const Color(0xFFF1F5F9),
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 90,
                    color: const Color(0xFFF1F5F9),
                    child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Color(0xFF94A3B8))),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.zoom_in_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewDocFullScreen(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      // Aadhaar: also write aadhaarVerified alias
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
          SnackBar(content: Text('Revoke failed: $e'),
              backgroundColor: Colors.red),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Document',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Explain why this document is rejected...',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Reject Document',
                style: TextStyle(color: Colors.white)),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document rejected'),
            backgroundColor: Color(0xFFDC2626),
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

  Widget _buildSuggestionCard(Map<String, dynamic> s) {
    final status =
        s['status']?.toString() ?? 'pending';
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: InkWell(
        onTap: () => _showSuggestionDetailsBottomSheet(s),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  s['business_name']?.toString() ??
                      s['name']?.toString() ??
                      'Untitled Suggestion',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _badge(status, statusColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s['category']?.toString() ?? 'Accommodation',
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 10, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                _formatDate(s['createdAt']),
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);
}

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text.isEmpty ? 'Unknown' : text[0].toUpperCase() + text.substring(1),
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined,
              size: 36, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 8),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _popupItem(IconData icon, String label, Color? color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color ?? const Color(0xFF1E293B),
                fontFamily: 'Outfit')),
      ],
    );
  }

  Widget _buildSectionTitle2(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.8)),
    );
  }

  // ─────────────────── Bottom Actions ───────────────────

  Widget _buildBottomActions(
    bool isActive,
    Map<String, dynamic> user,
    Map<String, dynamic> permissions,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showChangeRoleBottomSheet(
                context,
                (user['role'] ?? permissions['role'])
                        ?.toString()
                        .toLowerCase() ??
                    'student',
              ),
              icon: const Icon(Icons.manage_accounts_outlined, size: 18),
              label: const Text('Change Role'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleToggleStatus(isActive),
              icon: Icon(
                  isActive
                      ? Icons.block_flipped
                      : Icons.check_circle_outline,
                  size: 18),
              label: Text(isActive ? 'Deactivate' : 'Activate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── Role Bottom Sheet ───────────────────

  void _showChangeRoleBottomSheet(
      BuildContext context, String currentRole) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Change User Role',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            fontFamily: 'Outfit')),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Text(
                  'Select the new role. Permissions update instantly.',
                  style:
                      TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                ...[
                  ('student', 'Student',
                      'Can search and apply for student housing.',
                      Icons.school_outlined, const Color(0xFF2563EB)),
                  ('professional', 'Professional',
                      'Can search housing for professionals.',
                      Icons.business_center_outlined,
                      const Color(0xFF7C3AED)),
                  ('hoster', 'Hoster',
                      'Can list properties and manage bookings.',
                      Icons.person_pin_outlined,
                      const Color(0xFFD97706)),
                  ('owner', 'Owner',
                      'Property owner with full listing controls.',
                      Icons.home_work_outlined,
                      const Color(0xFF10B981)),
                ].map((r) {
                  final (value, title, desc, icon, color) = r;
                  final isSelected = currentRole == value ||
                      (value == 'student' &&
                          (currentRole == 'user' ||
                              currentRole.isEmpty));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _handleUpdateRole(value),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.05)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? color.withValues(alpha: 0.3)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.15)
                                    : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon,
                                  color: isSelected
                                      ? color
                                      : const Color(0xFF64748B),
                                  size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? color
                                              : const Color(0xFF1E293B),
                                          fontFamily: 'Outfit')),
                                  Text(desc,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded,
                                  color: color, size: 20)
                            else
                              const Icon(Icons.circle_outlined,
                                  color: Color(0xFFCBD5E1), size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────── Helpers ───────────────────

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
}

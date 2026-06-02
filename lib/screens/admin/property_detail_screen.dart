import 'package:flutter/material.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/screens/admin/widgets/admin_shared_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> property;
  final AdminService adminService;

  const PropertyDetailScreen({
    super.key,
    required this.property,
    required this.adminService,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late Map<String, dynamic> _property;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _property = Map<String, dynamic>.from(widget.property);
  }

  String _formatStatus(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'active') return 'Active';
    if (status == 'pending') return 'Under Review';
    if (status == 'inactive') return 'Inactive';
    if (status == 'rejected') return 'Rejected';
    return status[0].toUpperCase() + status.substring(1);
  }

  Color _getStatusColor(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'active') return Colors.green;
    if (status == 'pending') return Colors.orange;
    if (status == 'rejected') return Colors.red;
    return Colors.grey;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(date.toDate());
    }
    return date.toString();
  }

  Future<void> _handleUpdateStatus(String status) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      // In AdminService, the method is updatePropertyStatus(id, PropertyStatus)
      // We need to map string to enum if necessary, or check if service accepts string.
      // Based on admin_service.dart: updatePropertyStatus(String id, PropertyStatus status)
      // Wait, let me check the service again.

      // For now, I'll use direct Firestore update if enum mapping is complex or route through backend if possible.
      // Actually, admin_service already has approveItem and rejectItem which handle the role changes too.

      if (status == 'approved' || status == 'active') {
        await widget.adminService.approveItem(_property['id'], 'property');
      } else if (status == 'rejected') {
        await widget.adminService.rejectItem(_property['id'], 'property');
      } else {
        // Fallback for other statuses
        await FirebaseFirestore.instance.collection('properties').doc(_property['id']).update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        setState(() => _property['status'] = status);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Property $status successfully'), backgroundColor: Colors.green),
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
    final status = _formatStatus(_property['status']);
    final statusColor = _getStatusColor(_property['status']);
    final images = _property['images'] as List? ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Property Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Outfit')),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_left_rounded, color: Color(0xFF1E293B), size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Gallery / Banner
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Container(
                        height: 250,
                        width: double.infinity,
                        color: const Color(0xFFF1F5F9),
                        child: images.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: images.first,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Icon(Icons.home_work_outlined, size: 60, color: Colors.grey),
                              )
                            : const Icon(Icons.home_work_outlined, color: Colors.grey, size: 60),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: StatusBadge(text: status, color: statusColor),
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
                            child: Text('+${images.length - 1} Photos', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  _property['name'] ?? 'Untitled Property',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Outfit'),
                ),
                const SizedBox(height: 4),
                Text(
                  _property['category'] ?? 'Accommodation',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                const SizedBox(height: 16),

                _buildSectionTitle('LOCATION'),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _property['location'] ?? 'No Address Provided',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569), height: 1.5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('MONTHLY RENT'),
                          const SizedBox(height: 8),
                          Text('₹${_property['monthlyRent'] ?? 'N/A'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('DEPOSIT'),
                          const SizedBox(height: 8),
                          Text('₹${_property['securityDeposit'] ?? 'N/A'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                const SizedBox(height: 16),

                _buildSectionTitle('HOSTER DETAILS'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFF1F5F9),
                      child: Text(_property['hosterName']?.toString().isNotEmpty == true ? _property['hosterName'][0] : 'H', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_property['hosterName'] ?? 'Unknown Hoster', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                          const Text('Verified Property Owner', style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _iconDetail(Icons.phone_outlined, _property['hosterPhone'] ?? 'No Phone'),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                const SizedBox(height: 16),

                _buildSectionTitle('SPECIFICATIONS'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _specChip(Icons.king_bed_outlined, '${_property['rooms'] ?? 0} Rooms'),
                    _specChip(Icons.people_outline, '${_property['occupancy'] ?? 0}% Occupancy'),
                    _specChip(Icons.calendar_today_outlined, 'Listed on ${_formatDate(_property['createdAt'])}'),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                const SizedBox(height: 16),

                _buildSectionTitle('AMENITIES'),
                const SizedBox(height: 12),
                if (_property['amenities'] != null && (_property['amenities'] as List).isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_property['amenities'] as List).map((a) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
                      child: Text(a.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    )).toList(),
                  )
                else
                  const Text('No amenities specified', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                const SizedBox(height: 16),

                _buildSectionTitle('VERIFICATION DOCUMENTS'),
                const SizedBox(height: 16),
                _buildDocumentSection(),

                const SizedBox(height: 40),

                // Actions
                if (_property['status'] == 'pending') ...[
                  _actionBtn('Approve Listing', const Color(0xFFF0FDF4), const Color(0xFF16A34A), Icons.check_circle_outline_rounded, () => _handleUpdateStatus('active')),
                  const SizedBox(height: 12),
                  _actionBtn('Reject Listing', const Color(0xFFFEF2F2), const Color(0xFFDC2626), Icons.cancel_outlined, () => _handleUpdateStatus('rejected')),
                ] else if (_property['status'] == 'active') ...[
                  _actionBtn('Deactivate Listing', const Color(0xFFF1F5F9), const Color(0xFF475569), Icons.pause_circle_outline_rounded, () => _handleUpdateStatus('inactive')),
                ] else ...[
                  _actionBtn('Re-activate Listing', const Color(0xFFF0FDF4), const Color(0xFF16A34A), Icons.play_circle_outline_rounded, () => _handleUpdateStatus('active')),
                ],

                const SizedBox(height: 60),
              ],
            ),
          ),
          if (_isUpdating)
            Container(
              color: Colors.white.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection() {
    final verification = _property['verification'] as Map? ?? {};
    final documents = _property['documents'] as Map? ?? {};

    final List<Map<String, dynamic>> docItems = [
      if (verification['aadhaarUrl'] != null) {'title': 'Aadhaar Card', 'url': verification['aadhaarUrl']},
      if (verification['panUrl'] != null) {'title': 'PAN Card', 'url': verification['panUrl']},
      if (documents['ownershipUrl'] != null) {'title': 'Ownership Proof', 'url': documents['ownershipUrl']},
      if (documents['utilityUrl'] != null) {'title': 'Utility Bill', 'url': documents['utilityUrl']},
      if (documents['additionalUrl'] != null) {'title': 'Additional Doc', 'url': documents['additionalUrl']},
    ];

    if (docItems.isEmpty) {
      return const Text('No documents uploaded', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)));
    }

    return Column(
      children: docItems.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, color: Color(0xFF2563EB), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item['title'],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),
            TextButton(
              onPressed: () => _viewDocument(item['url']),
              child: const Text('View', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      )).toList(),
    );
  }

  void _viewDocument(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: url.toLowerCase().endsWith('.pdf') 
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('PDF viewer not implemented. Please check URL.', textAlign: TextAlign.center)))
                  : CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.2),
    );
  }

  Widget _iconDetail(IconData i, String t) => Row(children: [Icon(i, size: 18, color: const Color(0xFF64748B)), const SizedBox(width: 12), Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)))]);

  Widget _specChip(IconData i, String l) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Text(l, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    ),
  );

  Widget _actionBtn(String l, Color bg, Color t, IconData i, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i, size: 18, color: t),
          const SizedBox(width: 8),
          Text(l, style: TextStyle(color: t, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Outfit')),
        ],
      ),
    ),
  );
}

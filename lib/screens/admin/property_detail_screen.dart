import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/services/property_structure_service.dart';
import 'package:triangle_home/services/admin_api_service.dart';
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
  final Set<String> _expandedFloors = {};
  final Set<String> _expandedRooms = {};
  final PropertyStructureService _structureService = PropertyStructureService();

  @override
  void initState() {
    super.initState();
    _property = Map<String, dynamic>.from(widget.property);
  }

  String _formatStatus(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'active' || status == 'approved') return 'Approved/Live';
    if (status == 'pending') return 'Under Review';
    if (status == 'paused') return 'Paused';
    if (status == 'rejected') return 'Rejected';
    return status[0].toUpperCase() + status.substring(1);
  }

  Color _getStatusColor(dynamic s) {
    final status = s?.toString().toLowerCase() ?? 'pending';
    if (status == 'active' || status == 'approved') return Colors.green;
    if (status == 'pending') return Colors.orange;
    if (status == 'paused') return Colors.blue;
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

    String? rejectionReason;
    if (status == 'rejected') {
      rejectionReason = await _showRejectionDialog();
      if (rejectionReason == null || rejectionReason.isEmpty) return; // User cancelled
    }

    setState(() => _isUpdating = true);
    try {
      if (status == 'approved' || status == 'active') {
        await widget.adminService.approveItem(_property['id'], 'property');
      } else if (status == 'rejected') {
        await widget.adminService.rejectItem(
          _property['id'],
          'property',
          reason: rejectionReason,
        );
      } else {
        await FirebaseFirestore.instance
            .collection('properties')
            .doc(_property['id'])
            .update({
              'status': status,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      if (mounted) {
        setState(() => _property['status'] = status);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Property $status successfully'),
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

  Future<String?> _showRejectionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject Listing'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter reason for rejection...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Reject', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('properties')
          .doc(_property['id'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error loading property: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          _property = snapshot.data!.data()!;
          _property['id'] = snapshot.data!.id;
        }

        final status = _formatStatus(_property['status']);
        final statusColor = _getStatusColor(_property['status']);
        final images = _property['images'] as List? ?? [];

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Property Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontFamily: 'Outfit',
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
            actions: [
              IconButton(
                icon: const Icon(Icons.sync_rounded, color: Color(0xFF1E293B)),
                tooltip: 'Reconcile Property',
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reconciling property stats and pricing...')),
                  );
                  try {
                    await AdminApiService().reconcileProperty(_property['id']);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Property reconciled successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to reconcile property: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
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
                            child:
                                images.isNotEmpty
                                    ? CachedNetworkImage(
                                      imageUrl: images.first,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      errorWidget:
                                          (context, url, error) => const Icon(
                                            Icons.home_work_outlined,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                    )
                                    : const Icon(
                                      Icons.home_work_outlined,
                                      color: Colors.grey,
                                      size: 60,
                                    ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '+${images.length - 1} Photos',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      _property['name'] ?? 'Untitled Property',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _property['category'] ?? _property['type'] ?? _property['propertyType'] ?? _property['basicInfo']?['type'] ?? 'Accommodation',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                    const SizedBox(height: 16),

                    _buildSectionTitle('LOCATION'),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _property['location'] ?? _property['address'] ?? 'No Address Provided',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                    const SizedBox(height: 16),

                    _buildSectionTitle('PRICING & TERMS'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _pricingRow('Single Sharing Rent', '₹${_property['pricing']?['singleRent'] ?? _property['monthlyRent'] ?? _property['price'] ?? 'N/A'}', isHighlighted: true),
                          const Divider(height: 16, color: Color(0xFFE2E8F0)),
                          _pricingRow('Double Sharing Rent', '₹${_property['pricing']?['doubleRent'] ?? 'N/A'}'),
                          const Divider(height: 16, color: Color(0xFFE2E8F0)),
                          _pricingRow('Triple Sharing Rent', '₹${_property['pricing']?['tripleRent'] ?? 'N/A'}'),
                          const Divider(height: 16, color: Color(0xFFE2E8F0)),
                          _pricingRow('Security Deposit', '₹${_property['securityDeposit'] ?? _property['pricing']?['deposit'] ?? 'N/A'}'),
                          const Divider(height: 16, color: Color(0xFFE2E8F0)),
                          _pricingRow('Notice Period', '${_property['pricing']?['noticePeriod'] ?? 'N/A'}'),
                          const Divider(height: 16, color: Color(0xFFE2E8F0)),
                          _pricingRow('Food Included', _property['pricing']?['foodIncluded'] == true ? 'Yes' : 'No'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                    const SizedBox(height: 16),

                    _buildSectionTitle('HOSTER DETAILS'),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final hostProfile = _property['hostProfile'] as Map? ?? {};
                        final hosterName = _property['hosterName'] ?? hostProfile['name'] ?? 'Unknown Hoster';
                        final hosterPhone = _property['hosterPhone'] ?? hostProfile['phone'] ?? 'No Phone';
                        final hosterEmail = hostProfile['email'] ?? 'No Email';
                        final hostType = hostProfile['hostType'] ?? 'Property Owner';
                        final isHostVerified = _property['isHostVerified'] ?? false;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  child: Text(
                                    hosterName.isNotEmpty == true ? hosterName[0].toUpperCase() : 'H',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hosterName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            hostType,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isHostVerified
                                                  ? const Color(0xFFF0FDF4)
                                                  : const Color(0xFFFEF2F2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isHostVerified ? 'Verified' : 'Unverified',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isHostVerified
                                                    ? const Color(0xFF16A34A)
                                                    : const Color(0xFFDC2626),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _iconDetail(Icons.phone_outlined, hosterPhone),
                            const SizedBox(height: 8),
                            _iconDetail(Icons.email_outlined, hosterEmail),
                          ],
                        );
                      }
                    ),

                    Builder(
                      builder: (context) {
                        final basicInfo = _property['basicInfo'] as Map? ?? {};
                        final wardenName = basicInfo['wardenName'];
                        final wardenPhone = basicInfo['phone'];
                        final wardenEmail = basicInfo['email'];

                        if (wardenName != null && wardenName.toString().isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                              const SizedBox(height: 16),
                              _buildSectionTitle('PROPERTY MANAGER / WARDEN'),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    child: Text(
                                      wardenName.toString()[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          wardenName.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const Text(
                                          'On-Site Contact / Warden',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (wardenPhone != null && wardenPhone.toString().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _iconDetail(Icons.phone_outlined, wardenPhone.toString()),
                              ],
                              if (wardenEmail != null && wardenEmail.toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _iconDetail(Icons.email_outlined, wardenEmail.toString()),
                              ],
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      }
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                    const SizedBox(height: 16),

                    _buildSectionTitle('SPECIFICATIONS'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _specChip(
                          Icons.king_bed_outlined,
                          '${_property['rooms'] ?? 0} Rooms',
                        ),
                        _specChip(
                          Icons.people_outline,
                          'Cap: ${_property['totalCapacity'] ?? 0}',
                        ),
                        _specChip(
                          Icons.wc_outlined,
                          'For: ${_property['gender'] ?? 'Anyone'}',
                        ),
                        _specChip(
                          Icons.layers_outlined,
                          'Floors: ${_property['floorsCount'] ?? _property['propertyDetails']?['floorsCount'] ?? 1}',
                        ),
                        if (_property['numberingSystem'] != null || _property['propertyDetails']?['numberingSystem'] != null)
                          _specChip(
                            Icons.tag_rounded,
                            'Label: ${_property['numberingSystem'] ?? _property['propertyDetails']?['numberingSystem']}',
                          ),
                        _specChip(
                          Icons.calendar_today_outlined,
                          'Listed on ${_formatDate(_property['createdAt'])}',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                    const SizedBox(height: 16),

                    _buildSectionTitle('PROPERTY INVENTORY & STRUCTURE'),
                    const SizedBox(height: 12),
                    _buildInventorySummaryBar(),
                    const SizedBox(height: 12),
                    _buildPropertyStructureTree(),
                    const SizedBox(height: 8),
                    _buildBedStatusLegend(),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                    const SizedBox(height: 16),

                    _buildSectionTitle('DESCRIPTION'),
                    const SizedBox(height: 12),
                    Text(
                      _property['description'] ?? 'No description provided',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                    const SizedBox(height: 16),

                    _buildSectionTitle('AMENITIES'),
                    const SizedBox(height: 12),
                    if (_property['amenities'] != null &&
                        (_property['amenities'] as List).isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            (_property['amenities'] as List)
                                .map(
                                  (a) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFF1F5F9),
                                      ),
                                    ),
                                    child: Text(
                                      a.toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      )
                    else
                      const Text(
                        'No amenities specified',
                        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                    const SizedBox(height: 16),

                    _buildSectionTitle('VERIFICATION DOCUMENTS'),
                    const SizedBox(height: 16),
                    _buildDocumentSection(),

                    const SizedBox(height: 40),

                    // Actions
                    if (_property['status'] == 'pending') ...[
                      _actionBtn(
                        'Approve Listing',
                        const Color(0xFFF0FDF4),
                        const Color(0xFF16A34A),
                        Icons.check_circle_outline_rounded,
                        () => _handleUpdateStatus('active'),
                      ),
                      const SizedBox(height: 12),
                      _actionBtn(
                        'Reject Listing',
                        const Color(0xFFFEF2F2),
                        const Color(0xFFDC2626),
                        Icons.cancel_outlined,
                        () => _handleUpdateStatus('rejected'),
                      ),
                    ] else if (_property['status'] == 'active' || _property['status'] == 'approved') ...[
                      _actionBtn(
                        'Deactivate Listing',
                        const Color(0xFFF1F5F9),
                        const Color(0xFF475569),
                        Icons.pause_circle_outline_rounded,
                        () => _handleUpdateStatus('inactive'),
                      ),
                    ] else ...[
                      _actionBtn(
                        'Re-activate Listing',
                        const Color(0xFFF0FDF4),
                        const Color(0xFF16A34A),
                        Icons.play_circle_outline_rounded,
                        () => _handleUpdateStatus('active'),
                      ),
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
      },
    );
  }

  Widget _pricingRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentSection() {
    final verification = _property['verification'] as Map? ?? {};
    final documents = _property['documents'] as Map? ?? {};

    final aadhaarUrl = verification['aadhaarUrl'] ?? _property['aadhaarUrl'];
    final panUrl = verification['panUrl'] ?? _property['panUrl'];
    final regCertUrl = verification['registrationCertificateUrl'] ?? documents['registrationCertificateUrl'] ?? _property['registrationCertificateUrl'];
    final agencyLicUrl = verification['agencyLicenseUrl'] ?? documents['agencyLicenseUrl'] ?? _property['agencyLicenseUrl'];
    final ownershipUrl = documents['ownershipUrl'] ?? _property['ownershipUrl'];
    final utilityUrl = documents['utilityUrl'] ?? _property['utilityUrl'];
    final additionalUrl = documents['additionalUrl'] ?? _property['additionalUrl'];

    final List<Map<String, dynamic>> docItems = [
      if (aadhaarUrl != null)
        {'title': 'Aadhaar Card', 'url': aadhaarUrl},
      if (panUrl != null)
        {'title': 'PAN Card', 'url': panUrl},
      if (regCertUrl != null)
        {'title': 'Registration Certificate', 'url': regCertUrl},
      if (agencyLicUrl != null)
        {'title': 'Agency License', 'url': agencyLicUrl},
      if (ownershipUrl != null)
        {'title': 'Ownership Proof', 'url': ownershipUrl},
      if (utilityUrl != null)
        {'title': 'Utility Bill', 'url': utilityUrl},
      if (additionalUrl != null)
        {'title': 'Additional Doc', 'url': additionalUrl},
    ];

    if (docItems.isEmpty) {
      return const Text(
        'No documents uploaded',
        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      );
    }

    return Column(
      children:
          docItems
              .map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['title'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _viewDocument(item['url']),
                        child: const Text(
                          'View',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  void _viewDocument(String url) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        url.toLowerCase().endsWith('.pdf')
                            ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: Text(
                                  'PDF viewer not implemented. Please check URL.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                            : CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.contain,
                              placeholder:
                                  (context, url) =>
                                      const CircularProgressIndicator(),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.error),
                            ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.black54,
                    ),
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
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _inventoryRow(String label, dynamic count) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    ),
  );

  Widget _iconDetail(IconData i, String t) => Row(
    children: [
      Icon(i, size: 18, color: const Color(0xFF64748B)),
      const SizedBox(width: 12),
      Text(
        t,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
        ),
      ),
    ],
  );

  Widget _specChip(IconData i, String l) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Text(
          l,
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );

  Widget _actionBtn(
    String l,
    Color bg,
    Color t,
    IconData i,
    VoidCallback onTap,
  ) => InkWell(
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
          Icon(i, size: 18, color: t),
          const SizedBox(width: 8),
          Text(
            l,
            style: TextStyle(
              color: t,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Outfit',
            ),
          ),
        ],
      ),
    ),
  );

  /// Live inventory summary bar at the top of the inventory section.
  Widget _buildInventorySummaryBar() {
    final propertyId = _property['id'];
    return StreamBuilder<InventorySummary>(
      stream: _structureService.getInventorySummary(propertyId),
      builder: (context, snapshot) {
        final s = snapshot.data;
        final total = s?.totalBeds ?? 0;
        final available = s?.availableBeds ?? 0;
        final occupied = s?.occupiedBeds ?? 0;
        final maintenance = s?.maintenanceBeds ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E3A8A).withValues(alpha: 0.06),
                const Color(0xFF2563EB).withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryStatCell('Total Beds', total.toString(), const Color(0xFF1E293B)),
              _dividerLine(),
              _summaryStatCell('Available', available.toString(), const Color(0xFF16A34A)),
              _dividerLine(),
              _summaryStatCell('Occupied', occupied.toString(), const Color(0xFF2563EB)),
              _dividerLine(),
              _summaryStatCell(
                'Maintain.',
                maintenance.toString(),
                const Color(0xFFDC2626),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryStatCell(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _dividerLine() => Container(
    height: 28,
    width: 1,
    color: const Color(0xFFCBD5E1),
  );

  /// Bed status color legend.
  Widget _buildBedStatusLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendItem(Colors.green, 'Available'),
        _legendItem(Colors.blue, 'Occupied'),
        _legendItem(Colors.orange, 'Reserved'),
        _legendItem(Colors.red, 'Maintenance'),
        _legendItem(Colors.grey, 'Blocked'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  /// Shows a bottom sheet to let admin override a bed's status.
  void _showAdminBedStatusOverride(
    String bedId,
    String roomId,
    String currentStatus,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Override Bed Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Admin override — use carefully.',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),
              for (final entry in [
                ('available', Colors.green, 'Mark Available'),
                ('occupied', Colors.blue, 'Mark Occupied'),
                ('reserved', Colors.orange, 'Mark Reserved'),
                ('maintenance', Colors.red, 'Mark Maintenance'),
                ('blocked', Colors.grey, 'Block Bed'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        await _structureService.updateBedStatus(
                          propertyId: _property['id'],
                          roomId: roomId,
                          bedId: bedId,
                          newStatus: entry.$1,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Bed status updated to ${entry.$1}'),
                              backgroundColor: entry.$2,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: \$e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            currentStatus == entry.$1
                                ? entry.$2.withValues(alpha: 0.12)
                                : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              currentStatus == entry.$1
                                  ? entry.$2
                                  : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: entry.$2,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            entry.$3,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  currentStatus == entry.$1
                                      ? entry.$2
                                      : const Color(0xFF1E293B),
                            ),
                          ),
                          if (currentStatus == entry.$1) ...[
                            const Spacer(),
                            Icon(Icons.check_rounded, color: entry.$2, size: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPropertyStructureTree() {
    final propertyId = _property['id'];

    final floorsStream = FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .collection('floors')
        .orderBy('floorNumber')
        .snapshots();

    final roomsStream = FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .collection('rooms')
        .snapshots();

    final bedsStream = FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .collection('beds')
        .snapshots();

    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: Rx.combineLatest3(
        floorsStream,
        roomsStream,
        bedsStream,
        (a, b, c) => [a, b, c],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data![0].docs.isEmpty) {
          return Column(
            children: [
              _inventoryRow('Single Rooms', _property['propertyDetails']?['singleRooms'] ?? 0),
              _inventoryRow('Double Rooms', _property['propertyDetails']?['doubleRooms'] ?? 0),
              _inventoryRow('Triple Rooms', _property['propertyDetails']?['tripleRooms'] ?? 0),
              _inventoryRow('Dormitory Beds', _property['propertyDetails']?['dormitoryBeds'] ?? 0),
            ],
          );
        }

        final floors = snapshot.data![0].docs.map((d) => d.data()).toList();
        final rooms = snapshot.data![1].docs.map((d) => d.data()).toList();
        final beds = snapshot.data![2].docs.map((d) => d.data()).toList();

        return StreamBuilder<Map<String, InventorySummary>>(
          stream: _structureService.getFloorOccupancy(propertyId),
          builder: (context, occSnap) {
            final floorOccupancy = occSnap.data ?? {};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: floors.map((floor) {
            final floorId = floor['id'];
            final floorRooms = rooms.where((r) => r['floorId'] == floorId).toList();
            final floorBeds = beds.where((b) => b['floorId'] == floorId).toList();
            final isExpanded = _expandedFloors.contains(floorId);
            final occ = floorOccupancy[floorId];
            final occPercent = occ != null && occ.totalBeds > 0
                ? (occ.occupiedBeds / occ.totalBeds * 100).round()
                : 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Row(
                      children: [
                        Text(
                          floor['name'] ?? 'Floor',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Occupancy badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: occPercent >= 80
                                ? Colors.red.withValues(alpha: 0.12)
                                : occPercent >= 50
                                    ? Colors.orange.withValues(alpha: 0.12)
                                    : Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$occPercent% Occ.',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: occPercent >= 80
                                  ? Colors.red
                                  : occPercent >= 50
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      'Rooms: ${floorRooms.length} | Beds: ${floorBeds.length} | ${floor['status'] ?? 'Active'}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    trailing: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF64748B),
                    ),
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedFloors.remove(floorId);
                        } else {
                          _expandedFloors.add(floorId);
                        }
                      });
                    },
                  ),
                  if (isExpanded) ...[
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: floorRooms.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No rooms on this floor.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : Column(
                              children: floorRooms.map((room) {
                                final roomId = room['id'];
                                final roomBeds =
                                    beds.where((b) => b['roomId'] == roomId).toList();
                                final isRoomExpanded = _expandedRooms.contains(roomId);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        dense: true,
                                        title: Text(
                                          'Room ${room['roomNumber']} (${room['occupancyType'] ?? room['roomType']})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Beds: ${roomBeds.length} | ${room['status'] ?? 'Available'}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        trailing: Icon(
                                          isRoomExpanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons.keyboard_arrow_down_rounded,
                                          size: 18,
                                        ),
                                        onTap: () {
                                          setState(() {
                                            if (isRoomExpanded) {
                                              _expandedRooms.remove(roomId);
                                            } else {
                                              _expandedRooms.add(roomId);
                                            }
                                          });
                                        },
                                      ),
                                      if (isRoomExpanded) ...[
                                        const Divider(
                                          height: 1,
                                          color: Color(0xFFE2E8F0),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            children: roomBeds.map((bed) {
                                              final bedId =
                                                  bed['id'] ?? bed['bedId'] ?? '';
                                              final bStatus =
                                                  bed['status'] ?? 'available';
                                              Color bColor = Colors.green;
                                              if (bStatus == 'occupied') {
                                                bColor = Colors.blue;
                                              }
                                              if (bStatus == 'reserved' ||
                                                  bStatus == 'booked') {
                                                bColor = Colors.orange;
                                              }
                                              if (bStatus == 'maintenance') {
                                                bColor = Colors.red;
                                              }
                                              if (bStatus == 'blocked') {
                                                bColor = Colors.grey;
                                              }

                                              return InkWell(
                                                onTap: () => _showAdminBedStatusOverride(
                                                  bedId,
                                                  roomId,
                                                  bStatus,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                    horizontal: 4,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.king_bed_outlined,
                                                        color: bColor,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          'Bed ${bed['bedNumber']}',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      // Resident info or status
                                                      if (bed['currentResidentId'] != null)
                                                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                                          stream: FirebaseFirestore.instance
                                                              .collection('bookings')
                                                              .doc(bed['currentResidentId'])
                                                              .snapshots(),
                                                          builder: (context, bSnap) {
                                                            if (!bSnap.hasData ||
                                                                !bSnap.data!.exists) {
                                                              return const Text(
                                                                'Occupied',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors.blue,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              );
                                                            }
                                                            final bData = bSnap.data!.data()!;
                                                            final rName =
                                                                bData['tenantDetails']?[0]?['name'] ??
                                                                'Resident';
                                                            return Text(
                                                              rName,
                                                              style: const TextStyle(
                                                                fontSize: 10,
                                                                color: Colors.blue,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            );
                                                          },
                                                        )
                                                      else
                                                        Text(
                                                          bStatus[0].toUpperCase() +
                                                              bStatus.substring(1),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: bColor,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      const SizedBox(width: 4),
                                                      // Admin override indicator
                                                      Icon(
                                                        Icons.tune_rounded,
                                                        size: 12,
                                                        color: Colors.grey.shade400,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
          },
        );
      },
    );
  }
}


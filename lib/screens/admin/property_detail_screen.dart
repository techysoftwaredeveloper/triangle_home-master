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
      if (rejectionReason == null || rejectionReason.isEmpty) return; 
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
            backgroundColor: const Color(0xFF0F172A),
            title: const Text('Reject Listing', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter reason for rejection...',
                hintStyle: TextStyle(color: Colors.white24),
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
        if (snapshot.hasData && snapshot.data!.exists) {
          _property = snapshot.data!.data()!;
          _property['id'] = snapshot.data!.id;
        }

        final basicInfo = Map<String, dynamic>.from(_property['basicInfo'] ?? {});
        final images = _property['images'] as List? ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFF020617), // Enterprise Dark
          appBar: _buildAppBar(),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroIdentity(basicInfo, images),
                    const SizedBox(height: 48),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('LOCATION & SPECIFICATIONS'),
                              const SizedBox(height: 24),
                              _buildLocationGrid(basicInfo),
                              const SizedBox(height: 48),

                              _buildSectionTitle('PRICING & TERMS'),
                              const SizedBox(height: 24),
                              _buildPricingGrid(),
                              const SizedBox(height: 48),

                              _buildSectionTitle('DESCRIPTION'),
                              const SizedBox(height: 16),
                              Text(
                                _property['description'] ?? 'No description provided',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  height: 1.6,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                              const SizedBox(height: 48),

                              _buildSectionTitle('PROPERTY INVENTORY & STRUCTURE'),
                              const SizedBox(height: 24),
                              _buildInventorySummaryBar(),
                              const SizedBox(height: 24),
                              _buildPropertyStructureTree(),
                              const SizedBox(height: 16),
                              _buildBedStatusLegend(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('HOSTER DETAILS'),
                              const SizedBox(height: 24),
                              _buildHosterCard(),
                              const SizedBox(height: 48),

                              _buildSectionTitle('AMENITIES'),
                              const SizedBox(height: 24),
                              _buildAmenitiesChipCloud(),
                              const SizedBox(height: 48),

                              _buildSectionTitle('VERIFICATION DOCUMENTS'),
                              const SizedBox(height: 24),
                              _buildDocumentList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 64),
                    _buildActionPanel(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              if (_isUpdating)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
                ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF020617),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const Text('Property Approval', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x1910B981),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x4D10B981)),
            ),
            child: const Text('Live', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      actions: [
        _appBarAction(Icons.share_outlined, 'Share'),
        _appBarAction(Icons.more_vert_rounded, 'More'),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _appBarAction(IconData icon, String tooltip) {
    return IconButton(
      icon: Icon(icon, color: Colors.white70, size: 20),
      tooltip: tooltip,
      onPressed: () {},
    );
  }

  Widget _buildHeroIdentity(Map<String, dynamic> basic, List images) {
    final name = basic['collegeName'] ?? _property['name'] ?? 'Untitled Property';
    final type = _property['category'] ?? _property['type'] ?? 'Accommodation';
    final status = _property['status'] ?? 'pending';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _darkBadge(type.toString().toUpperCase(), const Color(0xFF6366F1)),
                  const SizedBox(width: 12),
                  _darkBadge(status.toString().toUpperCase(), _getStatusColor(status)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        _buildImagePreview(images),
      ],
    );
  }

  Widget _buildImagePreview(List images) {
    if (images.isEmpty) return const SizedBox.shrink();
    return Container(
      width: 240,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(imageUrl: images.first, fit: BoxFit.cover),
            Container(color: Colors.black26),
            Center(child: Text('+${images.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationGrid(Map<String, dynamic> basic) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0x0DFFFFFF))),
      child: Column(
        children: [
          _infoRow(Icons.location_on_outlined, 'Full Address', _property['location'] ?? 'N/A'),
          const Divider(height: 32, color: Color(0x0DFFFFFF)),
          Row(
            children: [
              Expanded(child: _infoRow(Icons.layers_outlined, 'Floors', '${_property['floorsCount'] ?? 1}')),
              Expanded(child: _infoRow(Icons.king_bed_outlined, 'Total Rooms', '${_property['rooms'] ?? 0}')),
              Expanded(child: _infoRow(Icons.people_outline, 'Total Capacity', '${_property['totalCapacity'] ?? _property['capacity'] ?? 0}')),
              Expanded(child: _infoRow(Icons.wc_outlined, 'Gender', _property['gender'] ?? 'Any')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingGrid() {
    final pricing = Map<String, dynamic>.from(_property['pricing'] as Map? ?? {});
    
    final List<Map<String, dynamic>> tiers = [];
    
    void addTier(String id, String label, Color color) {
      final rentKey = id == 'single' || id == 'double' || id == 'triple' ? '${id}Rent' : '${id}SharingRent';
      final depositKey = id == 'single' || id == 'double' || id == 'triple' ? '${id}Deposit' : '${id}SharingDeposit';
      
      final rent = pricing[rentKey] ?? (id == 'single' ? (_property['monthlyRent'] ?? _property['price']) : null);
      final deposit = pricing[depositKey];
      
      if (rent != null) {
        tiers.add({
          'label': label,
          'rent': rent,
          'deposit': deposit,
          'color': color,
        });
      }
    }

    addTier('single', 'Single Sharing', const Color(0xFF10B981));
    addTier('double', 'Double Sharing', const Color(0xFF3B82F6));
    addTier('triple', 'Triple Sharing', const Color(0xFFF59E0B));
    addTier('four', 'Four Sharing', const Color(0xFF8B5CF6));
    addTier('six', 'Six Sharing', const Color(0xFFEC4899));

    // Fallback if no tiers found
    if (tiers.isEmpty && (_property['monthlyRent'] != null || _property['price'] != null)) {
      tiers.add({
        'label': 'Monthly Rent',
        'rent': _property['monthlyRent'] ?? _property['price'],
        'deposit': _property['securityDeposit'] ?? pricing['deposit'],
        'color': const Color(0xFF10B981),
      });
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0x0DFFFFFF))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 32,
            runSpacing: 32,
            children: tiers.map((t) => SizedBox(
              width: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _priceItem(t['label'], t['rent'], t['color']),
                  if (t['deposit'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.security_outlined, size: 12, color: Colors.white24),
                        const SizedBox(width: 6),
                        Text('Dep: ₹${t['deposit']}', style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            )).toList(),
          ),
          const Divider(height: 64, color: Color(0x0DFFFFFF)),
          Row(
            children: [
              Expanded(child: _infoRow(Icons.security_outlined, 'Primary Deposit', '₹${_property['securityDeposit'] ?? pricing['deposit'] ?? "N/A"}')),
              Expanded(child: _infoRow(Icons.history_outlined, 'Notice Period', pricing['noticePeriod'] ?? 'N/A')),
              Expanded(child: _infoRow(Icons.restaurant_outlined, 'Food Included', pricing['foodIncluded'] == true ? 'YES' : 'NO')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHosterCard() {
    final hostProfile = _property['hostProfile'] as Map? ?? {};
    final basicInfo = _property['basicInfo'] as Map? ?? {};
    final hosterName = _property['hosterName'] ?? hostProfile['name'] ?? 'Unknown Hoster';
    final hostType = hostProfile['hostType'] ?? 'Property Owner';

    // Warden info can be in basicInfo (property level) or in hoster request
    final wardenName = basicInfo['wardenName'] ?? basicInfo['warden_name'];
    final wardenPhone = basicInfo['wardenPhone'] ?? basicInfo['warden_phone'] ?? basicInfo['phone'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0x0DFFFFFF))),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 24, backgroundColor: const Color(0xFF1E293B), child: Text(hosterName[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(hosterName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(hostType, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _infoRow(Icons.phone_outlined, 'Phone', _property['hosterPhone'] ?? hostProfile['phone'] ?? 'N/A'),
          const SizedBox(height: 16),
          _infoRow(Icons.email_outlined, 'Email', hostProfile['email'] ?? 'N/A'),
          
          if (wardenName != null) ...[
            const Divider(height: 48, color: Color(0x0DFFFFFF)),
            _infoRow(Icons.person_pin_outlined, 'On-Site Manager', wardenName),
            const SizedBox(height: 16),
            _infoRow(Icons.phone_iphone_outlined, 'Warden Phone', wardenPhone ?? 'N/A'),
          ] else
            StreamBuilder<Map<String, dynamic>?>(
              stream: widget.adminService.getUserHosterRequestStream(_property['hoster_id'] ?? ''),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final hInfo = snapshot.data!['info'] as Map? ?? {};
                final wName = hInfo['wardenName'] ?? hInfo['warden_name'];
                if (wName == null) return const SizedBox.shrink();
                return Column(children: [
                  const Divider(height: 48, color: Color(0x0DFFFFFF)),
                  _infoRow(Icons.person_pin_outlined, 'On-Site Manager', wName),
                  const SizedBox(height: 16),
                  _infoRow(Icons.phone_iphone_outlined, 'Warden Phone', hInfo['wardenPhone'] ?? hInfo['phone'] ?? 'N/A'),
                ]);
              }
            ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesChipCloud() {
    final amenities = _property['amenities'] as List? ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0x0DFFFFFF))),
      child: amenities.isEmpty
          ? const Text('No amenities listed', style: TextStyle(color: Colors.white24, fontSize: 12))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities.map((a) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x0DFFFFFF))),
                child: Text(a.toString(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
    );
  }

  Widget _buildDocumentList() {
    final verification = _property['verification'] as Map? ?? {};
    final documents = _property['documents'] as Map? ?? {};
    final docItems = [
      if (verification['aadhaarUrl'] != null) {'title': 'Aadhaar Card', 'url': verification['aadhaarUrl']},
      if (verification['panUrl'] != null) {'title': 'PAN Card', 'url': verification['panUrl']},
      if (documents['ownershipUrl'] != null) {'title': 'Ownership Proof', 'url': documents['ownershipUrl']},
      if (documents['utilityUrl'] != null) {'title': 'Utility Bill', 'url': documents['utilityUrl']},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0x0DFFFFFF))),
      child: docItems.isEmpty
          ? const Text('No verification documents', style: TextStyle(color: Colors.white24, fontSize: 12))
          : Column(children: docItems.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                const Icon(Icons.description_outlined, color: Colors.white38, size: 18),
                const SizedBox(width: 12),
                Expanded(child: Text(d['title']!, style: const TextStyle(color: Colors.white, fontSize: 13))),
                TextButton(onPressed: () => _viewDocument(d['url']!), child: const Text('VIEW', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 11))),
              ]),
            )).toList()),
    );
  }

  Widget _buildInventorySummaryBar() {
    return StreamBuilder<InventorySummary>(
      stream: _structureService.getInventorySummary(_property['id']),
      builder: (context, snapshot) {
        final s = snapshot.data;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0x1A6366F1))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metric('Total Beds', s?.totalBeds.toString() ?? '0', Colors.white),
              _verticalDivider(),
              _metric('Occupied', s?.occupiedBeds.toString() ?? '0', const Color(0xFF6366F1)),
              _verticalDivider(),
              _metric('Available', s?.availableBeds.toString() ?? '0', const Color(0xFF10B981)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPropertyStructureTree() {
    final propertyId = _property['id'];
    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: Rx.combineLatest3(
        FirebaseFirestore.instance.collection('properties').doc(propertyId).collection('floors').orderBy('floorNumber').snapshots(),
        FirebaseFirestore.instance.collection('properties').doc(propertyId).collection('rooms').snapshots(),
        FirebaseFirestore.instance.collection('properties').doc(propertyId).collection('beds').snapshots(),
        (a, b, c) => [a, b, c],
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data![0].docs.isEmpty) return const SizedBox.shrink();
        final floors = snapshot.data![0].docs.map((d) => d.data()).toList();
        final rooms = snapshot.data![1].docs.map((d) => d.data()).toList();
        final beds = snapshot.data![2].docs.map((d) => d.data()).toList();

        return Column(
          children: floors.map((floor) {
            final floorId = floor['id'];
            final floorRooms = rooms.where((r) => r['floorId'] == floorId).toList();
            final isExpanded = _expandedFloors.contains(floorId);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x0DFFFFFF))),
              child: Column(
                children: [
                  ListTile(
                    title: Text(floor['name'] ?? 'Floor', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Rooms: ${floorRooms.length} | ${floor['status'] ?? 'Active'}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    trailing: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white38),
                    onTap: () => setState(() => isExpanded ? _expandedFloors.remove(floorId) : _expandedFloors.add(floorId)),
                  ),
                  if (isExpanded) ...[
                    const Divider(height: 1, color: Color(0x0DFFFFFF)),
                    ...floorRooms.map((room) {
                      final roomId = room['id'];
                      final roomBeds = beds.where((b) => b['roomId'] == roomId).toList();
                      final isRoomExpanded = _expandedRooms.contains(roomId);
                      return Column(children: [
                        ListTile(
                          dense: true,
                          title: Text('Room ${room['roomNumber']} (${room['roomType'] ?? 'Standard'})', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          trailing: Icon(isRoomExpanded ? Icons.remove : Icons.add, size: 16, color: Colors.white38),
                          onTap: () => setState(() => isRoomExpanded ? _expandedRooms.remove(roomId) : _expandedRooms.add(roomId)),
                        ),
                        if (isRoomExpanded) Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Wrap(spacing: 8, runSpacing: 8, children: roomBeds.map((bed) {
                            final bStatus = bed['status'] ?? 'available';
                            final bColor = _getBedColor(bStatus);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: bColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: bColor.withValues(alpha: 0.2))),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.king_bed_outlined, color: bColor, size: 14),
                                const SizedBox(width: 6),
                                Text(bed['bedNumber'].toString(), style: TextStyle(color: bColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ]),
                            );
                          }).toList()),
                        ),
                      ]);
                    }),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0x0DFFFFFF))),
      child: Column(
        children: [
          const Text('Administrative Controls', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Finalize your review before taking action.', style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 32),
          if (_property['status'] == 'pending') ...[
            Row(children: [
              Expanded(child: _actionBtn('APPROVE LISTING', const Color(0xFF10B981), Icons.check_circle_outline, () => _handleUpdateStatus('active'))),
              const SizedBox(width: 16),
              Expanded(child: _actionBtn('REJECT LISTING', const Color(0xFFEF4444), Icons.cancel_outlined, () => _handleUpdateStatus('rejected'))),
            ]),
          ] else if (_property['status'] == 'active' || _property['status'] == 'approved') ...[
            _actionBtn('DEACTIVATE PROPERTY', Colors.white.withValues(alpha: 0.05), Icons.pause_circle_outline, () => _handleUpdateStatus('inactive')),
          ] else ...[
            _actionBtn('RE-ACTIVATE PROPERTY', const Color(0xFF10B981), Icons.play_circle_outline, () => _handleUpdateStatus('active')),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: const Color(0xFF6366F1), size: 16), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5))]),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _priceItem(String label, dynamic value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text('₹$value', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
    ]);
  }

  Widget _metric(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _verticalDivider() => Container(width: 1, height: 40, color: const Color(0x0DFFFFFF));

  Widget _darkBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Color _getBedColor(String status) {
    switch (status.toLowerCase()) {
      case 'occupied': return const Color(0xFF3B82F6);
      case 'reserved': return const Color(0xFFF59E0B);
      case 'maintenance': return const Color(0xFFEF4444);
      default: return const Color(0xFF10B981);
    }
  }

  Widget _buildBedStatusLegend() {
    return Wrap(spacing: 16, runSpacing: 8, children: [
      _legendItem(const Color(0xFF10B981), 'Available'),
      _legendItem(const Color(0xFF3B82F6), 'Occupied'),
      _legendItem(const Color(0xFFF59E0B), 'Reserved'),
      _legendItem(const Color(0xFFEF4444), 'Maintenance'),
    ]);
  }

  Widget _legendItem(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
    ]);
  }

  void _viewDocument(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(alignment: Alignment.center, children: [
          ClipRRect(borderRadius: BorderRadius.circular(24), child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain, placeholder: (context, url) => const CircularProgressIndicator()))),
          Positioned(top: 10, right: 10, child: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(context))),
        ]),
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
}

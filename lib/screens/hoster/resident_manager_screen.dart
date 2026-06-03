import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/resident_stay.dart';
import 'package:triangle_home/services/stay_lifecycle_service.dart';
import 'package:triangle_home/theme/app_theme.dart';

class ResidentManagerScreen extends StatefulWidget {
  final String propertyId;

  const ResidentManagerScreen({super.key, required this.propertyId});

  @override
  State<ResidentManagerScreen> createState() => _ResidentManagerScreenState();
}

class _ResidentManagerScreenState extends State<ResidentManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Resident Manager',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDarkColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.successColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.successColor,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Notice Received'),
            Tab(text: 'Rent Overdue'),
            Tab(text: 'Checkout Pending'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildResidentList(StayStatus.active),
                _buildResidentList(StayStatus.noticeSubmitted),
                _buildRentOverdueList(),
                _buildResidentList(StayStatus.checkoutPending),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search by name, room or bed...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildResidentList(StayStatus status) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('resident_stays')
              .where('propertyId', isEqualTo: widget.propertyId)
              .where('status', isEqualTo: status.name)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final residents =
            snapshot.data!.docs
                .map((doc) => ResidentStayModel.fromFirestore(doc))
                .toList();
        // Simple search filter simulation
        final filtered =
            residents
                .where(
                  (r) =>
                      r.residentId.toLowerCase().contains(_searchQuery) ||
                      r.roomId.contains(_searchQuery),
                )
                .toList();

        if (filtered.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _ResidentCard(stay: filtered[index]),
        );
      },
    );
  }

  Widget _buildRentOverdueList() {
    // Specialized query for rent status would go here
    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text(
            'No residents found',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ResidentCard extends StatelessWidget {
  final ResidentStayModel stay;
  const _ResidentCard({required this.stay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resident ID: ${stay.residentId.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Room ${stay.roomId} • Bed ${stay.bedId}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: stay.status),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metaInfo('Rent Status', 'PAID', Colors.green),
              _metaInfo(
                'Stay Duration',
                '${DateTime.now().difference(stay.checkInDate).inDays} Days',
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {}, // Open Resident Detail or Checkout Wizard
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: AppTheme.textDarkColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Manage Residency',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textMutedColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final StayStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.green;
    if (status == StayStatus.noticeSubmitted) color = Colors.orange;
    if (status == StayStatus.checkoutPending) color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

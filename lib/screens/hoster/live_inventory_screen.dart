import 'package:flutter/material.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/models/bed_model.dart';
import 'package:triangle_home/models/room_model.dart';
import 'package:triangle_home/services/inventory_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveInventoryScreen extends StatefulWidget {
  final String propertyId;

  const LiveInventoryScreen({super.key, required this.propertyId});

  @override
  State<LiveInventoryScreen> createState() => _LiveInventoryScreenState();
}

class _LiveInventoryScreenState extends State<LiveInventoryScreen> {
  final InventoryService _inventoryService = InventoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Live Inventory',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDarkColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('properties')
                .doc(widget.propertyId)
                .collection('rooms')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms =
              snapshot.data?.docs
                  .map((doc) => RoomModel.fromFirestore(doc))
                  .toList() ??
              [];

          if (rooms.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: rooms.length,
            itemBuilder:
                (context, index) => _RoomInventoryCard(
                  propertyId: widget.propertyId,
                  room: rooms[index],
                  inventoryService: _inventoryService,
                ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bed_rounded, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text(
            'No inventory defined',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _RoomInventoryCard extends StatelessWidget {
  final String propertyId;
  final RoomModel room;
  final InventoryService inventoryService;

  const _RoomInventoryCard({
    required this.propertyId,
    required this.room,
    required this.inventoryService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room ${room.roomNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${room.roomType.name.toUpperCase()} • Floor ${room.floor}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                _OccupancyBadge(
                  occupied: room.occupiedBeds,
                  total: room.totalBeds,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance
                    .collection('properties')
                    .doc(propertyId)
                    .collection('rooms')
                    .doc(room.id)
                    .collection('beds')
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final beds =
                  snapshot.data!.docs
                      .map((doc) => BedModel.fromFirestore(doc))
                      .toList();

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      beds
                          .map(
                            (bed) => _BedStatusChip(
                              bed: bed,
                              onTap: () => _showBedActions(context, bed),
                            ),
                          )
                          .toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showBedActions(BuildContext context, BedModel bed) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bed ${bed.bedNumber} Actions',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _actionTile(
                  context,
                  'Release Bed',
                  Icons.check_circle_outline,
                  Colors.green,
                  () {
                    inventoryService.releaseBed(
                      propertyId: propertyId,
                      roomId: room.id,
                      bedId: bed.id,
                    );
                    Navigator.pop(context);
                  },
                ),
                _actionTile(
                  context,
                  'Maintenance Mode',
                  Icons.build_circle_outlined,
                  Colors.orange,
                  () {
                    // Implementation of status update for maintenance
                    Navigator.pop(context);
                  },
                ),
                _actionTile(
                  context,
                  'Block Bed',
                  Icons.block_flipped,
                  Colors.red,
                  () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _actionTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _OccupancyBadge extends StatelessWidget {
  final int occupied;
  final int total;
  const _OccupancyBadge({required this.occupied, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$occupied/$total Occupied',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDarkColor,
        ),
      ),
    );
  }
}

class _BedStatusChip extends StatelessWidget {
  final BedModel bed;
  final VoidCallback onTap;

  const _BedStatusChip({required this.bed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    IconData icon = Icons.bed_outlined;

    switch (bed.status) {
      case BedStatus.available:
        color = Colors.green;
        icon = Icons.bed_outlined;
        break;
      case BedStatus.reserved:
        color = Colors.orange;
        icon = Icons.timer_outlined;
        break;
      case BedStatus.occupied:
        color = Colors.blue;
        icon = Icons.person_rounded;
        break;
      case BedStatus.maintenance:
        color = Colors.red;
        icon = Icons.cleaning_services_rounded;
        break;
      default:
        color = Colors.grey;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              bed.bedNumber,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            Text(
              bed.status.name.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

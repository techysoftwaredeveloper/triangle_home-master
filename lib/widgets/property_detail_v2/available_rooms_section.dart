import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AvailableRoomsSection extends StatefulWidget {
  final List<Map<String, dynamic>> rooms;
  final List<Map<String, dynamic>> beds;
  final Function(Map<String, dynamic>, Map<String, dynamic>) onBedSelected;
  final String? selectedBedId;

  const AvailableRoomsSection({
    super.key,
    required this.rooms,
    required this.beds,
    required this.onBedSelected,
    this.selectedBedId,
  });

  @override
  State<AvailableRoomsSection> createState() => _AvailableRoomsSectionState();
}

class _AvailableRoomsSectionState extends State<AvailableRoomsSection> {
  final Set<String> _expandedRooms = {};

  @override
  Widget build(BuildContext context) {
    if (widget.rooms.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Rooms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All Rooms', style: TextStyle(color: AppTheme.successColor)),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: widget.rooms.length,
          itemBuilder: (context, index) {
            final room = widget.rooms[index];
            final roomBeds = widget.beds.where((b) => b['roomId'] == room['id']).toList();
            final isExpanded = _expandedRooms.contains(room['id']);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedRooms.remove(room['id']);
                        } else {
                          _expandedRooms.add(room['id']);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: (room['images'] as List?)?.first ?? '',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(color: Colors.grey[200]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Room ${room['roomNumber']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    room['occupancyType'] ?? 'Sharing',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: roomBeds.map((bed) {
                                    final status = bed['status'] as String? ?? 'available';
                                    return Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: status == 'available' ? AppTheme.successColor : Colors.red,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.5,
                        ),
                        itemCount: roomBeds.length,
                        itemBuilder: (context, idx) {
                          final bed = roomBeds[idx];
                          final isSelected = widget.selectedBedId == bed['id'];
                          final status = bed['status'] as String? ?? 'available';
                          final isAvailable = status == 'available';

                          return InkWell(
                            onTap: isAvailable ? () => widget.onBedSelected(room, bed) : null,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.successColor.withValues(alpha: 0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppTheme.successColor : Colors.grey[200]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Bed ${bed['bedNumber']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isAvailable ? AppTheme.successColor : Colors.red,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: isAvailable ? AppTheme.successColor : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

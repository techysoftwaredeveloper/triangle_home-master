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
  String? _selectedFloor;

  @override
  Widget build(BuildContext context) {
    if (widget.rooms.isEmpty) return const SizedBox.shrink();

    // Group rooms by floor
    final Map<String, List<Map<String, dynamic>>> roomsByFloor = {};
    for (var room in widget.rooms) {
      final floor = room['floor']?.toString() ?? _extractFloorFromRoomNumber(room['roomNumber']?.toString() ?? '');
      roomsByFloor.putIfAbsent(floor, () => []).add(room);
    }

    final sortedFloors = roomsByFloor.keys.toList()..sort((a, b) => a.compareTo(b));

    // Initialize selected floor if not set
    if (_selectedFloor == null || !sortedFloors.contains(_selectedFloor)) {
      _selectedFloor = sortedFloors.isNotEmpty ? sortedFloors.first : null;
    }

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
              _buildFloorDropdown(sortedFloors),
            ],
          ),
        ),
        if (_selectedFloor != null)
          _buildRoomList(roomsByFloor[_selectedFloor!]!),
      ],
    );
  }

  Widget _buildFloorDropdown(List<String> floors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFloor,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: 'Outfit',
          ),
          onChanged: (String? newValue) {
            setState(() {
              _selectedFloor = newValue;
              _expandedRooms.clear(); // Collapse rooms when switching floors
            });
          },
          items: floors.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _extractFloorFromRoomNumber(String roomNumber) {
    if (roomNumber.isEmpty) return 'Unknown';
    // Try to find first digit or 'F' prefix
    final match = RegExp(r'[Ff](\d+)|(\d)').firstMatch(roomNumber);
    if (match != null) {
      return 'Floor ${match.group(1) ?? match.group(2)}';
    }
    return 'Floor 1';
  }

  Widget _buildRoomList(List<Map<String, dynamic>> rooms) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
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
                          imageUrl: (room['images'] is List && (room['images'] as List).isNotEmpty)
                              ? (room['images'] as List).first.toString()
                              : '',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.room_service_outlined, color: Colors.grey),
                          ),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Bed ${bed['bedNumber']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                        Expanded(
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: isAvailable ? AppTheme.successColor : Colors.red,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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
    );
  }
}



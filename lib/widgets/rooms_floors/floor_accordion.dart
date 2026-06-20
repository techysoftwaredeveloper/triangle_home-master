import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/rooms_floors/detailed_room_card.dart';

class FloorAccordion extends StatefulWidget {
  final String floorName;
  final List<Map<String, dynamic>> rooms;
  final List<Map<String, dynamic>> allBeds;
  final String? selectedBedId;
  final Function(Map<String, dynamic>, Map<String, dynamic>) onBedSelected;
  final bool initiallyExpanded;

  const FloorAccordion({
    super.key,
    required this.floorName,
    required this.rooms,
    required this.allBeds,
    required this.selectedBedId,
    required this.onBedSelected,
    this.initiallyExpanded = false,
  });

  @override
  State<FloorAccordion> createState() => _FloorAccordionState();
}

class _FloorAccordionState extends State<FloorAccordion> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    int totalBeds = 0;
    int availableBeds = 0;

    for (var room in widget.rooms) {
      final roomBeds = widget.allBeds.where((b) => b['roomId'] == room['id']);
      totalBeds += roomBeds.length;
      availableBeds += roomBeds.where((b) => b['status']?.toString().toLowerCase() == 'available').length;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.layers_outlined, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.floorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${widget.rooms.length} Rooms | $availableBeds Available',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textLightColor),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Column(
              children: widget.rooms.map((room) {
                final roomBeds = widget.allBeds.where((b) => b['roomId'] == room['id']).toList();
                return DetailedRoomCard(
                  room: room,
                  beds: roomBeds,
                  selectedBedId: widget.selectedBedId,
                  onBedSelected: widget.onBedSelected,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

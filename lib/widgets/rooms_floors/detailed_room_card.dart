import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DetailedRoomCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final List<Map<String, dynamic>> beds;
  final String? selectedBedId;
  final Function(Map<String, dynamic>, Map<String, dynamic>) onBedSelected;

  const DetailedRoomCard({
    super.key,
    required this.room,
    required this.beds,
    required this.selectedBedId,
    required this.onBedSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: (room['images'] is List && (room['images'] as List).isNotEmpty)
                      ? (room['images'] as List).first.toString()
                      : '',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[100],
                    child: const Icon(Icons.room_outlined, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Room ${room['roomNumber']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          '₹${room['monthlyRent'] ?? room['price'] ?? room['baseRent'] ?? room['rent'] ?? 'N/A'}/bed',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room['occupancyType'] ?? 'Sharing',
                      style: const TextStyle(color: AppTheme.accentColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${beds.length} Beds • ${room['bathroomType'] ?? 'Attached Bath'}',
                      style: const TextStyle(color: AppTheme.textLightColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Beds:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildBedMap(),
        ],
      ),
    );
  }

  Widget _buildBedMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: beds.map((bed) {
            final bool isSelected = selectedBedId == bed['id'];
            final String status = bed['status']?.toString().toLowerCase() ?? 'available';
            final bool isAvailable = status == 'available';
            
            Color dotColor = isAvailable ? AppTheme.successGreen : const Color(0xFF64748B);
            if (isSelected) dotColor = AppTheme.primaryColor;

            return InkWell(
              onTap: isAvailable ? () => onBedSelected(room, bed) : null,
              child: Container(
                width: (constraints.maxWidth - 36) / 3, // 3 items per row approx
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bed['bedNumber']?.toString() ?? 'Bed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isSelected ? 'Selected' : status[0].toUpperCase() + status.substring(1),
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textLightColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

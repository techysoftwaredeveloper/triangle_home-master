import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:intl/intl.dart';

class PropertyOverviewCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final Map<String, dynamic> stats;

  const PropertyOverviewCard({super.key, required this.property, required this.stats});

  @override
  Widget build(BuildContext context) {
    final String lastUpdated = stats['updatedAt'] != null 
      ? DateFormat.jm().format(stats['updatedAt'].toDate()) 
      : 'Just now';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  property['title'] ?? 'Property Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
              if (property['verified'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, color: AppTheme.successColor, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(color: AppTheme.successColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber[700], size: 18),
              const SizedBox(width: 4),
              Text(
                '${property['rating'] ?? 0.0}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                '(${property['reviewCount'] ?? 0} Reviews)',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.circle, size: 4, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  property['location'] ?? 'Location',
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(Icons.bed_outlined, stats['availableBeds']?.toString() ?? '0', 'Beds Available'),
              _buildStatItem(Icons.door_front_door_outlined, stats['availableRooms']?.toString() ?? '0', 'Rooms Available'),
              _buildStatItem(Icons.access_time, lastUpdated, 'Last updated'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.black54),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

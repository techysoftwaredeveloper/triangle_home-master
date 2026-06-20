import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class RoomsFloorsHeaderStats extends StatelessWidget {
  final int totalFloors;
  final int totalRooms;
  final int totalBeds;
  final int availableBeds;

  const RoomsFloorsHeaderStats({
    super.key,
    required this.totalFloors,
    required this.totalRooms,
    required this.totalBeds,
    required this.availableBeds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(totalFloors.toString(), 'Floors'),
          _buildStat(totalRooms.toString(), 'Rooms'),
          _buildStat(totalBeds.toString(), 'Beds'),
          _buildStat(
            availableBeds.toString(),
            'Available',
            color: AppTheme.successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textLightColor,
          ),
        ),
      ],
    );
  }
}

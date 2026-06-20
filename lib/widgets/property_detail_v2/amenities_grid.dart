import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class AmenitiesGrid extends StatelessWidget {
  final List<dynamic> amenities;

  const AmenitiesGrid({super.key, required this.amenities});

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();

    // Take top 6-8 amenities for the horizontal display or show all if few
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: amenities.length,
        itemBuilder: (context, index) {
          final amenity = amenities[index].toString();
          return _buildAmenityItem(amenity);
        },
      ),
    );
  }

  Widget _buildAmenityItem(String label) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Light blue-grey background
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getAmenityIcon(label),
              color: AppTheme.primaryColor,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textLightColor,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String label) {
    final l = label.toLowerCase();
    if (l.contains('wifi')) return Icons.wifi;
    if (l.contains('food') || l.contains('meal') || l.contains('breakfast') || l.contains('dinner')) return Icons.restaurant;
    if (l.contains('laundry') || l.contains('wash') || l.contains('machine')) return Icons.local_laundry_service;
    if (l.contains('ac') || l.contains('air')) return Icons.ac_unit;
    if (l.contains('cctv') || l.contains('security') || l.contains('camera')) return Icons.videocam_outlined;
    if (l.contains('power') || l.contains('backup') || l.contains('generator')) return Icons.electric_bolt;
    if (l.contains('water') || l.contains('heater') || l.contains('geyser')) return Icons.hot_tub;
    if (l.contains('parking') || l.contains('bike') || l.contains('car')) return Icons.local_parking;
    if (l.contains('gym') || l.contains('fitness')) return Icons.fitness_center;
    if (l.contains('tv')) return Icons.tv;
    if (l.contains('fridge') || l.contains('refrigerator')) return Icons.kitchen;
    if (l.contains('kitchen')) return Icons.countertops;
    if (l.contains('lift') || l.contains('elevator')) return Icons.elevator;
    if (l.contains('housekeeping') || l.contains('cleaning')) return Icons.cleaning_services;
    return Icons.check_circle_outline;
  }
}

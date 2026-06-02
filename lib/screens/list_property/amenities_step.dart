import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class AmenitiesStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic>? initialData;

  const AmenitiesStep({super.key, required this.onContinue, this.initialData});

  @override
  State<AmenitiesStep> createState() => _AmenitiesStepState();
}

class _AmenitiesStepState extends State<AmenitiesStep> {
  final List<Map<String, dynamic>> _amenities = [
    {'label': 'WiFi', 'icon': Icons.wifi_rounded},
    {'label': 'Food', 'icon': Icons.flatware_rounded},
    {'label': 'Laundry', 'icon': Icons.local_laundry_service_rounded},
    {'label': 'AC', 'icon': Icons.ac_unit_rounded},
    {'label': 'Parking', 'icon': Icons.local_parking_rounded},
    {'label': 'CCTV', 'icon': Icons.videocam_rounded},
    {'label': 'Power Backup', 'icon': Icons.battery_charging_full_rounded},
    {'label': 'Water Purifier', 'icon': Icons.water_drop_rounded},
    {'label': 'Study Room', 'icon': Icons.menu_book_rounded},
    {'label': 'Security', 'icon': Icons.security_rounded},
    {'label': 'Housekeeping', 'icon': Icons.cleaning_services_rounded},
    {'label': 'Lift', 'icon': Icons.elevator_rounded},
  ];

  final Set<String> _selectedAmenities = {};

  @override
  void initState() {
    super.initState();
    final data = widget.initialData?['amenities'] ?? [];
    if (data is List) {
      _selectedAmenities.addAll(List<String>.from(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select available amenities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDarkColor)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.9,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: _amenities.length,
              itemBuilder: (context, index) {
                final amenity = _amenities[index];
                final isSelected = _selectedAmenities.contains(amenity['label']);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedAmenities.remove(amenity['label']);
                      } else {
                        _selectedAmenities.add(amenity['label']);
                      }
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.successColor : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppTheme.successColor : Colors.grey.shade200),
                        ),
                        child: Icon(amenity['icon'], color: isSelected ? Colors.white : AppTheme.textMutedColor, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        amenity['label'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.successColor : AppTheme.textLightColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onContinue({
                  'amenities': _selectedAmenities.toList(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

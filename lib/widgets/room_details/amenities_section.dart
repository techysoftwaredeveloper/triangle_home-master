import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AmenitiesSection extends StatefulWidget {
  const AmenitiesSection({super.key});

  @override
  State<AmenitiesSection> createState() => _AmenitiesSectionState();
}

class _AmenitiesSectionState extends State<AmenitiesSection> {
  bool _showAll = false;

  final List<Map<String, dynamic>> amenities = [
    {'name': 'Food - Vegetarian', 'available': true},
    {'name': 'Food - Non-Vegetarian', 'available': true},
    {'name': 'Attached Bathroom', 'available': true},
    {'name': 'Washing Machine', 'available': true},
    {'name': 'Cleaning Services', 'available': true},
    {'name': 'Water Heater', 'available': false},
    {'name': 'WiFi Connectivity', 'available': true},
    {'name': 'CCTV Surveillance', 'available': false},
    {'name': 'Power Backup', 'available': true},
    {'name': 'Lift Facility', 'available': true},
    {'name': 'Parking Area', 'available': false},
  ];

  @override
  Widget build(BuildContext context) {
    final displayedAmenities = _showAll ? amenities : amenities.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Primary Amenities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Outfit',
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showAll = !_showAll;
                  });
                },
                child: Text(
                  _showAll ? 'View Less' : 'View All',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Outfit',
                    color: Color(0xFF007BFF),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Amenities Box
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(displayedAmenities.length, (index) {
              final amenity = displayedAmenities[index];
              final isAvailable = amenity['available'];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '•',
                          style: TextStyle(
                            fontSize: 24,
                            height: 1,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          amenity['name'],
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF2D2D2D),
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      isAvailable ? Icons.check_circle : Icons.remove_circle,
                      color: isAvailable ? const Color(0xFF1ABC5C) : Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 80).ms);
            }),
          ),
        ),
      ],
    );
  }
}

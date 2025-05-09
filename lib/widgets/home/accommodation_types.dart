

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AccommodationTypes extends StatefulWidget {
  const AccommodationTypes({super.key});

  @override
  State<AccommodationTypes> createState() => _AccommodationTypesState();
}

class _AccommodationTypesState extends State<AccommodationTypes> {
  int selectedIndex = 0;

  final List<String> tabs = [
    'College Hostels',
    'PG Accommodation',
    'Apartments',
  ];

  final List<List<Map<String, dynamic>>> content = [
    [
      {'title': 'College Hostels For Men', 'icon': Icons.man},
      {'title': 'College Hostels For Women', 'icon': Icons.woman},
    ],
    [
      {'title': 'PG Accommodation for Men', 'icon': Icons.boy},
      {'title': 'PG Accommodation for Women', 'icon': Icons.girl},
    ],
    [
      {'title': 'Near My College/University', 'icon': Icons.apartment},
      {'title': 'Around My City/Area', 'icon': Icons.home},
    ],
  ];

  Widget _buildTab(String label, int index) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color.fromARGB(255, 255, 255, 255),
              fontSize: 12,
              fontFamily:  'outfit',
              
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 6),
              height: 2,
              width: 70,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.9),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(2),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildTypeCard(String title, IconData icon) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
        leading: Icon(icon, size: 28, color: const Color.fromARGB(255, 5, 155, 224)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontFamily:  'outfit',
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black45),
        onTap: () {},
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A7BD5), Color(0xFF00D2FF)], // Blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) => _buildTab(tabs[i], i)),
          ),
          const SizedBox(height: 24),

          // Animated Content Cards
          ...content[selectedIndex].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildTypeCard(item['title'], item['icon']),
              )),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

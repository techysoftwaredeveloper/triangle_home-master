import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CityTags extends StatelessWidget {
  final List<String> cities;

  const CityTags({
    super.key,
    required this.cities,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Text(
            'Jump To City:  ',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 12,
              fontFamily:  'outfit',
            ),
          ),
          ...List.generate(
            cities.length,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: Colors.grey[200],
                side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255), width: 0.9),
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  fontFamily:  'outfit',
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                label: Text(cities[index]),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0);
  }
}
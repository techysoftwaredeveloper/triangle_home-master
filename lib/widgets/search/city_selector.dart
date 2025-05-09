import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CitySelector extends StatelessWidget {
  final List<String> cities;
  final String selectedCity;
  final Function(String) onCitySelected;

  const CitySelector({
    super.key,
    required this.cities,
    required this.selectedCity,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cities.map((city) {
          final isSelected = city == selectedCity;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(city),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onCitySelected(city);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF1E3A8A),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          );
        }).toList(),
      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
    );
  }
}
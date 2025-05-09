import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LocalityFilters extends StatelessWidget {
  final List<String> selectedLocalities;
  final Function(String) onLocalityRemoved;
  final VoidCallback onAddMore;

  const LocalityFilters({
    super.key,
    required this.selectedLocalities,
    required this.onLocalityRemoved,
    required this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Locality Filters:',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            TextButton(
              onPressed: onAddMore,
              child: const Text(
                'Add More',
                style: TextStyle(color: Color(0xFF1E3A8A)),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedLocalities.map((locality) {
            return Chip(
              label: Text(locality),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => onLocalityRemoved(locality),
              backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
              labelStyle: const TextStyle(color: Color(0xFF1E3A8A)),
            );
          }).toList(),
        ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),
      ],
    );
  }
}
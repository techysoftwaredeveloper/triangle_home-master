import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TenantSelector extends StatefulWidget {
  const TenantSelector({super.key});

  @override
  State<TenantSelector> createState() => _TenantSelectorState();
}

class _TenantSelectorState extends State<TenantSelector> {
  int? selectedTenant;

  void _selectTenant(int index) {
    setState(() {
      selectedTenant = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Number of Tenants In Room:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Outfit',
                color: Colors.white,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
          Row(
            children: List.generate(4, (index) {
              final isSelected = selectedTenant == index;
              return Padding(
                padding: const EdgeInsets.only(right: 15),
                child: GestureDetector(
                  onTap: () => _selectTenant(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        color: isSelected ? const Color(0xFF1E4373) : Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2, end: 0),

          // Optional validation message
          if (selectedTenant == null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: const Text(
                '* Please select number of tenants',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                  fontFamily: 'Outfit',
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
        ],
      ),
    );
  }
}

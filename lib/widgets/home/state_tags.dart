import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';

class StateTags extends StatelessWidget {
  final List<String> states;
  final String selectedState;
  final String currentLocation;
  final void Function(String state) onStateSelected;

  const StateTags({
    super.key,
    required this.states,
    required this.selectedState,
    required this.currentLocation,
    required this.onStateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. FIXED LABEL: "Jump To City"
          _buildFixedLabel(),

          const SizedBox(width: 8),

          // 2. SCROLLABLE CONTENT: "Near Me" + Cities
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  if (currentLocation.isNotEmpty)
                    _buildNearMeButton(),

                  ...states.map((state) => _buildCityChip(state)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildFixedLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.near_me_outlined, size: 14, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        Text(
          'Jump To City',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.5,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 1,
          height: 20,
          color: const Color(0xFFE2E8F0),
        ),
      ],
    );
  }

  Widget _buildNearMeButton() {
    final bool isSelected = selectedState == currentLocation || selectedState == 'Detecting...';
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onStateSelected('near_me_trigger'),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.accentColor : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              if (selectedState == 'Detecting...')
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                Icon(
                  Icons.my_location_rounded,
                  size: 14,
                  color: isSelected ? Colors.white : AppTheme.accentColor
                ),
              const SizedBox(width: 6),
              Text(
                selectedState == 'Detecting...' ? 'Locating...' : 'Near Me',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityChip(String state) {
    final bool isSelected = state == selectedState;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(state),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) onStateSelected(state);
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
          fontFamily: AppTheme.fontFamily,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        elevation: isSelected ? 2 : 0,
        pressElevation: 4,
      ),
    );
  }
}

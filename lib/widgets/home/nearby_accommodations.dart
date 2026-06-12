import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:triangle_home/widgets/home/premium_property_card.dart';
import 'package:triangle_home/theme/app_theme.dart';

class NearbyAccommodations extends StatelessWidget {
  final List<Map<String, dynamic>> accommodations;
  final String selectedCity;
  final String? customTitle;

  const NearbyAccommodations({
    super.key,
    required this.accommodations,
    required this.selectedCity,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    // Filtering is done in propertiesStreamProvider; show all passed items.
    final filteredAccommodations = accommodations;

    final title =
        customTitle ??
        (selectedCity.isEmpty ||
                selectedCity.toLowerCase() == 'all' ||
                selectedCity.toLowerCase() == 'global'
            ? 'PG Accommodations'
            : selectedCity.toLowerCase() == 'near me'
                ? 'PG Accommodations Near You'
                : 'PG Accommodations in $selectedCity');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDarkColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 540, // Increased to 540 to prevent bottom overflow on various screen sizes
            child:
                filteredAccommodations.isEmpty
                    ? const Center(
                      child: Text(
                        "No properties found.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredAccommodations.length,
                      itemBuilder: (context, index) {
                        return PremiumPropertyCard(
                          property: filteredAccommodations[index],
                          width: 320,
                        ).animate().fadeIn(delay: (300 + index * 150).ms);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:triangle_home/screens/room_details_screen.dart';
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
    final filteredAccommodations =
        (selectedCity.toLowerCase() == 'near me' ||
                selectedCity.toLowerCase() == 'all' ||
                selectedCity.isEmpty)
            ? accommodations
            : accommodations
                .where(
                  (acc) =>
                      (acc['city']?.toString().toLowerCase() ?? '') ==
                      selectedCity.toLowerCase(),
                )
                .toList();

    final title =
        customTitle ??
        (selectedCity.toLowerCase() == 'near me'
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
            height: 330,
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
                        final accommodation = filteredAccommodations[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => RoomDetailsScreen(
                                      accommodation: accommodation,
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: accommodation['image'] ?? '',
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => Container(
                                          height: 180,
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                    errorWidget:
                                        (context, url, error) => Container(
                                          height: 180,
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(Icons.error),
                                          ),
                                        ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        accommodation['title'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: AppTheme.fontBase,
                                          fontFamily: AppTheme.fontFamily,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textDarkColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        accommodation['location'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: AppTheme.fontSM,
                                          fontFamily: AppTheme.fontFamily,
                                          fontWeight: FontWeight.normal,
                                          color: AppTheme.textLightColor,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              SvgPicture.asset(
                                                'assets/images/sharingicon.svg',
                                                height: 16,
                                                width: 16,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                      AppTheme.primaryColor,
                                                      BlendMode.srcIn,
                                                    ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                accommodation['sharing'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: AppTheme.fontSM,
                                                  fontFamily:
                                                      AppTheme.fontFamily,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      '₹${accommodation['price'] ?? '0'}',
                                                  style: const TextStyle(
                                                    fontSize: AppTheme.fontLG,
                                                    fontFamily:
                                                        AppTheme.fontFamily,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppTheme.textDarkColor,
                                                  ),
                                                ),
                                                const TextSpan(
                                                  text: ' /Month',
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppTheme.fontXS + 1,
                                                    fontFamily:
                                                        AppTheme.fontFamily,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppTheme.textLightColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: (300 + index * 150).ms);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';

class AmenitiesSection extends StatefulWidget {
  final List<String> amenities;
  final String propertyType;

  /// For apartments: key highlights list of maps {icon, label, sublabel?}
  final List<Map<String, dynamic>> highlights;

  /// Structured amenity categories — overrides flat [amenities] list for Hostel/PG.
  /// Keys: `food`, `utilities`, `comfort`, `facilities`, `safety`
  /// Each value is a List of maps with `label` and `available` (bool)
  final Map<String, List<Map<String, dynamic>>> amenityCategories;

  /// BHK-specific property details for apartments:
  /// Keys: `bedrooms`, `bathrooms`, `floor`, `parking`, `age`, `facing`, `furnishing`
  final Map<String, dynamic> bhkDetails;

  /// Project status string, e.g. 'Ready to Move', 'Under Construction'
  final String propertyStatus;

  const AmenitiesSection({
    super.key,
    this.amenities = const [],
    this.propertyType = '',
    this.highlights = const [],
    this.amenityCategories = const {},
    this.bhkDetails = const {},
    this.propertyStatus = '',
  });

  @override
  State<AmenitiesSection> createState() => _AmenitiesSectionState();
}

class _AmenitiesSectionState extends State<AmenitiesSection> {
  bool _showAll = false;

  bool get _isApartment =>
      widget.propertyType.toLowerCase().contains('apartment') ||
      widget.propertyType.toLowerCase().contains('flat');

  @override
  Widget build(BuildContext context) {
    if (_isApartment) return _buildKeyHighlights();
    return _buildCategorizedAmenities();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Apartments: Key Highlights expanded grid
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildKeyHighlights() {
    final highlights =
        widget.highlights.isNotEmpty
            ? widget.highlights
            : _buildHighlightsFromDetails();

    return Container(
      color: const Color(0xFFF5F6FA),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Highlights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Outfit',
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: _buildHighlightGrid(highlights),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  /// Build highlights from bhkDetails + amenities fallback
  List<Map<String, dynamic>> _buildHighlightsFromDetails() {
    final result = <Map<String, dynamic>>[];
    final d = widget.bhkDetails;

    // Area
    final area = d['area'] as int? ?? d['carpetArea'] as int?;
    if (area != null && area > 0) {
      result.add({
        'icon': Icons.grid_view_outlined,
        'label': '$area sq ft',
        'sublabel': 'Carpet Area',
      });
    }

    // Furnishing
    final furnishing =
        (d['furnishing'] as String?) ?? (d['furnishingStatus'] as String?);
    if (furnishing != null && furnishing.isNotEmpty) {
      result.add({
        'icon': Icons.chair_outlined,
        'label': furnishing,
        'sublabel': 'Furnishing',
      });
    } else if (widget.amenities.any(
      (a) =>
          a.toLowerCase().contains('furnish') ||
          a.toLowerCase().contains('move'),
    )) {
      final match = widget.amenities.firstWhere(
        (a) =>
            a.toLowerCase().contains('furnish') ||
            a.toLowerCase().contains('move'),
      );
      result.add({'icon': Icons.chair_outlined, 'label': match});
    }

    // Bedrooms
    final bedrooms = d['bedrooms'] as int?;
    if (bedrooms != null) {
      result.add({
        'icon': Icons.bed_outlined,
        'label': '$bedrooms Bedroom${bedrooms == 1 ? '' : 's'}',
        'sublabel': 'Configuration',
      });
    }

    // Bathrooms
    final bathrooms = d['bathrooms'] as int?;
    if (bathrooms != null) {
      result.add({
        'icon': Icons.bathtub_outlined,
        'label': '$bathrooms Bathroom${bathrooms == 1 ? '' : 's'}',
        'sublabel': '',
      });
    }

    // Floor
    final floor =
        d['floor'] as String? ??
        (d['floorNumber'] != null ? '${d['floorNumber']}' : null);
    if (floor != null && floor.isNotEmpty) {
      result.add({
        'icon': Icons.layers_outlined,
        'label':
            floor.contains('Floor') || floor.contains('floor')
                ? floor
                : '$floor Floor',
        'sublabel': 'Floor',
      });
    }

    // Parking
    final parking = d['parking'];
    if (parking == true || parking == 'Yes' || parking == 'yes') {
      result.add({
        'icon': Icons.directions_car_outlined,
        'label': 'Parking Available',
      });
    } else if (parking == false || parking == 'No' || parking == 'no') {
      result.add({
        'icon': Icons.directions_car_outlined,
        'label': 'No Parking',
        'unavailable': true,
      });
    }

    // Property age / project status
    final age = d['age'] as String? ?? d['propertyAge'] as String?;
    if (age != null && age.isNotEmpty) {
      result.add({
        'icon': Icons.calendar_today_outlined,
        'label': age,
        'sublabel': 'Property Age',
      });
    } else if (widget.propertyStatus.isNotEmpty) {
      result.add({
        'icon': Icons.info_outline_rounded,
        'label': widget.propertyStatus,
        'sublabel': 'Status',
      });
    }

    // Facing direction
    final facing = d['facing'] as String?;
    if (facing != null && facing.isNotEmpty) {
      result.add({
        'icon': Icons.explore_outlined,
        'label': '$facing Facing',
        'sublabel': 'Direction',
      });
    }

    // Lift / elevator from amenities
    if (widget.amenities.any(
      (a) =>
          a.toLowerCase().contains('lift') ||
          a.toLowerCase().contains('elevator'),
    )) {
      result.add({'icon': Icons.elevator_outlined, 'label': 'Lift Available'});
    }

    // Fall back to default if nothing resolved
    if (result.isEmpty) {
      return _defaultHighlightsFromAmenities();
    }
    return result;
  }

  Widget _buildHighlightGrid(List<Map<String, dynamic>> items) {
    final rows = <List<Map<String, dynamic>>>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add([items[i], if (i + 1 < items.length) items[i + 1]]);
    }
    return Column(
      children:
          rows.asMap().entries.map((entry) {
            final rowIndex = entry.key;
            final pair = entry.value;
            return Column(
              children: [
                if (rowIndex > 0)
                  Divider(color: Colors.grey.shade100, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(child: _buildHighlightItem(pair[0])),
                      if (pair.length > 1) ...[
                        Container(
                          width: 1,
                          height: 48,
                          color: Colors.grey.shade100,
                        ),
                        Expanded(child: _buildHighlightItem(pair[1])),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildHighlightItem(Map<String, dynamic> item) {
    final icon = item['icon'] as IconData? ?? Icons.star_outline;
    final label = item['label'] as String? ?? '';
    final sublabel = item['sublabel'] as String? ?? '';
    final unavailable = item['unavailable'] as bool? ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 28,
          color:
              unavailable ? const Color(0xFFBDBDBD) : AppTheme.textLightColor,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            color: unavailable ? const Color(0xFFBDBDBD) : AppTheme.textColor,
            height: 1.4,
          ),
        ),
        if (sublabel.isNotEmpty)
          Text(
            sublabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'Outfit',
              color: AppTheme.textLightColor,
            ),
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _defaultHighlightsFromAmenities() {
    final result = <Map<String, dynamic>>[];
    if (widget.amenities.isNotEmpty) {
      for (final amenity in widget.amenities.take(6)) {
        result.add({'icon': _iconForAmenity(amenity), 'label': amenity});
      }
    } else {
      result.addAll([
        {'icon': Icons.grid_view_outlined, 'label': 'Carpet Area'},
        {'icon': Icons.bed_outlined, 'label': 'Move In Ready'},
        {'icon': Icons.directions_car_outlined, 'label': 'Parking'},
        {'icon': Icons.elevator_outlined, 'label': 'Lift Available'},
      ]);
    }
    return result;
  }

  IconData _iconForAmenity(String amenity) {
    final a = amenity.toLowerCase();
    if (a.contains('carpet') || a.contains('area') || a.contains('sqft'))
      return Icons.grid_view_outlined;
    if (a.contains('furnished') || a.contains('furnish'))
      return Icons.bed_outlined;
    if (a.contains('parking') || a.contains('car'))
      return Icons.directions_car_outlined;
    if (a.contains('gym') || a.contains('fitness'))
      return Icons.fitness_center_outlined;
    if (a.contains('pool') || a.contains('swimming'))
      return Icons.pool_outlined;
    if (a.contains('lift') || a.contains('elevator'))
      return Icons.elevator_outlined;
    if (a.contains('security') || a.contains('guard'))
      return Icons.security_outlined;
    if (a.contains('wifi') || a.contains('internet'))
      return Icons.wifi_outlined;
    if (a.contains('power') || a.contains('backup'))
      return Icons.power_outlined;
    return Icons.check_circle_outline;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Hostel / PG: Categorized amenities
  // ─────────────────────────────────────────────────────────────────────────

  static const _categoryMeta = {
    'food': (label: 'Food', icon: Icons.restaurant_outlined),
    'utilities': (label: 'Utilities', icon: Icons.electrical_services_outlined),
    'comfort': (label: 'Comfort', icon: Icons.bed_outlined),
    'facilities': (
      label: 'Facilities',
      icon: Icons.local_laundry_service_outlined,
    ),
    'safety': (label: 'Safety', icon: Icons.security_outlined),
  };

  Widget _buildCategorizedAmenities() {
    // Build categories from structured data or infer from flat list
    final cats =
        widget.amenityCategories.isNotEmpty
            ? widget.amenityCategories
            : _inferCategories(widget.amenities);

    if (cats.isEmpty && widget.amenities.isEmpty)
      return const SizedBox.shrink();

    // Flatten to a combined list for "show all" logic
    final allCategories =
        _categoryMeta.keys
            .where((k) => cats.containsKey(k) && cats[k]!.isNotEmpty)
            .toList();

    // When not showing all, show at most 2 categories
    final visibleCategories =
        _showAll ? allCategories : allCategories.take(2).toList();

    final hasMore = allCategories.length > 2;

    return Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amenities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Outfit',
                    color: AppTheme.textColor,
                  ),
                ),
                if (hasMore)
                  GestureDetector(
                    onTap: () => setState(() => _showAll = !_showAll),
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

          // Category cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children:
                  visibleCategories.asMap().entries.map((entry) {
                    final key = entry.value;
                    final meta = _categoryMeta[key]!;
                    final items = cats[key]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CategoryCard(
                        label: meta.label,
                        icon: meta.icon,
                        items: items,
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: entry.key * 80),
                        duration: 300.ms,
                      ),
                    );
                  }).toList(),
            ),
          ),

          // Flat fallback if no categorized data but flat amenities exist
          if (cats.isEmpty && widget.amenities.isNotEmpty) _buildFlatFallback(),
        ],
      ),
    );
  }

  Widget _buildFlatFallback() {
    final displayed =
        _showAll ? widget.amenities : widget.amenities.take(4).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Column(
          children: List.generate(displayed.length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '•',
                        style: TextStyle(
                          fontSize: 20,
                          height: 1,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        displayed[index],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D2D2D),
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF1ABC5C),
                    size: 20,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: index * 60));
          }),
        ),
      ),
    );
  }

  /// Infer categories from a flat amenity list using keyword matching
  Map<String, List<Map<String, dynamic>>> _inferCategories(
    List<String> amenities,
  ) {
    final food = <Map<String, dynamic>>[];
    final utilities = <Map<String, dynamic>>[];
    final comfort = <Map<String, dynamic>>[];
    final facilities = <Map<String, dynamic>>[];
    final safety = <Map<String, dynamic>>[];

    for (final a in amenities) {
      final lower = a.toLowerCase();
      final item = {'label': a, 'available': true};
      if (lower.contains('food') ||
          lower.contains('veg') ||
          lower.contains('non-veg') ||
          lower.contains('meal') ||
          lower.contains('canteen') ||
          lower.contains('dining')) {
        food.add(item);
      } else if (lower.contains('wifi') ||
          lower.contains('electricity') ||
          lower.contains('water') ||
          lower.contains('power') ||
          lower.contains('internet')) {
        utilities.add(item);
      } else if (lower.contains('ac') ||
          lower.contains('fan') ||
          lower.contains('furnished') ||
          lower.contains('mattress') ||
          lower.contains('bed') ||
          lower.contains('geyser')) {
        comfort.add(item);
      } else if (lower.contains('laundry') ||
          lower.contains('washing') ||
          lower.contains('housekeeping') ||
          lower.contains('kitchen') ||
          lower.contains('parking')) {
        facilities.add(item);
      } else if (lower.contains('security') ||
          lower.contains('cctv') ||
          lower.contains('biometric') ||
          lower.contains('access') ||
          lower.contains('warden')) {
        safety.add(item);
      } else {
        // Leftover goes to facilities as a catch-all
        facilities.add(item);
      }
    }

    return {
      if (food.isNotEmpty) 'food': food,
      if (utilities.isNotEmpty) 'utilities': utilities,
      if (comfort.isNotEmpty) 'comfort': comfort,
      if (facilities.isNotEmpty) 'facilities': facilities,
      if (safety.isNotEmpty) 'safety': safety,
    };
  }
}

// ── Category card ──
class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Map<String, dynamic>> items;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade100, height: 1),

          // Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children:
                  items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final itemLabel = item['label'] as String? ?? '';
                    final available = item['available'] as bool? ?? true;
                    return _AmenityRow(
                      label: itemLabel,
                      available: available,
                      showDivider: idx < items.length - 1,
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenityRow extends StatelessWidget {
  final String label;
  final bool available;
  final bool showDivider;

  const _AmenityRow({
    required this.label,
    required this.available,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      fontSize: 20,
                      height: 1,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      color:
                          available
                              ? const Color(0xFF2D2D2D)
                              : AppTheme.textLightColor,
                    ),
                  ),
                ],
              ),
              available
                  ? const Icon(
                    Icons.check_circle,
                    color: Color(0xFF1ABC5C),
                    size: 20,
                  )
                  : const Icon(
                    Icons.cancel_outlined,
                    color: Color(0xFFBDBDBD),
                    size: 20,
                  ),
            ],
          ),
        ),
        if (showDivider) Divider(color: Colors.grey.shade100, height: 1),
      ],
    );
  }
}

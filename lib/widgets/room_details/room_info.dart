import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

bool _isApartment(String type) =>
    type.toLowerCase().contains('apartment') ||
    type.toLowerCase().contains('flat');

class RoomInfo extends StatefulWidget {
  final String city;
  final String type;
  final String name;
  final double rating;
  final int reviewCount;
  final int totalBeds;
  /// Per-sharing prices: {1: price, 2: price, 3: price, 4: price}
  final Map<int, int> sharingPrices;
  /// Per-sharing available rooms count: {1: count, 2: count, ...}
  final Map<int, int> availabilityBySharing;
  /// Per-BHK available units: {0: count, 1: count, ...} (0-based index)
  final Map<int, int> availabilityByBhk;
  /// Currently selected BHK index (apartments only)
  final int selectedBhkIndex;
  /// Area (sq ft) for currently selected BHK config
  final int bhkArea;
  /// Gender allowed: 'Boys', 'Girls', 'Unisex', or ''
  final String gender;
  /// Project status: 'Ready to Move', 'Under Construction', etc.
  final String projectStatus;
  /// Property category: 'Apartment', 'Gated Community', etc.
  final String propertyCategory;
  /// Distance descriptors, e.g. ['500m to VTU', '2km to Bus Stop']
  final List<String> distances;
  final Function(int)? onTenantSelected;
  /// Called with 0-based BHK index when user selects a BHK option
  final Function(int)? onBhkSelected;

  const RoomInfo({
    super.key,
    required this.city,
    required this.type,
    this.name = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.totalBeds = 0,
    this.sharingPrices = const {},
    this.availabilityBySharing = const {},
    this.availabilityByBhk = const {},
    this.selectedBhkIndex = 0,
    this.bhkArea = 0,
    this.gender = '',
    this.projectStatus = '',
    this.propertyCategory = '',
    this.distances = const [],
    this.onTenantSelected,
    this.onBhkSelected,
  });

  @override
  State<RoomInfo> createState() => _RoomInfoState();
}

class _RoomInfoState extends State<RoomInfo> {
  int? _selectedTenant;
  int _selectedBhk = 0;

  bool get _isApt => _isApartment(widget.type);

  void _selectTenant(int index) {
    final count = index + 1;
    // Don't allow selection if no availability
    final avail = widget.availabilityBySharing[count];
    if (avail != null && avail == 0) return;
    setState(() => _selectedTenant = index);
    widget.onTenantSelected?.call(count);
  }

  void _selectBhk(int index) {
    setState(() => _selectedBhk = index);
    widget.onBhkSelected?.call(index);
  }

  Future<void> _openMaps() async {
    final query = Uri.encodeComponent(widget.city);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.name.isNotEmpty ? widget.name : widget.type;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Navy identity block ──
        Container(
          color: AppTheme.primaryColor,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type / status / gender badges row
              if (!_isApt)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BadgeRow(
                    propertyType: widget.type,
                    gender: widget.gender,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ApartmentBadgeRow(
                    projectStatus: widget.projectStatus,
                    propertyCategory: widget.propertyCategory,
                  ),
                ),

              // Property name
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              // Rating + reviews row
              if (widget.rating > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RatingRow(
                    rating: widget.rating,
                    reviewCount: widget.reviewCount,
                    totalBeds: widget.totalBeds,
                  ),
                ),

              // Address + View On Map
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _openMaps,
                      child: Text(
                        widget.city,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 36,
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _openMaps,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'View On Map',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Distance chips
              if (widget.distances.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: widget.distances.map((d) => _DistanceChip(label: d)).toList(),
                  ),
                ),
            ],
          ),
        ),

        // ── Selector block ──
        Container(
          color: const Color(0xFFF5F6FA),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: _isApt ? _buildBhkSelector() : _buildTenantSelector(),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0);
  }

  // ── BHK selector for Apartments ──
  Widget _buildBhkSelector() {
    const bhkLabels = ['1 BHK', '2 BHK', '3 BHK', '4 BHK'];
    // Sync internal state with parent-driven selectedBhkIndex
    if (_selectedBhk != widget.selectedBhkIndex) {
      _selectedBhk = widget.selectedBhkIndex;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: List.generate(bhkLabels.length, (index) {
            final isSelected = _selectedBhk == index;
            final avail = widget.availabilityByBhk[index];
            final isUnavailable = avail != null && avail == 0;
            return GestureDetector(
              onTap: isUnavailable ? null : () => _selectBhk(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isUnavailable
                      ? Colors.grey.shade200
                      : isSelected
                          ? AppTheme.primaryColor
                          : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUnavailable
                        ? Colors.grey.shade300
                        : isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.22),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  bhkLabels[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    color: isUnavailable
                        ? Colors.grey.shade400
                        : isSelected
                            ? Colors.white
                            : AppTheme.textColor,
                  ),
                ),
              ),
            );
          }),
        ),
        // Availability status for selected BHK
        if (widget.availabilityByBhk.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _BhkAvailabilityStatus(
              index: _selectedBhk,
              availability: widget.availabilityByBhk,
            ).animate().fadeIn(duration: 200.ms),
          ),
        // Area hint
        if (widget.bhkArea > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.grid_view_outlined,
                    size: 13, color: AppTheme.textLightColor),
                const SizedBox(width: 5),
                Text(
                  '${widget.bhkArea} sq ft carpet area',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Outfit',
                    color: AppTheme.textLightColor,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 200.ms),
          ),
      ],
    );
  }

  // ── Tenant count selector for Hostel / PG ──
  Widget _buildTenantSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            const Text(
              'Number of Tenants In A Room:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Outfit',
                color: AppTheme.textColor,
              ),
            ),
            ...List.generate(4, (index) {
              final count = index + 1;
              final isSelected = _selectedTenant == index;
              final avail = widget.availabilityBySharing[count];
              final isUnavailable = avail != null && avail == 0;

              return GestureDetector(
                onTap: () => _selectTenant(index),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isUnavailable
                            ? Colors.grey.shade200
                            : isSelected
                                ? AppTheme.primaryColor
                                : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isUnavailable
                              ? Colors.grey.shade300
                              : isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            color: isUnavailable
                                ? Colors.grey.shade400
                                : isSelected
                                    ? Colors.white
                                    : AppTheme.textColor,
                          ),
                        ),
                      ),
                    ),
                    // Availability dot badge
                    if (!isUnavailable && avail != null && avail <= 3)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF9800),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),

        // Availability status row
        if (_selectedTenant != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _AvailabilityStatus(
              count: _selectedTenant! + 1,
              availability: widget.availabilityBySharing,
            ).animate().fadeIn(duration: 200.ms),
          ),

        // Dynamic price hint
        if (_selectedTenant != null && widget.sharingPrices.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _PricingHint(
              selectedCount: _selectedTenant! + 1,
              sharingPrices: widget.sharingPrices,
            ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.2, end: 0),
          ),
      ],
    );
  }
}

// ── Apartment-specific badges: project status + category ──
class _ApartmentBadgeRow extends StatelessWidget {
  final String projectStatus;
  final String propertyCategory;

  const _ApartmentBadgeRow({
    required this.projectStatus,
    required this.propertyCategory,
  });

  @override
  Widget build(BuildContext context) {
    final statusBadge = _resolveStatus(projectStatus);
    final catBadge = _resolveCategory(propertyCategory);

    return Wrap(
      spacing: 8,
      children: [
        if (statusBadge != null)
          _Pill(label: statusBadge.$1, icon: statusBadge.$2, color: statusBadge.$3),
        if (catBadge != null)
          _Pill(label: catBadge.$1, icon: catBadge.$2),
      ],
    );
  }

  (String, IconData, Color)? _resolveStatus(String s) {
    final sl = s.toLowerCase();
    if (sl.contains('ready') || sl.contains('move')) {
      return ('Ready to Move', Icons.check_circle_outline, const Color(0xFF1ABC5C));
    }
    if (sl.contains('under') || sl.contains('construct')) {
      return ('Under Construction', Icons.construction_outlined, const Color(0xFFFF9800));
    }
    if (sl.contains('new') || sl.contains('launch')) {
      return ('New Launch', Icons.fiber_new_outlined, const Color(0xFF2196F3));
    }
    return null;
  }

  (String, IconData)? _resolveCategory(String c) {
    final cl = c.toLowerCase();
    if (cl.contains('gated') || cl.contains('community')) {
      return ('Gated Community', Icons.villa_outlined);
    }
    if (cl.contains('apartment') || cl.contains('flat')) {
      return ('Apartment', Icons.apartment_outlined);
    }
    if (cl.contains('studio')) return ('Studio', Icons.hotel_outlined);
    if (cl.isEmpty) return null;
    return (c, Icons.home_outlined);
  }
}

// ── BHK availability status line ──
class _BhkAvailabilityStatus extends StatelessWidget {
  final int index; // 0-based
  final Map<int, int> availability;

  const _BhkAvailabilityStatus({required this.index, required this.availability});

  @override
  Widget build(BuildContext context) {
    final avail = availability[index];
    if (avail == null) return const SizedBox.shrink();

    final (label, color) = avail == 0
        ? ('Not Available', const Color(0xFFE53935))
        : avail <= 2
            ? ('Only $avail unit${avail == 1 ? '' : 's'} left', const Color(0xFFFF9800))
            : ('$avail units available', const Color(0xFF1ABC5C));

    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Property type + gender badges (Hostel/PG) ──
class _BadgeRow extends StatelessWidget {
  final String propertyType;
  final String gender;

  const _BadgeRow({required this.propertyType, required this.gender});

  @override
  Widget build(BuildContext context) {
    final typeBadge = _resolveTypeBadge(propertyType);
    final genderBadge = _resolveGenderBadge(gender);

    return Wrap(
      spacing: 8,
      children: [
        if (typeBadge != null) _Pill(label: typeBadge.$1, icon: typeBadge.$2),
        if (genderBadge != null)
          _Pill(label: genderBadge.$1, icon: genderBadge.$2, color: genderBadge.$3),
      ],
    );
  }

  (String, IconData)? _resolveTypeBadge(String type) {
    final t = type.toLowerCase();
    if (t.contains('hostel')) return ('Hostel', Icons.school_outlined);
    if (t.contains('paying guest') || t.contains('pg')) {
      return ('PG', Icons.home_outlined);
    }
    return null;
  }

  (String, IconData, Color)? _resolveGenderBadge(String g) {
    final gl = g.toLowerCase();
    if (gl.contains('boy') || gl.contains('male') || gl.contains('men')) {
      return ('Boys Only', Icons.male, const Color(0xFF2196F3));
    }
    if (gl.contains('girl') || gl.contains('female') || gl.contains('women')) {
      return ('Girls Only', Icons.female, const Color(0xFFE91E8C));
    }
    if (gl.contains('unisex') || gl.contains('co-ed') || gl.contains('both')) {
      return ('Unisex', Icons.people_outline, const Color(0xFF9C27B0));
    }
    return null;
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _Pill({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Distance chip ──
class _DistanceChip extends StatelessWidget {
  final String label;

  const _DistanceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_walk_outlined,
              color: Colors.white.withValues(alpha: 0.85), size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Outfit',
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Availability status line ──
class _AvailabilityStatus extends StatelessWidget {
  final int count;
  final Map<int, int> availability;

  const _AvailabilityStatus({required this.count, required this.availability});

  @override
  Widget build(BuildContext context) {
    final avail = availability[count];
    if (avail == null) return const SizedBox.shrink();

    final (label, color) = avail == 0
        ? ('Not Available', const Color(0xFFE53935))
        : avail <= 2
            ? ('Only $avail room${avail == 1 ? '' : 's'} left', const Color(0xFFFF9800))
            : ('$avail rooms available', const Color(0xFF1ABC5C));

    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Rating row ──
class _RatingRow extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final int totalBeds;

  const _RatingRow({
    required this.rating,
    required this.reviewCount,
    required this.totalBeds,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 16),
            const SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (reviewCount > 0) ...[
          const SizedBox(width: 6),
          Text(
            '($reviewCount reviews)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontFamily: 'Outfit',
            ),
          ),
        ],
        if (totalBeds > 0) ...[
          const SizedBox(width: 12),
          Container(width: 1, height: 12, color: Colors.white.withValues(alpha: 0.35)),
          const SizedBox(width: 12),
          Row(
            children: [
              Icon(Icons.bed_outlined, color: Colors.white.withValues(alpha: 0.8), size: 14),
              const SizedBox(width: 4),
              Text(
                '$totalBeds beds available',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        ],
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1ABC5C).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFF1ABC5C).withValues(alpha: 0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_outlined, color: Color(0xFF1ABC5C), size: 12),
              SizedBox(width: 3),
              Text(
                'Verified',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1ABC5C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Pricing hint ──
class _PricingHint extends StatelessWidget {
  final int selectedCount;
  final Map<int, int> sharingPrices;

  const _PricingHint({required this.selectedCount, required this.sharingPrices});

  @override
  Widget build(BuildContext context) {
    final selectedPrice = sharingPrices[selectedCount] ?? 0;
    final allSame = sharingPrices.values.toSet().length == 1;
    if (allSame || selectedPrice == 0) return const SizedBox.shrink();

    final desc = switch (selectedCount) {
      1 => 'Private room — only you',
      2 => 'Shared with 1 other person',
      3 => 'Shared with 2 others',
      4 => 'Shared with 3 others',
      _ => '',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$desc · ₹$selectedPrice/month for this option',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Outfit',
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

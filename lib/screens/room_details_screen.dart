import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/room_details/amenities_section.dart';
import 'package:triangle_home/widgets/room_details/bottom_bar.dart';
import 'package:triangle_home/widgets/room_details/image_carousel.dart';
import 'package:triangle_home/widgets/room_details/owner_section.dart';
import 'package:triangle_home/widgets/room_details/room_info.dart';

class RoomDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> accommodation;

  const RoomDetailsScreen({super.key, required this.accommodation});

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  // For Hostel/PG
  int _selectedTenantCount = 0;
  // For Apartments — 0-based BHK index (0 = 1BHK, 1 = 2BHK, ...)
  int _selectedBhkIndex = 0;

  int _displayPrice = 0;
  int _displayArea = 0; // sq ft for selected BHK config
  final List<Map<String, String>> _tenantDetails = [];

  // ── Type helpers ──────────────────────────────────────────────────────────

  String _asString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return defaultValue;
  }

  int _asInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value.replaceAll(',', '')) ?? defaultValue;
    }
    return defaultValue;
  }

  List<String> _asStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) return [value];
    return [];
  }

  bool get _isApartment {
    final t =
        _asString(
          widget.accommodation['propertyType'] ?? widget.accommodation['type'],
        ).toLowerCase();
    return t.contains('apartment') || t.contains('flat');
  }

  // ── BHK config key helper ─────────────────────────────────────────────────

  static const _bhkLabels = ['1 BHK', '2 BHK', '3 BHK', '4 BHK'];

  String _bhkKey(int index) => _bhkLabels[index];

  // ── Pricing (Apartments: per BHK; Hostel/PG: per sharing) ────────────────

  /// Reads from pricingInfo['1 BHK'], ['2 BHK'], etc. Falls back to base price.
  int _priceForBhk(int index) {
    final pricingInfoRaw = widget.accommodation['pricingInfo'];
    final pricingInfo =
        pricingInfoRaw is Map<String, dynamic> ? pricingInfoRaw : null;
    if (pricingInfo != null) {
      final val = pricingInfo[_bhkKey(index)];
      if (val != null) return _asInt(val);
    }
    return _asInt(widget.accommodation['price']);
  }

  int _priceForSharing(int count) {
    final pricingInfoRaw = widget.accommodation['pricingInfo'];
    final pricingInfo =
        pricingInfoRaw is Map<String, dynamic> ? pricingInfoRaw : null;
    if (pricingInfo != null) {
      final val = pricingInfo['$count sharing'];
      if (val != null) return _asInt(val);
    }
    return _asInt(widget.accommodation['price']);
  }

  Map<int, int> get _sharingPrices {
    final map = <int, int>{};
    for (var i = 1; i <= 4; i++) {
      map[i] = _priceForSharing(i);
    }
    return map;
  }

  // ── Area per BHK config ───────────────────────────────────────────────────

  /// Reads from areaInfo['1 BHK'], ['2 BHK'], etc. Falls back to base area.
  int _areaForBhk(int index) {
    final areaInfoRaw = widget.accommodation['areaInfo'];
    final areaInfo = areaInfoRaw is Map<String, dynamic> ? areaInfoRaw : null;
    if (areaInfo != null) {
      final val = areaInfo[_bhkKey(index)];
      if (val != null) return _asInt(val);
    }
    return _asInt(
      widget.accommodation['area'] ?? widget.accommodation['carpetArea'],
    );
  }

  // ── Availability ──────────────────────────────────────────────────────────

  /// Per-BHK availability for apartments: {'1 BHK': N, '2 BHK': N, ...}
  Map<int, int> get _availabilityByBhk {
    final avMapRaw = widget.accommodation['availability'];
    final avMap = avMapRaw is Map<String, dynamic> ? avMapRaw : null;
    if (avMap == null) return {};
    final result = <int, int>{};
    for (var i = 0; i < 4; i++) {
      final val = avMap[_bhkKey(i)] ?? avMap['${i + 1} BHK'];
      if (val != null) result[i] = _asInt(val);
    }
    return result;
  }

  /// Per-sharing availability for Hostel/PG
  Map<int, int> get _availabilityBySharing {
    final avMapRaw = widget.accommodation['availability'];
    final avMap = avMapRaw is Map<String, dynamic> ? avMapRaw : null;
    if (avMap == null) return {};
    final result = <int, int>{};
    for (var i = 1; i <= 4; i++) {
      final val = avMap['$i sharing'] ?? avMap['$i'];
      if (val != null) result[i] = _asInt(val);
    }
    return result;
  }

  // ── BHK-specific key highlights data ─────────────────────────────────────

  /// Returns per-BHK property details map from Firestore field 'bhkDetails'
  /// e.g. { '1 BHK': { 'bedrooms': 1, 'bathrooms': 1, 'floor': '3rd', 'parking': true, ... } }
  Map<String, dynamic> get _bhkDetails {
    final bhkDetailsMapRaw = widget.accommodation['bhkDetails'];
    final bhkDetailsMap =
        bhkDetailsMapRaw is Map<String, dynamic> ? bhkDetailsMapRaw : null;
    if (bhkDetailsMap != null) {
      final key = _bhkKey(_selectedBhkIndex);
      final val = bhkDetailsMap[key];
      if (val is Map) return Map<String, dynamic>.from(val);
    }
    return {};
  }

  // ── Amenity categories ────────────────────────────────────────────────────

  Map<String, List<Map<String, dynamic>>> get _amenityCategories {
    final raw = widget.accommodation['amenityCategories'];
    if (raw == null || raw is! Map) return {};
    final result = <String, List<Map<String, dynamic>>>{};
    raw.forEach((k, v) {
      if (v is List) {
        result[k.toString()] =
            v
                .map<Map<String, dynamic>>((item) {
                  if (item is Map) {
                    return {
                      'label': _asString(item['label']),
                      'available':
                          (item['available'] is bool)
                              ? item['available'] as bool
                              : true,
                    };
                  }
                  return {'label': item.toString(), 'available': true};
                })
                .where((m) => (m['label'] as String).isNotEmpty)
                .toList();
      }
    });
    return result;
  }

  // ── Image tags ────────────────────────────────────────────────────────────

  List<String> _parseImageTags(dynamic tags) {
    if (tags == null) return [];
    if (tags is List) return tags.map((e) => e.toString()).toList();
    return [];
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _displayPrice =
        _isApartment ? _priceForBhk(0) : _asInt(widget.accommodation['price']);
    _displayArea = _isApartment ? _areaForBhk(0) : 0;
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────

  void _handleBhkSelection(int index) {
    setState(() {
      _selectedBhkIndex = index;
      _displayPrice = _priceForBhk(index);
      _displayArea = _areaForBhk(index);
      _selectedTenantCount = 1; // at least 1 tenant once BHK selected
      _tenantDetails
        ..clear()
        ..add({
          'name': 'Primary Tenant',
          'phone': 'Your registered phone',
          'email': 'Your registered email',
          'college': 'Your college',
        });
    });
  }

  void _handleTenantSelection(int count) {
    setState(() {
      _selectedTenantCount = count;
      _displayPrice = _priceForSharing(count);
      _tenantDetails
        ..clear()
        ..add({
          'name': 'Primary Tenant',
          'phone': 'Your registered phone',
          'email': 'Your registered email',
          'college': 'Your college',
        });
      for (var i = 1; i < count; i++) {
        _tenantDetails.add({
          'name': 'Tenant ${i + 1}',
          'phone': '',
          'email': '',
          'college': '',
        });
      }
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<String> _parseImageList(dynamic images) {
    if (images == null) return [];
    if (images is! List) return [];
    return images
        .map((e) => _asString(e))
        .where((e) => e.isNotEmpty)
        .take(10)
        .toList();
  }

  List<String> _parseAmenities(dynamic amenities) {
    if (amenities == null) return [];
    if (amenities is! List) return [];
    return amenities
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> _parseDistances(dynamic distances) => _asStringList(distances);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accommodation = widget.accommodation;
    final propertyType = _asString(
      accommodation['propertyType'] ?? accommodation['type'],
    );

    final imageList = _parseImageList(accommodation['images']);
    final fallbackImage = _asString(accommodation['image']);
    final displayImages =
        imageList.isNotEmpty
            ? imageList
            : (fallbackImage.isNotEmpty ? [fallbackImage] : <String>[]);

    final imageTags = _parseImageTags(accommodation['imageTags']);
    final distances = _parseDistances(accommodation['distances']);
    final gender = _asString(
      accommodation['gender'] ?? accommodation['genderAllowed'],
    );
    final projectStatus = _asString(
      accommodation['projectStatus'] ?? accommodation['status'],
    );
    final propertyCategory = _asString(
      accommodation['propertyCategory'] ?? accommodation['category'],
    );

    final ratingNum = accommodation['rating'];
    final rating = (ratingNum is num) ? ratingNum.toDouble() : 0.0;
    final reviewCountNum = accommodation['reviewCount'];
    final reviewCount = (reviewCountNum is num) ? reviewCountNum.toInt() : 0;
    final totalBeds = _asInt(accommodation['totalBeds']);
    final deposit = _asInt(
      accommodation['deposit'] ?? accommodation['initialDeposit'],
      defaultValue: _displayPrice > 0 ? _displayPrice + 1500 : 0,
    );
    final maintenanceCharge = _asInt(accommodation['maintenanceCharge']);
    final additionalCosts = _asInt(accommodation['additionalCosts']);

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImageCarousel(images: displayImages, imageTags: imageTags),
                RoomInfo(
                  name: _asString(accommodation['name']),
                  type: propertyType,
                  city: _asString(
                    accommodation['address'] ?? accommodation['city'],
                  ),
                  rating: rating,
                  reviewCount: reviewCount,
                  totalBeds: totalBeds,
                  sharingPrices: _sharingPrices,
                  availabilityBySharing: _availabilityBySharing,
                  availabilityByBhk: _availabilityByBhk,
                  selectedBhkIndex: _selectedBhkIndex,
                  bhkArea: _displayArea,
                  gender: gender,
                  projectStatus: projectStatus,
                  propertyCategory: propertyCategory,
                  distances: distances,
                  onTenantSelected: _handleTenantSelection,
                  onBhkSelected: _handleBhkSelection,
                ),
                AmenitiesSection(
                  amenities: _parseAmenities(accommodation['amenities']),
                  propertyType: propertyType,
                  amenityCategories: _amenityCategories,
                  bhkDetails: _bhkDetails,
                  propertyStatus: projectStatus,
                ),
                OwnerSection(
                  owner: _asString(
                    accommodation['wardenName'],
                    defaultValue: 'Property Owner',
                  ),
                  phone: _asString(accommodation['phone'], defaultValue: 'N/A'),
                ),
                const SizedBox(height: 180),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomBar(
              price:
                  _displayPrice > 0
                      ? _displayPrice
                      : _asInt(accommodation['price']),
              deposit: deposit,
              maintenanceCharge: maintenanceCharge,
              additionalCosts: additionalCosts,
              accommodation: accommodation,
              selectedTenantCount: _selectedTenantCount,
              tenantDetails: _tenantDetails,
              propertyType: propertyType,
            ),
          ),
        ],
      ),
    );
  }
}

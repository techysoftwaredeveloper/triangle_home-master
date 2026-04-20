import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triangle_home/screens/room_details_screen.dart';
import 'package:triangle_home/services/firebase_service.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;
  final String selectedCity;
  final String searchType;
  final List<String> selectedLocalities;
  final String selectedState;
  final String selectedCollege;
  final String accommodationType;
  final String tenantType;
  final String roomType;

  const SearchResultsScreen({
    super.key,
    required this.searchQuery,
    required this.selectedCity,
    required this.searchType,
    required this.selectedLocalities,
    required this.selectedState,
    this.selectedCollege = '',
    this.accommodationType = 'Paying Guest Hostels',
    this.tenantType = 'Anyone',
    this.roomType = 'Any',
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  String _sortBy = 'Price: Low to High';
  String _propertyType = 'All';
  String _priceRange = 'All';

  List<Map<String, dynamic>> _allResults = [];
  List<Map<String, dynamic>> _filteredResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSearchResults();
  }

  Future<void> _fetchSearchResults() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _firebaseService.getFilteredProperties(
        city: widget.selectedCity,
        localities: widget.selectedLocalities,
        college: widget.selectedCollege,
        accommodationType: widget.accommodationType,
        tenantType: widget.tenantType,
        roomType: widget.roomType,
      );

      setState(() {
        _allResults = results;
        _filteredResults = results;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      debugPrint('Error fetching search results: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allResults);

    // Apply property type filter
    if (_propertyType != 'All') {
      filtered =
          filtered.where((property) {
            final type =
                property['propertyType']?.toString().toLowerCase() ?? '';
            final category = 
                property['category']?.toString().toLowerCase() ?? '';
            switch (_propertyType) {
              case 'PG':
                return type.contains('pg') || type.contains('paying guest') || category.contains('pg');
              case 'Hostel':
                return type.contains('hostel') || category.contains('hostel');
              case 'Apartment':
                return type.contains('apartment') || type.contains('flat') || category.contains('apartment');
              default:
                return true;
            }
          }).toList();
    }

    // Apply price range filter
    if (_priceRange != 'All') {
      filtered =
          filtered.where((property) {
            final price = property['price'] as int? ?? 0;
            switch (_priceRange) {
              case '< ₹5000':
                return price < 5000;
              case '₹5000-₹10000':
                return price >= 5000 && price <= 10000;
              case '> ₹10000':
                return price > 10000;
              default:
                return true;
            }
          }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Price: Low to High':
        filtered.sort(
          (a, b) => (a['price'] as int).compareTo(b['price'] as int),
        );
        break;
      case 'Price: High to Low':
        filtered.sort(
          (a, b) => (b['price'] as int).compareTo(a['price'] as int),
        );
        break;
      case 'Rating':
        filtered.sort(
          (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
        );
        break;
      case 'Distance':
        // Keep original order for distance
        break;
    }

    setState(() {
      _filteredResults = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.searchQuery,
              style: const TextStyle(
                color: AppTheme.textOnPrimary,
                fontSize: AppTheme.fontMD,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            Text(
              '${_filteredResults.length} properties found in ${widget.selectedCity}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: AppTheme.fontSM,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildFilters(),
              Expanded(
                child:
                    _isLoading
                        ? _buildSkeletonLoader()
                        : _filteredResults.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: _filteredResults.length,
                          itemBuilder: (context, index) {
                            return _buildPropertyCard(_filteredResults[index])
                                .animate()
                                .fadeIn(delay: Duration(milliseconds: 100 * index))
                                .slideY(begin: 0.2, end: 0);
                          },
                        ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: _buildStickyFilterButton(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const HomeBottomNavBar(selectedIndex: 0),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No properties found',
            style: TextStyle(
              fontSize: AppTheme.fontLG,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLightColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _sortBy = 'Price: Low to High';
                _propertyType = 'All';
                _priceRange = 'All';
              });
              _applyFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Reset Filters',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton(
              'Sort By',
              _sortBy,
              [
                'Price: Low to High',
                'Price: High to Low',
                'Rating',
                'Distance',
              ],
              (value) {
                setState(() => _sortBy = value);
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              'Property Type',
              _propertyType,
              ['All', 'PG', 'Hostel', 'Apartment'],
              (value) {
                setState(() => _propertyType = value);
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              'Price Range',
              _priceRange,
              ['All', '< ₹5000', '₹5000-₹10000', '> ₹10000'],
              (value) {
                setState(() => _priceRange = value);
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder:
              (context) => _buildFilterSheet(label, value, options, onChanged),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: AppTheme.fontSM,
                  fontFamily: AppTheme.fontFamily,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSheet(
    String title,
    String selectedValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTheme.fontLG,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map(
            (option) => ListTile(
              title: Text(option),
              trailing:
                  option == selectedValue
                      ? const Icon(Icons.check, color: AppTheme.primaryColor)
                      : null,
              onTap: () {
                onChanged(option);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFilterButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAllFilters,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Manage Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAllFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _sortBy = 'Price: Low to High';
                        _propertyType = 'All';
                        _priceRange = 'All';
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterSection('Sort By', [
                    'Price: Low to High',
                    'Price: High to Low',
                    'Rating',
                    'Distance',
                  ], _sortBy, (v) => setState(() => _sortBy = v)),
                  const Divider(),
                  _buildFilterSection('Property Type', [
                    'All', 'PG', 'Hostel', 'Apartment'
                  ], _propertyType, (v) => setState(() => _propertyType = v)),
                  const Divider(),
                  _buildFilterSection('Price Range', [
                    'All', '< ₹5000', '₹5000-₹10000', '> ₹10000'
                  ], _priceRange, (v) => setState(() => _priceRange = v)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options, String selectedValue, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onSelect(option);
                }
              },
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 20, width: 150, color: Colors.grey[200]),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 250, color: Colors.grey[200]),
                  ],
                ),
              ),
            ],
          ).animate(onPlay: (controller) => controller.repeat())
           .shimmer(duration: 1500.ms, color: Colors.grey[100]),
        );
      },
    );
  }
  Widget _buildPropertyCard(Map<String, dynamic> property) {
    final user = FirebaseAuth.instance.currentUser;
    final propertyId = property['id'] as String? ?? '';
    final isUnavailable = property['booking_status'] == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: isUnavailable ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RoomDetailsScreen(accommodation: property),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: property['image'] ?? '',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                ),
                if (isUnavailable)
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BOOKING COMPLETED',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () async {
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please login to add to wishlist'),
                            ),
                          );
                          return;
                        }
                        try {
                          await _firebaseService.addToWishlist(
                            propertyId: propertyId,
                            propertyData: property,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to wishlist'),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error adding to wishlist: $e');
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${property['price']}/month',
                        style: TextStyle(
                          fontSize: AppTheme.fontXL,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTheme.fontFamily,
                          color: isUnavailable ? Colors.grey : AppTheme.textDarkColor,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: isUnavailable ? Colors.grey : Colors.amber[700], size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${property['rating'] ?? 4.0} (${property['reviewCount'] ?? 0})',
                            style: TextStyle(
                              fontSize: AppTheme.fontBase,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppTheme.fontFamily,
                              color: isUnavailable ? Colors.grey : AppTheme.textDarkColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property['title'] ?? 'Property',
                    style: TextStyle(
                      fontSize: AppTheme.fontMD,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                      color: isUnavailable ? Colors.grey : AppTheme.textDarkColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    property['location'] ?? '',
                    style: TextStyle(
                      color: isUnavailable ? Colors.grey[400] : AppTheme.textLightColor,
                      fontSize: AppTheme.fontBase,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: isUnavailable ? Colors.grey[400] : Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        property['distance'] ?? '',
                        style: TextStyle(
                          color: isUnavailable ? Colors.grey[400] : AppTheme.textLightColor,
                          fontSize: AppTheme.fontSM,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children:
                        (property['amenities'] as List<dynamic>? ?? [])
                            .take(4)
                            .map(
                              (amenity) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  amenity.toString(),
                                  style: TextStyle(
                                    color: isUnavailable ? Colors.grey[400] : AppTheme.textLightColor,
                                    fontSize: AppTheme.fontSM,
                                    fontFamily: AppTheme.fontFamily,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

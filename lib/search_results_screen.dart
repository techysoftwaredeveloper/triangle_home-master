import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/providers/service_providers.dart';
import 'package:triangle_home/widgets/home/premium_property_card.dart';
import 'package:triangle_home/providers/property_provider.dart';
import 'package:triangle_home/models/search_filter.dart';
import 'package:triangle_home/widgets/locality_search_popup.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/home/bottom_nav_bar.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
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
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  final ScrollController _scrollController = ScrollController();

  String _sortBy = 'Price: Low to High';
  String _propertyType = 'All';
  String _priceRange = 'All';
  List<String> _selectedLocalities = [];
  List<Map<String, dynamic>> _availableLocalities = [];

  @override
  void initState() {
    super.initState();
    _selectedLocalities = List.from(widget.selectedLocalities);
    
    // Set initial filters in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchFilterProvider.notifier).state = SearchFilter(
        city: widget.selectedCity,
        localities: widget.selectedLocalities,
        college: widget.selectedCollege,
        accommodationType: widget.accommodationType,
        tenantType: widget.tenantType,
        roomType: widget.roomType,
      );
    });

    _loadAvailableLocalities();
  }

  Future<void> _loadAvailableLocalities() async {
    if (widget.selectedCity.isEmpty) return;
    try {
      final service = ref.read(propertyServiceProvider);
      final localities =
          await service.getLocalities(widget.selectedCity);
      if (mounted) {
        setState(() {
          _availableLocalities = localities;
        });
      }
    } catch (e) {
      debugPrint('Error loading localities: $e');
    }
  }

  void _updatePriceRangeFilter(String value) {
    setState(() => _priceRange = value);
    
    double? minP, maxP;
    if (value != 'All') {
      final parts = value.split('-');
      if (parts.length == 2) {
        minP = double.tryParse(parts[0].replaceAll(RegExp(r'[^0-9]'), ''));
        maxP = double.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
      } else if (value.contains('<')) {
        maxP = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
      } else if (value.contains('>')) {
        minP = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
      }
    }

    ref.read(searchFilterProvider.notifier).update((s) => s.copyWith(
      minPrice: minP,
      maxPrice: maxP,
    ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyLocalFilters(List<Map<String, dynamic>> results) {
    List<Map<String, dynamic>> filtered = List.from(results);

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
                return type.contains('pg') ||
                    type.contains('paying guest') ||
                    category.contains('pg');
              case 'Hostel':
                return type.contains('hostel') || category.contains('hostel');
              case 'Apartment':
                return type.contains('apartment') ||
                    type.contains('flat') ||
                    category.contains('apartment');
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
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final streamAsync = ref.watch(filteredPropertiesStreamProvider);

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
            streamAsync.when(
              data: (results) => Text(
                '${_applyLocalFilters(results).length} properties found',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: AppTheme.fontSM,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              loading: () => const Text('Searching...', style: TextStyle(color: Colors.white70, fontSize: 10)),
              error: (_, __) => const Text('Error', style: TextStyle(color: Colors.red, fontSize: 10)),
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
                child: streamAsync.when(
                  data: (results) {
                    final filtered = _applyLocalFilters(results);
                    if (filtered.isEmpty) return _buildEmptyState();
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildPropertyCard(filtered[index])
                            .animate()
                            .fadeIn(delay: const Duration(milliseconds: 50))
                            .slideY(begin: 0.1, end: 0);
                      },
                    );
                  },
                  loading: () => _buildSkeletonLoader(),
                  error: (e, __) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(child: _buildStickyFilterButton()),
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
              ref.read(searchFilterProvider.notifier).update((s) => s.copyWith(
                minPrice: null,
                maxPrice: null,
              ));
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
                _updatePriceRangeFilter(value);
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
      builder:
          (context) => Container(
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
                          ref.read(searchFilterProvider.notifier).state = SearchFilter(
                            city: widget.selectedCity,
                            localities: widget.selectedLocalities,
                            college: widget.selectedCollege,
                            accommodationType: widget.accommodationType,
                            tenantType: widget.tenantType,
                            roomType: widget.roomType,
                          );
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
                      _buildFilterSection(
                        'Sort By',
                        [
                          'Price: Low to High',
                          'Price: High to Low',
                          'Rating',
                          'Distance',
                        ],
                        _sortBy,
                        (v) => setState(() => _sortBy = v),
                      ),
                      const Divider(),
                      _buildFilterSection(
                        'Property Type',
                        ['All', 'PG', 'Hostel', 'Apartment'],
                        _propertyType,
                        (v) => setState(() => _propertyType = v),
                      ),
                      const Divider(),
                      _buildFilterSection(
                        'Price Range',
                        ['All', '< ₹5000', '₹5000-₹10000', '> ₹10000'],
                        _priceRange,
                        (v) => setState(() => _priceRange = v),
                      ),
                      if (_availableLocalities.isNotEmpty) ...[
                        const Divider(),
                        _buildLocalityFilterSection(),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
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
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String selectedValue,
    Function(String) onSelect,
  ) {
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
          children:
              options.map((option) {
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

  Widget _buildLocalityFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Locality',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton(
              onPressed: _showLocalityPicker,
              child: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedLocalities.isEmpty)
          const Text(
            'All Localities',
            style: TextStyle(color: AppTheme.textLightColor, fontSize: 14),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _selectedLocalities.map((locality) {
                  return Chip(
                    label: Text(locality),
                    onDeleted: () {
                      setState(() {
                        _selectedLocalities.remove(locality);
                      });
                      ref.read(searchFilterProvider.notifier).update((s) => s.copyWith(
                        localities: _selectedLocalities,
                      ));
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    labelStyle: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showLocalityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => LocalitySearchPopup(
            localities: _availableLocalities,
            selectedLocalities: _selectedLocalities,
            onLocalityToggled: (locality) {
              setState(() {
                if (_selectedLocalities.contains(locality)) {
                  _selectedLocalities.remove(locality);
                } else if (_selectedLocalities.length < 5) {
                  _selectedLocalities.add(locality);
                }
              });
              ref.read(searchFilterProvider.notifier).update((s) => s.copyWith(
                localities: _selectedLocalities,
              ));
            },
          ),
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
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 20,
                          width: 150,
                          color: Colors.grey[200],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: 250,
                          color: Colors.grey[200],
                        ),
                      ],
                    ),
                  ),
                ],
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1500.ms, color: Colors.grey[100]),
        );
      },
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    return PremiumPropertyCard(property: property, width: double.infinity);
  }
}

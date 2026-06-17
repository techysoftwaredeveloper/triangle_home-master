import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/search_results_screen.dart';
import 'package:triangle_home/services/property_service.dart';
import 'package:triangle_home/providers/property_provider.dart';
import 'package:triangle_home/models/search_filter.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/locality_search_popup.dart';

class ApartmentSearchScreen extends ConsumerStatefulWidget {
  final bool isByArea;
  const ApartmentSearchScreen({super.key, this.isByArea = false});

  @override
  ConsumerState<ApartmentSearchScreen> createState() => _ApartmentSearchScreenState();
}

class _ApartmentSearchScreenState extends ConsumerState<ApartmentSearchScreen> {
  final PropertyService _propertyService = PropertyService();
  String _selectedCity = 'Kochi';
  String _selectedRoomType = 'Any';
  final List<String> _selectedLocalities = [];
  final TextEditingController _collegeSearchController =
      TextEditingController();

  List<String> _cities = [];
  List<Map<String, dynamic>> _localities = [];
  final List<String> _roomTypes = [
    'Any',
    '1 RK',
    '1 BHK',
    '2 BHK',
    '3 BHK',
    '4 BHK',
    '4+ BHK',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final cities = await _propertyService.getCities();
      setState(() {
        _cities = cities;
        if (cities.isNotEmpty) {
          _selectedCity = cities.first;
        }
      });
      if (_selectedCity.isNotEmpty) {
        _loadLocalities(_selectedCity);
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  Future<void> _loadLocalities(String city) async {
    try {
      final localities = await _propertyService.getLocalities(city);
      setState(() {
        _localities = localities;
        if (widget.isByArea) {
          _selectedLocalities.clear();
          _selectedLocalities.addAll(
            localities.take(2).map((l) => l['name'].toString()),
          );
        }
        _updateGlobalFilter();
      });
    } catch (e) {
      debugPrint('Error loading localities: $e');
    }
  }

  @override
  void dispose() {
    _collegeSearchController.dispose();
    super.dispose();
  }

  void _updateGlobalFilter() {
     ref.read(searchFilterProvider.notifier).state = SearchFilter(
        city: _selectedCity,
        localities: _selectedLocalities,
        college: !widget.isByArea ? _collegeSearchController.text : '',
        accommodationType: 'Apartments',
        roomType: _selectedRoomType,
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.isByArea
                    ? 'Search Apartments By Area'
                    : 'Search Apartments Near College/University',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainSearchCard(),
                  const SizedBox(height: 16),
                  _buildRoomTypeCard(),
                ],
              ),
            ),
          ),
          _buildSearchButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMainSearchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where are you planning to move into?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
              fontFamily: 'Outfit',
            ),
          ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          const SizedBox(height: 20),
          const Text(
            'Select City:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  _cities.map((city) {
                    final isSelected = city == _selectedCity;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCity = city;
                            _selectedLocalities.clear();
                            _loadLocalities(city);
                          });
                          _updateGlobalFilter();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppTheme.primaryColor
                                      : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            city,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                              fontFamily: 'Outfit',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          if (widget.isByArea) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Locality Filters:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    fontFamily: 'Outfit',
                  ),
                ),
                TextButton(
                  onPressed: _showLocalityPicker,
                  child: Text(
                    'Add More',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _selectedLocalities.isEmpty
                ? GestureDetector(
                    onTap: _showLocalityPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: const Text(
                        'Select Localities',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _selectedLocalities.map((locality) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  locality,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedLocalities.remove(locality);
                                    });
                                    _updateGlobalFilter();
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _collegeSearchController,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                      onChanged: (val) => _updateGlobalFilter(),
                      decoration: const InputDecoration(
                        hintText: 'Search for the name of your College',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                          fontFamily: 'Outfit',
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          ],
        ],
      ),
    );
  }

  Future<void> _showLocalityPicker() async {
    if (_localities.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No localities available')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => LocalitySearchPopup(
            localities: _localities,
            selectedLocalities: _selectedLocalities,
            onLocalityToggled: (locality) {
              setState(() {
                if (_selectedLocalities.contains(locality)) {
                  _selectedLocalities.remove(locality);
                } else if (_selectedLocalities.length < 5) {
                  _selectedLocalities.add(locality);
                }
              });
              _updateGlobalFilter();
            },
          ),
    );
  }

  Widget _buildRoomTypeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please select your room type:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate width for 4 columns with 12px spacing
              final itemWidth = (constraints.maxWidth - (3 * 12)) / 4;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    _roomTypes.map((type) {
                      final isSelected = _selectedRoomType == type;
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedRoomType = type);
                          _updateGlobalFilter();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: itemWidth,
                          height: 44, // Fixed height for a uniform box look
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppTheme.primaryColor.withValues(
                                      alpha: 0.08,
                                    )
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppTheme.primaryColor
                                      : const Color(0xFFE2E8F0),
                              width: isSelected ? 1 : 1,
                            ),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? AppTheme.primaryColor
                                      : const Color(0xFF64748B),
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                              fontFamily: 'Outfit',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSearchButton() {
    final streamAsync = ref.watch(filteredPropertiesStreamProvider);
    final isSearchDisabled = _selectedCity.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isSearchDisabled) 
            streamAsync.when(
              data: (results) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${results.length} properties matching your criteria',
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SizedBox(height: 2, width: 100, child: LinearProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => SearchResultsScreen(
                          searchQuery:
                              widget.isByArea
                                  ? _selectedLocalities.join(', ')
                                  : _collegeSearchController.text,
                          selectedCity: _selectedCity,
                          selectedState: '',
                          searchType: widget.isByArea ? 'By Area' : 'By College',
                          selectedLocalities: _selectedLocalities,
                          selectedCollege:
                              widget.isByArea ? '' : _collegeSearchController.text,
                          accommodationType: 'Apartments',
                          tenantType: 'Anyone',
                          roomType: _selectedRoomType,
                        ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Search',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Outfit',
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/search_results_screen.dart';
import 'package:triangle_home/services/property_service.dart';
import 'package:triangle_home/providers/property_provider.dart';
import 'package:triangle_home/models/search_filter.dart';
import 'package:triangle_home/widgets/locality_search_popup.dart';
import 'package:triangle_home/theme/app_theme.dart';

class AccommodationSearchScreen extends ConsumerStatefulWidget {
  const AccommodationSearchScreen({super.key});

  @override
  ConsumerState<AccommodationSearchScreen> createState() =>
      _AccommodationSearchScreenState();
}

class _AccommodationSearchScreenState extends ConsumerState<AccommodationSearchScreen> {
  final PropertyService _propertyService = PropertyService();
  List<String> _cities = [];
  String _selectedCity = '';

  String _searchType = 'By Area';
  List<String> _selectedLocalities = [];
  String _selectedSharing = '';
  List<String> _sharingOptions = [];

  @override
  void initState() {
    super.initState();
    _fetchCitiesFromFirestore();
    _fetchSharingTypes();
  }

  Future<void> _fetchCitiesFromFirestore() async {
    try {
      final cityList = await _propertyService.getCities();
      if (!mounted) return;

      if (cityList.isNotEmpty) {
        setState(() {
          _cities = cityList;
          _selectedCity = cityList.first;
        });
        _fetchAreasByCity();
      }
    } catch (e) {
      debugPrint('Error fetching cities: $e');
      if (mounted && e.toString().contains('permission-denied')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission denied by Firestore. Please check security rules.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _fetchAreasByCity() async {
    if (_selectedCity.isEmpty) return;

    try {
      final areas = await _propertyService.getLocalities(_selectedCity);
      if (mounted) {
        setState(() {
          _selectedLocalities =
              areas.take(2).map((a) => a['name'].toString()).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching areas: $e');
    }
  }

  Future<void> _fetchSharingTypes() async {
    try {
      final sharingList = await _propertyService.getSharingTypes();
      setState(() {
        _sharingOptions = sharingList;
      });
    } catch (e) {
      debugPrint('Error fetching sharing types: $e');
    }
  }

  void _updateGlobalFilter() {
     ref.read(searchFilterProvider.notifier).state = SearchFilter(
        city: _selectedCity,
        localities: _selectedLocalities,
        college: _searchType == 'By College' ? 'Near Colleges' : '',
        accommodationType: 'Paying Guest Hostels',
        roomType: _selectedSharing,
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search For Paying Guest Accommodations',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Select City:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildCitySelector(),
                  const SizedBox(height: 24),
                  _buildSearchTypeSelector(),
                  const SizedBox(height: 24),
                  _buildLocalityFilters(),
                  const SizedBox(height: 32),
                  Text(
                    'Room Sharing Type:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildSharingOptions(),
                ],
              ),
            ),
          ),
          _buildSearchButton(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCitySelector() {
    if (_cities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          _cities.map((city) {
            final isSelected = city == _selectedCity;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCity = city;
                  _selectedLocalities = [];
                });
                _fetchAreasByCity();
                _updateGlobalFilter();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8, // Increased for better tap area
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  city,
                  style: TextStyle(
                    fontSize: 12, // Increased for visibility
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSearchTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionButton(
            'By Area',
            _searchType == 'By Area',
            () {
              setState(() => _searchType = 'By Area');
              _updateGlobalFilter();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionButton(
            'By College',
            _searchType == 'By College',
            () {
              setState(() => _searchType = 'By College');
              _updateGlobalFilter();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalityFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Locality Filters:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            TextButton(
              onPressed: _showLocalityPicker,
              child: const Text(
                'Add More',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _selectedLocalities.map((locality) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        locality,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap:
                            () {
                              setState(
                                () => _selectedLocalities.remove(locality),
                              );
                              _updateGlobalFilter();
                            },
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Future<void> _showLocalityPicker() async {
    try {
      final options = await _propertyService.getLocalities(_selectedCity);
      if (options.isNotEmpty) {
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) {
            return LocalitySearchPopup(
              localities: options,
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
            );
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No localities found for this city')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error showing locality picker: $e');
    }
  }

  Widget _buildSharingOptions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          _sharingOptions.map((option) {
            final isSelected = _selectedSharing == option;
            return InkWell(
              onTap: () {
                setState(() => _selectedSharing = option);
                _updateGlobalFilter();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.1)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isSelected ? AppTheme.primaryColor : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSearchButton() {
    final streamAsync = ref.watch(filteredPropertiesStreamProvider);
    final isSearchDisabled = _selectedCity.isEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
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
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => SearchResultsScreen(
                          searchQuery:
                              _searchType == 'By Area'
                                  ? _selectedLocalities.join(', ')
                                  : 'Near Colleges',
                          selectedCity: _selectedCity,
                          selectedState: '',
                          searchType: _searchType,
                          selectedLocalities: _selectedLocalities,
                          accommodationType: 'Paying Guest Hostels',
                          roomType: _selectedSharing,
                        ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Search',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

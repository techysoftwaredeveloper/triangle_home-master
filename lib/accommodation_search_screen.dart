import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:triangle_home/search_results_screen.dart';
import 'package:triangle_home/services/property_service.dart';
import 'package:triangle_home/theme/app_theme.dart';

class AccommodationSearchScreen extends StatefulWidget {
  const AccommodationSearchScreen({super.key});

  @override
  State<AccommodationSearchScreen> createState() =>
      _AccommodationSearchScreenState();
}

class _AccommodationSearchScreenState extends State<AccommodationSearchScreen> {
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
      // First, find the document by city name (case-insensitive)
      final snapshot =
          await FirebaseFirestore.instance.collection('cities').get();

      String? docId;
      for (final doc in snapshot.docs) {
        final cityName = doc['name'].toString();
        if (cityName.toLowerCase() == _selectedCity.toLowerCase()) {
          docId = doc.id;
          break;
        }
      }

      if (docId != null) {
        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('cities')
                .doc(docId)
                .get();
        final data = docSnapshot.data();
        if (data != null && data['areas'] is List) {
          final areas = List<String>.from(data['areas']);
          setState(() {
            _selectedLocalities = areas.take(2).toList();
          });
        }
      } else {
        debugPrint('City "$_selectedCity" not found in Firestore.');
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
            () => setState(() => _searchType = 'By Area'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionButton(
            'By College',
            _searchType == 'By College',
            () => setState(() => _searchType = 'By College'),
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
                            () => setState(
                              () => _selectedLocalities.remove(locality),
                            ),
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
      // First, find the document by city name (case-insensitive)
      final snapshot =
          await FirebaseFirestore.instance.collection('cities').get();

      String? docId;
      for (final doc in snapshot.docs) {
        final cityName = doc['name'].toString();
        if (cityName.toLowerCase() == _selectedCity.toLowerCase()) {
          docId = doc.id;
          break;
        }
      }

      if (docId == null) {
        debugPrint('City "$_selectedCity" not found for locality picker.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No areas found for $_selectedCity')),
          );
        }
        return;
      }

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('cities')
              .doc(docId)
              .collection('areas')
              .get();

      final options = querySnapshot.docs.map((doc) => doc.id).toList();
      if (options.isNotEmpty) {
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return ListView(
              children:
                  options.map((locality) {
                    final alreadySelected = _selectedLocalities.contains(
                      locality,
                    );
                    return ListTile(
                      title: Text(locality),
                      trailing:
                          alreadySelected
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                      onTap: () {
                        setState(() {
                          if (!alreadySelected) {
                            _selectedLocalities.add(locality);
                          }
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            );
          },
        );
      } else {
        debugPrint('No areas found for city $_selectedCity');
      }
    } catch (e) {
      debugPrint('Error fetching areas for picker: $e');
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
              onTap: () => setState(() => _selectedSharing = option),
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
    return Container(
      padding: const EdgeInsets.all(16),
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
    );
  }
}

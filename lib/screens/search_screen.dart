import 'package:flutter/material.dart';
import 'package:triangle_home/search_results_screen.dart';
import 'package:triangle_home/services/firebase_service.dart';
import 'package:triangle_home/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  final String? initialSearchType;
  final String? initialAccommodationType;
  final String? initialTenantType;

  const SearchScreen({
    super.key,
    this.initialSearchType,
    this.initialAccommodationType,
    this.initialTenantType,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  List<String> _cities = [];
  List<String> _localities = [];
  List<String> _colleges = [];

  String _selectedCity = '';
  late String _selectedSearchType;
  final List<String> _selectedLocalities = [];
  String _selectedCollege = '';
  late String _selectedAccommodationType;
  late String _selectedTenantType;
  String _selectedRoomType = 'Any';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedSearchType = widget.initialSearchType ?? 'By Area';
    _selectedAccommodationType =
        widget.initialAccommodationType ?? 'Paying Guest Hostels';
    _selectedTenantType = widget.initialTenantType ?? 'Anyone';
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final cities = await _firebaseService.getCities();
      final colleges = await _firebaseService.getColleges();

      setState(() {
        _cities = cities;
        _colleges = colleges;
        if (cities.isNotEmpty) {
          _selectedCity = cities.first;
        }
        _isLoading = false;
      });

      if (_selectedCity.isNotEmpty) {
        _loadLocalities(_selectedCity);
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLocalities(String city) async {
    try {
      final localities = await _firebaseService.getLocalities(city);
      setState(() {
        _localities = localities;
      });
    } catch (e) {
      debugPrint('Error loading localities: $e');
    }
  }

  void _handleAddLocality() {
    if (_selectedSearchType == 'By College') {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder:
            (context) => _buildCollegeSelectionSheet(),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder:
            (context) => _buildLocalitySelectionSheet(),
      );
    }
  }

  Widget _buildLocalitySelectionSheet() {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder:
          (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Locality',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                          fontFamily: 'Outfit',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child:
                      _localities.isEmpty
                          ? const Center(child: Text('No localities available'))
                          : ListView.builder(
                            controller: controller,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _localities.length,
                            itemBuilder: (context, index) {
                              final locality = _localities[index];
                              final isSelected = _selectedLocalities.contains(
                                locality,
                              );

                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  title: Text(
                                    locality,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? AppTheme.primaryColor
                                              : const Color(0xFF334155),
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                  trailing:
                                      isSelected
                                          ? const Icon(
                                            Icons.check_circle,
                                            color: AppTheme.primaryColor,
                                          )
                                          : null,
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedLocalities.remove(locality);
                                      } else if (_selectedLocalities.length <
                                          5) {
                                        _selectedLocalities.add(locality);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'You can select up to 5 localities',
                                            ),
                                          ),
                                        );
                                      }
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildCollegeSelectionSheet() {
    String searchQuery = '';
    return StatefulBuilder(
      builder: (context, setModalState) {
        final filteredColleges =
            _colleges
                .where(
                  (c) => c.toLowerCase().contains(searchQuery.toLowerCase()),
                )
                .toList();

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder:
              (_, controller) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Search for Your College',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                              fontFamily: 'Outfit',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF64748B),
                              size: 22,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: TextField(
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Search for College Name',
                                hintStyle: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                  fontFamily: 'Outfit',
                                ),
                                suffixIcon: Icon(
                                  Icons.search,
                                  color: Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              onChanged: (value) {
                                setModalState(() {
                                  searchQuery = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (searchQuery.isNotEmpty) ...[
                            const Text(
                              'Search Results',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                                fontFamily: 'Outfit',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...filteredColleges.map(
                              (college) => _buildCollegeListTile(college),
                            ),
                          ] else ...[
                            const Text(
                              'Popular Institutions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                                fontFamily: 'Outfit',
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildPopularInstitutionsGrid(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  Widget _buildCollegeListTile(String college) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCollege = college;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                college,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155),
                  fontFamily: 'Outfit',
                ),
              ),
            ),
            const Icon(Icons.north_east, color: Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularInstitutionsGrid() {
    final popular = [
      {
        'name': 'Yenepoya University',
        'location': 'Mangaluru, Karnataka',
        'logo':
            'https://upload.wikimedia.org/wikipedia/en/2/2e/Yenepoya_University_Logo.png',
      },
      {
        'name': 'IIT Delhi',
        'location': 'New Delhi',
        'logo': 'https://home.iitd.ac.in/images/logo.png',
      },
      {
        'name': 'IIM Ahmedabad',
        'location': 'Ahmedabad, Gujarat',
        'logo': 'https://www.iima.ac.in/sites/default/files/iima-logo.png',
      },
      {
        'name': 'Madras Christian College',
        'location': 'Chennai, Tamil Nadu',
        'logo':
            'https://upload.wikimedia.org/wikipedia/en/0/0d/Madras_Christian_College_logo.png',
      },
      {
        'name': 'BITS Pilani',
        'location': 'Pilani, Rajasthan',
        'logo': 'https://www.bits-pilani.ac.in/wp-content/uploads/bits-logo.png',
      },
      {
        'name': 'Manipal Academy',
        'location': 'Manipal, Karnataka',
        'logo': 'https://manipal.edu/content/dam/manipal/mu/images/logo.png',
      },
      {
        'name': 'SRM University',
        'location': 'Chennai, Tamil Nadu',
        'logo': 'https://www.srmist.edu.in/wp-content/uploads/2021/01/logo.png',
      },
      {
        'name': 'Chandigarh University',
        'location': 'Mohali, Punjab',
        'logo':
            'https://www.cuchd.in/assets/images/chandigarh-university-logo.png',
      },
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 20,
      children:
          popular.map((inst) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 56) / 2,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCollege = inst['name']!;
                  });
                  Navigator.pop(context);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        inst['logo']!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, __, ___) => Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.school,
                                size: 20,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inst['name']!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                              fontFamily: 'Outfit',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            inst['location']!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                              fontFamily: 'Outfit',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  void _handleSearch() {
    if (_selectedCity.isEmpty ||
        (_selectedSearchType == 'By Area' && _selectedLocalities.isEmpty) ||
        (_selectedSearchType == 'By College' && _selectedCollege.isEmpty)) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SearchResultsScreen(
              searchQuery:
                  _selectedSearchType == 'By Area'
                      ? _selectedLocalities.join(", ")
                      : _selectedCollege,
              selectedCity: _selectedCity,
              selectedState: '',
              searchType: _selectedSearchType,
              selectedLocalities: _selectedLocalities,
              selectedCollege: _selectedCollege,
              accommodationType: _selectedAccommodationType,
              tenantType: _selectedTenantType,
              roomType: _selectedRoomType,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isSearchDisabled =
        _selectedCity.isEmpty ||
        (_selectedSearchType == 'By Area' && _selectedLocalities.isEmpty) ||
        (_selectedSearchType == 'By College' && _selectedCollege.isEmpty);

    return Scaffold(
      backgroundColor: Colors.white,
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
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Search For Paying Guest Accommodations',
                style: TextStyle(
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMainSearchCard(),
                          const SizedBox(height: 16),
                          if (_selectedSearchType == 'By Area')
                            _buildAdditionalPreferencesSection(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: isSearchDisabled ? null : _handleSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Search',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Outfit',
                color: isSearchDisabled ? Colors.black26 : Colors.white,
              ),
            ),
          ),
        ),
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
          ),
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
                          });
                          _loadLocalities(city);
                        },
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
          Row(
            children: [
              Expanded(
                child: _buildToggleTab(
                  'By Area',
                  _selectedSearchType == 'By Area',
                  () => setState(() => _selectedSearchType = 'By Area'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleTab(
                  'By College',
                  _selectedSearchType == 'By College',
                  () => setState(() => _selectedSearchType = 'By College'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_selectedSearchType == 'By Area') ...[
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
                  onPressed: _handleAddLocality,
                  child: const Text(
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _selectedLocalities.isEmpty
                      ? [
                        GestureDetector(
                          onTap: _handleAddLocality,
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
                        ),
                      ]
                      : _selectedLocalities.map((locality) {
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
            GestureDetector(
              onTap: _handleAddLocality,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCollege.isEmpty
                            ? 'Search for A College Name'
                            : _selectedCollege,
                        style: TextStyle(
                          color:
                              _selectedCollege.isEmpty
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF1E293B),
                          fontSize: 14,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.search,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleTab(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.05)
                  : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1 : 1,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.black54,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
              fontFamily: 'Outfit',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalPreferencesSection() {
    final isApartment = _selectedAccommodationType == 'Apartments';
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
            'Do you have any additional preferences?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 24),

          // Looking For
          const Text(
            'Looking For:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPreferenceButton(
                  'Paying Guest Hostels',
                  _selectedAccommodationType == 'Paying Guest Hostels',
                  () => setState(
                    () => _selectedAccommodationType = 'Paying Guest Hostels',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPreferenceButton(
                  'Apartments',
                  _selectedAccommodationType == 'Apartments',
                  () =>
                      setState(() => _selectedAccommodationType = 'Apartments'),
                ),
              ),
            ],
          ),

          // Tenant Type - Hidden if Apartments
          if (!isApartment) ...[
            const SizedBox(height: 24),
            const Text(
              'Tenant Type:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildPreferenceButton(
                        'Man',
                        _selectedTenantType == 'Man',
                        () => setState(() => _selectedTenantType = 'Man'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPreferenceButton(
                        'Woman',
                        _selectedTenantType == 'Woman',
                        () => setState(() => _selectedTenantType = 'Woman'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPreferenceButton(
                  'Anyone',
                  _selectedTenantType == 'Anyone',
                  () => setState(() => _selectedTenantType = 'Anyone'),
                ),
              ],
            ),
          ],

          // Room Type
          const SizedBox(height: 24),
          const Text(
            'Room Type:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final options =
                  isApartment
                      ? [
                        'Any',
                        '1 RK',
                        '1 BHK',
                        '2 BHK',
                        '3 BHK',
                        '4 BHK',
                        '4+ BHK',
                      ]
                      : [
                        'Any',
                        'Single',
                        '2 Sharing',
                        '3 Sharing',
                        '4 Sharing',
                      ];

              final crossAxisCount = isApartment ? 4 : 3;
              final itemWidth =
                  (constraints.maxWidth - ((crossAxisCount - 1) * 12)) /
                  crossAxisCount;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    options.map((type) {
                      final isSelected = _selectedRoomType == type;
                      return InkWell(
                        onTap: () => setState(() => _selectedRoomType = type),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: itemWidth,
                          height: 44,
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
    );
  }

  Widget _buildPreferenceButton(
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.05)
                  : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1 : 1,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.black54,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
              fontFamily: 'Outfit',
            ),
          ),
        ),
      ),
    );
  }
}

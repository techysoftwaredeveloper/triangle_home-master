import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/search_results_screen.dart';
import 'package:triangle_home/providers/property_provider.dart';
import 'package:triangle_home/providers/location_provider.dart';
import 'package:triangle_home/models/search_filter.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/college_search_popup.dart';
import 'package:triangle_home/screens/profile/help_support_screen.dart';

class CollegeSearchScreen extends ConsumerStatefulWidget {
  final String gender; // 'Men' or 'Women'

  const CollegeSearchScreen({super.key, required this.gender});

  @override
  ConsumerState<CollegeSearchScreen> createState() => _CollegeSearchScreenState();
}

class _CollegeSearchScreenState extends ConsumerState<CollegeSearchScreen> {
  String _selectedCollege = '';
  String _selectedSharing = 'Any';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid modifying provider during build/init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateGlobalFilter();
    });
  }

  void _updateGlobalFilter() {
    final selectedCity = ref.read(locationProvider).selectedCity;
    ref.read(searchFilterProvider.notifier).state = SearchFilter(
      city: selectedCity,
      college: _selectedCollege,
      accommodationType: 'Paying Guest Hostels',
      tenantType: widget.gender == 'Men' ? 'Man' : 'Woman',
      roomType: _selectedSharing,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        title: Text(
          'Search College Hostels For ${widget.gender}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppTheme.fontMD,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchInput(),
            const SizedBox(height: 16),
            _buildSharingTypeSection(),
            const SizedBox(height: 16),
            _buildHelpCard(),
            const SizedBox(height: 80),
            _buildSearchButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return GestureDetector(
      onTap: _showCollegeSelection,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedCollege.isEmpty
                    ? 'Search for the name of your College'
                    : _selectedCollege,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: AppTheme.fontBase,
                  color:
                      _selectedCollege.isEmpty
                          ? AppTheme.textMutedColor
                          : AppTheme.textColor,
                ),
              ),
            ),
            const Icon(
              Icons.search_rounded,
              color: AppTheme.textMutedColor,
              size: 28,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  void _showCollegeSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CollegeSearchPopup(
            colleges: const [
              'Yenepoya University',
              'Anna University',
              'St. Aloysius College',
              'Madras Christian College',
            ],
            onCollegeSelected: (college) {
              setState(() {
                _selectedCollege = college;
              });
              _updateGlobalFilter();
            },
          ),
    );
  }

  Widget _buildSharingTypeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please select your room sharing type:',
            style: TextStyle(
              fontSize: AppTheme.fontMD,
              fontWeight: FontWeight.w500,
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate width for 3 columns as per design image
              final itemWidth = (constraints.maxWidth - (2 * 12)) / 3;
              final options = [
                'Any',
                'Single',
                '2 Sharing',
                '3 Sharing',
                '4 Sharing',
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    options.map((label) {
                      final isSelected = _selectedSharing == label;
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedSharing = label);
                          // Use addPostFrameCallback or a microtask if this is somehow triggered during build
                          // though onTap is usually safe.
                          _updateGlobalFilter();
                        },
                        borderRadius: BorderRadius.circular(12),
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
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.dividerColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? AppTheme.primaryColor
                                      : const Color(0xFF64748B),
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
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
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHelpCard() {
    return GestureDetector(
      onTap: _showHelpDetails,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need Help With Hostel Fee Payments?',
                    style: TextStyle(
                      fontSize: AppTheme.fontMD,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.fontFamily,
                      color: AppTheme.textDarkColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We\'re here for you. Tap here to know more!',
                    style: TextStyle(
                      fontSize: AppTheme.fontSM,
                      color: AppTheme.textLightColor,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSearchButton() {
    final streamAsync = ref.watch(filteredPropertiesStreamProvider);
    final isEnabled = _selectedCollege.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEnabled)
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
              onPressed:
                  isEnabled
                      ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => SearchResultsScreen(
                                  searchQuery: _selectedCollege,
                                  selectedCity: ref.read(locationProvider).selectedCity,
                                  searchType: 'College',
                                  selectedLocalities: const [],
                                  selectedState: '',
                                  selectedCollege: _selectedCollege,
                                  tenantType:
                                      widget.gender == 'Men' ? 'Man' : 'Woman',
                                  roomType: _selectedSharing,
                                ),
                          ),
                        );
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isEnabled ? AppTheme.primaryColor : const Color(0xFFE5E5E5),
                foregroundColor: isEnabled ? Colors.white : AppTheme.textMutedColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Search',
                style: TextStyle(
                  fontSize: AppTheme.fontMD,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0);
  }

  void _showHelpDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.4,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Financial Assistance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Need help with hostel fee payments? We offer flexible payment plans and educational loans to support your stay. Contact our support team for more details.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppTheme.textLightColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                    child: const Text('Contact Support'),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

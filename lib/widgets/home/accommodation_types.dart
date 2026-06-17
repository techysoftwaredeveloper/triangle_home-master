import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:triangle_home/apartment_search_screen.dart';
import 'package:triangle_home/screens/college_search_screen.dart';
import 'package:triangle_home/screens/search_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';

class AccommodationTypes extends StatefulWidget {
  const AccommodationTypes({super.key});

  @override
  State<AccommodationTypes> createState() => _AccommodationTypesState();
}

class _AccommodationTypesState extends State<AccommodationTypes> {
  late PageController _pageController;
  int selectedIndex = 0;

  final List<String> tabs = [
    'College Hostels',
    'PG Accommodation',
    'Apartments',
  ];

  final List<List<Map<String, dynamic>>> content = [
    [
      {
        'title': 'College Hostels For Men',
        'icon': 'assets/images/Boyface.svg',
        'isCollege': true,
        'gender': 'Men',
      },
      {
        'title': 'College Hostels For Women',
        'icon': 'assets/images/Girlface.svg',
        'isCollege': true,
        'gender': 'Women',
      },
    ],
    [
      {
        'title': 'PG Accommodation for Men',
        'icon': 'assets/images/Boyface.svg',
        'searchType': 'By Area',
        'accommodationType': 'Paying Guest Hostels',
        'tenantType': 'Man',
      },
      {
        'title': 'PG Accommodation for Women',
        'icon': 'assets/images/Girlface.svg',
        'searchType': 'By Area',
        'accommodationType': 'Paying Guest Hostels',
        'tenantType': 'Woman',
      },
    ],
    [
      {
        'title': 'Near My College/University',
        'icon': 'assets/images/school.svg',
        'isApartment': true,
        'isByArea': false,
      },
      {
        'title': 'Around My City/Area',
        'icon': 'assets/images/home_work.svg',
        'isApartment': true,
        'isByArea': true,
      },
    ],
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (selectedIndex == index) return;
    
    setState(() => selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _onPageChanged(int index) {
    if (selectedIndex == index) return;
    setState(() => selectedIndex = index);
  }

  void _handleCardTap(Map<String, dynamic> params) {
    if (params['isCollege'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CollegeSearchScreen(gender: params['gender']),
        ),
      );
    } else if (params['isApartment'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApartmentSearchScreen(isByArea: params['isByArea']),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => SearchScreen(
                initialSearchType: params['searchType'],
                initialAccommodationType: params['accommodationType'],
                initialTenantType: params['tenantType'],
              ),
        ),
      );
    }
  }

  Widget _buildTab(String label, int index) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color.fromARGB(255, 255, 255, 255),
              fontSize: 11, // Slightly smaller to ensure fit
              fontFamily: AppTheme.fontFamily,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          // Consistent indicator container to prevent height/width jumps
          SizedBox(
            height: 2,
            width: double.infinity,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                width: isSelected ? 60 : 0,
                decoration: BoxDecoration(
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ] : null,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String title, String svgAssetPath, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 4,
          ),
          leading: SvgPicture.asset(svgAssetPath, height: 28, width: 28),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppTheme.fontSM,
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDarkColor,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.black45),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Using Row with Expanded children to lock positions
          Row(
            children: List.generate(tabs.length, (i) => Expanded(
              child: _buildTab(tabs[i], i),
            )),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 165, // Fits 2 cards perfectly
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: tabs.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, pageIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: content[pageIndex].map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTypeCard(
                          item['title'],
                          item['icon'],
                          () => _handleCardTap(item),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }
}

import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class CollegeSearchPopup extends StatefulWidget {
  final List<String> colleges;
  final Function(String) onCollegeSelected;

  const CollegeSearchPopup({
    super.key,
    required this.colleges,
    required this.onCollegeSelected,
  });

  @override
  State<CollegeSearchPopup> createState() => _CollegeSearchPopupState();
}

class _CollegeSearchPopupState extends State<CollegeSearchPopup> {
  String _searchQuery = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredColleges =
        widget.colleges
            .where((c) => c.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6, // Covers about 60% of screen to match image
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder:
          (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                // Header with title and close icon
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Search for Your College/Institution',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Outfit',
                          color: AppTheme.textDarkColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 24,
                          color: Colors.grey,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    children: [
                      // Search Bar inside popup
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _controller,
                          autofocus:
                              false, // Wait for manual click to show keyboard
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search for College Name',
                            hintStyle: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            suffixIcon: Icon(
                              Icons.search_rounded,
                              color: Color(0xFF94A3B8),
                              size: 24,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),

                      // Dynamic Search Results Section
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 32),
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
                        if (filteredColleges.isEmpty)
                          const Center(
                            child: Text(
                              'No institutions found matching your search.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ...filteredColleges.map(
                            (college) => _buildResultItem(college),
                          ),
                      ],

                      const SizedBox(height: 32),

                      // Popular Institutions Section
                      const Text(
                        'Our Popular Institutions',
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
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildResultItem(String college) {
    return InkWell(
      onTap: () {
        widget.onCollegeSelected(college);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 4,
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
                  fontFamily: 'Outfit',
                  color: AppTheme.textColor,
                ),
              ),
            ),
            const Icon(
              Icons.north_east_rounded,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
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
              width: (MediaQuery.of(context).size.width - 64) / 2,
              child: InkWell(
                onTap: () {
                  widget.onCollegeSelected(inst['name']!);
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
}

import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';

class LocalitySearchPopup extends StatefulWidget {
  final List<Map<String, dynamic>> localities;
  final List<String> selectedLocalities;
  final Function(String) onLocalityToggled;

  const LocalitySearchPopup({
    super.key,
    required this.localities,
    required this.selectedLocalities,
    required this.onLocalityToggled,
  });

  @override
  State<LocalitySearchPopup> createState() => _LocalitySearchPopupState();
}

class _LocalitySearchPopupState extends State<LocalitySearchPopup> {
  String _searchQuery = '';
  final TextEditingController _controller = TextEditingController();
  late List<String> _tempSelectedLocalities;

  @override
  void initState() {
    super.initState();
    _tempSelectedLocalities = List.from(widget.selectedLocalities);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLocalities =
        widget.localities
            .where((l) {
              final name = l['name']?.toString().toLowerCase() ?? '';
              final hub = l['hub']?.toString().toLowerCase() ?? '';
              final query = _searchQuery.toLowerCase();
              return name.contains(query) || hub.contains(query);
            })
            .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
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
                // Handle bar
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Locality',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                          color: AppTheme.textDarkColor,
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search for locality or area',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppTheme.primaryColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Content
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount:
                        filteredLocalities.isEmpty
                            ? 1
                            : filteredLocalities.length,
                    itemBuilder: (context, index) {
                      if (filteredLocalities.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Icon(
                                Icons.location_off_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No localities found',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final localityMap = filteredLocalities[index];
                      final locality = localityMap['name'] as String;
                      final hub = localityMap['hub'] as String?;
                      final type = localityMap['type'] as String? ?? 'General';
                      
                      final isSelected = _tempSelectedLocalities.contains(
                        locality,
                      );

                      IconData getIcon() {
                        if (type.toLowerCase().contains('college')) {
                          return Icons.school_rounded;
                        }
                        if (type.toLowerCase().contains('industrial') || 
                            type.toLowerCase().contains('hub') ||
                            type.toLowerCase().contains('park')) {
                          return Icons.business_rounded;
                        }
                        return Icons.location_on_rounded;
                      }

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _tempSelectedLocalities.remove(locality);
                            } else if (_tempSelectedLocalities.length < 5) {
                              _tempSelectedLocalities.add(locality);
                            }
                          });
                          widget.onLocalityToggled(locality);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFF1F5F9)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? AppTheme.primaryColor.withValues(
                                            alpha: 0.1,
                                          )
                                          : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  getIcon(),
                                  color:
                                      isSelected
                                          ? AppTheme.primaryColor
                                          : const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locality,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                        fontFamily: 'Outfit',
                                        color:
                                            isSelected
                                                ? AppTheme.primaryColor
                                                : AppTheme.textColor,
                                      ),
                                    ),
                                    if (hub != null)
                                      Text(
                                        'Near $hub',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                          fontFamily: 'Outfit',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 22,
                                )
                              else
                                const Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: Color(0xFFCBD5E1),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Action Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                          fontSize: 16,
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
}

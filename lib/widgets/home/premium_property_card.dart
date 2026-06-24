import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triangle_home/screens/property_detail_screen_v2.dart';
import 'package:triangle_home/models/property_stats_model.dart';
import 'package:triangle_home/theme/app_theme.dart';

class PremiumPropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final double width;

  const PremiumPropertyCard({
    super.key,
    required this.property,
    this.width = 320,
  });

  @override
  Widget build(BuildContext context) {
    final propertyId = property['id']?.toString() ?? '';
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('propertyStats').doc(propertyId).snapshots(),
      builder: (context, statsSnapshot) {
        final stats = statsSnapshot.hasData && statsSnapshot.data!.exists
            ? PropertyStatsModel.fromFirestore(statsSnapshot.data!)
            : null;

        final imageUrl = _getImageUrl();
        final bool hasValidImage = imageUrl.isNotEmpty && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailScreenV2(property: property),
              ),
            );
          },
          child: Container(
            width: width,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Image Section
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        children: [
                          !hasValidImage
                              ? Container(
                                  height: 240,
                                  color: Colors.grey[300],
                                  width: double.infinity,
                                  child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
                                )
                              : CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  height: 240,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: 240,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    height: 240,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
                                  ),
                                ),
                          // Dark Gradient Overlay
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.02),
                                    Colors.black.withValues(alpha: 0.4),
                                  ],
                                  stops: const [0.6, 0.8, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price Floating Badge (Top-Right)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${property['monthlyRent'] ?? property['price'] ?? '0'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const Text(
                              '/mo',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textLightColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Wishlist Button (Top-Left)
                    if (user != null)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: _WishlistButton(propertyId: propertyId, propertyData: property),
                      ),

                    // Bottom Badges (Verification & Gender)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Gender Badge
                              _GenderBadge(gender: property['gender'] ?? property['genderRestriction']),
                              const SizedBox(height: 6),
                              // Verification Badge
                              if (property['verification']?['isVerified'] == true || property['status'] == 'approved')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successGreen,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.verified, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'VERIFIED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          _AvailabilityBadge(stats: stats),
                        ],
                      ),
                    ),
                  ],
                ),

                // 2. Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (property['propertyType'] ?? property['type'] ?? 'PG').toString().toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (property['name'] ?? property['title'] ?? 'Unnamed Property').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: AppTheme.fontFamily,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _RatingDisplay(property: property),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppTheme.accentColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatLocation(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textLightColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Amenities (New Scrollable Design)
                      _AmenitiesList(amenities: property['amenities'] as List?),

                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppTheme.dividerColor),
                      const SizedBox(height: 20),

                      // Occupancy Stats
                      _OccupancyStats(stats: stats, propertyData: property),
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

  String _getImageUrl() {
    String url = '';
    if (property['image'] != null && property['image'].toString().isNotEmpty) {
      url = property['image'].toString();
    } else {
      final images = property['images'] as List?;
      if (images != null && images.isNotEmpty) {
        url = images[0].toString();
      } else {
        final imageUrls = property['image_urls'] as List?;
        if (imageUrls != null && imageUrls.isNotEmpty) {
          url = imageUrls[0].toString();
        }
      }
    }

    // Clean URL (remove whitespace, etc.)
    url = url.trim();

    // Basic validation
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      return '';
    }

    return url;
  }

  String _formatLocation() {
    final locality = (property['locality'] ?? '').toString();
    final city = (property['city'] ?? '').toString();
    if (locality.isNotEmpty && city.isNotEmpty) {
      return '$locality, $city';
    }
    return city.isNotEmpty ? city : (locality.isNotEmpty ? locality : 'Location N/A');
  }

  String _getDeposit() {
    final keys = [
      'deposit',
      'securityDeposit',
      'security_deposit',
      'baseDeposit',
      'depositAmount',
      'deposit_amount',
      'basicInfo.deposit',
      'basicInfo.securityDeposit',
    ];

    for (var key in keys) {
      if (key.contains('.')) {
        final parts = key.split('.');
        dynamic current = property;
        for (var part in parts) {
          if (current is Map && current.containsKey(part)) {
            current = current[part];
          } else {
            current = null;
            break;
          }
        }
        if (current != null && current.toString().isNotEmpty && current.toString() != '0') {
          return '₹${current.toString()}';
        }
      } else {
        if (property.containsKey(key) && property[key] != null && property[key].toString().isNotEmpty && property[key].toString() != '0') {
          return '₹${property[key].toString()}';
        }
      }
    }
    return '₹N/A';
  }
}

class _WishlistButton extends StatefulWidget {
  final String propertyId;
  final Map<String, dynamic> propertyData;

  const _WishlistButton({super.key, required this.propertyId, required this.propertyData});

  @override
  State<_WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<_WishlistButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(widget.propertyId)
          .snapshots(),
      builder: (context, snapshot) {
        final bool isFavorite = snapshot.hasData && snapshot.data!.exists;

        return GestureDetector(
          onTap: () async {
            _controller.forward(from: 0);
            final docRef = FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('wishlist')
                .doc(widget.propertyId);

            if (isFavorite) {
              await docRef.delete();
            } else {
              await docRef.set({
                'propertyId': widget.propertyId,
                'addedAt': FieldValue.serverTimestamp(),
                'propertyData': widget.propertyData,
              });
            }
          },
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : AppTheme.textLightColor,
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GenderBadge extends StatelessWidget {
  final dynamic gender;

  const _GenderBadge({required this.gender});

  @override
  Widget build(BuildContext context) {
    String label = (gender?.toString() ?? 'Anyone').toLowerCase();
    Color color = Colors.white;
    IconData icon = Icons.wc;

    if (label.contains('boy') || label.contains('men')) {
      label = 'Boys Only';
      color = Colors.blue;
      icon = Icons.male;
    } else if (label.contains('girl') || label.contains('women')) {
      label = 'Girls Only';
      color = Colors.pink;
      icon = Icons.female;
    } else {
      label = 'Unisex';
      color = Colors.orange;
      icon = Icons.wc;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final PropertyStatsModel? stats;

  const _AvailabilityBadge({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const SizedBox.shrink();
    }

    final int total = stats!.totalBeds;
    final int occupied = stats!.occupiedBeds;
    final int available = total - occupied;

    String label = 'Available Now';
    Color color = AppTheme.successGreen;

    if (available == 0) {
      label = 'Currently Full';
      color = AppTheme.errorColor;
    } else if (available <= 3) {
      label = 'Limited Availability';
      color = AppTheme.warningColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppTheme.textColor.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingDisplay extends StatelessWidget {
  final Map<String, dynamic> property;

  const _RatingDisplay({required this.property});

  @override
  Widget build(BuildContext context) {
    final double rating = (property['rating'] as num? ?? 0).toDouble();
    final int count = (property['reviewCount'] as num? ?? 0).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : 'New',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.amber,
            ),
          ),
          if (count > 0)
            Text(
              ' ($count)',
              style: TextStyle(
                color: Colors.amber.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _OccupancyStats extends StatelessWidget {
  final PropertyStatsModel? stats;
  final Map<String, dynamic> propertyData;

  const _OccupancyStats({required this.stats, required this.propertyData});

  @override
  Widget build(BuildContext context) {
    final int total = stats?.totalBeds ?? (propertyData['totalBeds'] as num? ?? propertyData['beds'] ?? 0).toInt();
    final int available = stats?.availableBeds ?? (total - (stats?.occupiedBeds ?? (propertyData['currentOccupancy'] as num? ?? 0).toInt()));
    
    // Use helper from parent if possible, but here we just re-implement briefly for the widget
    String deposit = 'N/A';
    final depKeys = ['deposit', 'securityDeposit', 'security_deposit', 'baseDeposit'];
    for (var k in depKeys) {
      if (propertyData[k] != null && propertyData[k].toString() != '0') {
        deposit = '₹${propertyData[k]}';
        break;
      }
    }

    return Row(
      children: [
        _buildStatItem(Icons.bed_outlined, 'Beds', total.toString(), Colors.blue),
        _buildVerticalDivider(),
        _buildStatItem(Icons.check_circle_outline, 'Left', available.toString(), AppTheme.successGreen),
        _buildVerticalDivider(),
        _buildStatItem(Icons.account_balance_wallet_outlined, 'Deposit', deposit, Colors.orange),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppTheme.dividerColor,
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMutedColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenitiesList extends StatelessWidget {
  final List? amenities;

  const _AmenitiesList({this.amenities});

  @override
  Widget build(BuildContext context) {
    if (amenities == null || amenities!.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: amenities!.length,
        itemBuilder: (context, index) {
          final amenity = amenities![index].toString();
          return _AmenityCircle(label: amenity);
        },
      ),
    );
  }
}

class _AmenityCircle extends StatelessWidget {
  final String label;

  const _AmenityCircle({required this.label});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.check;
    if (label == 'WiFi') icon = Icons.wifi;
    if (label == 'AC') icon = Icons.ac_unit;
    if (label == 'Food') icon = Icons.restaurant;
    if (label == 'Laundry') icon = Icons.local_laundry_service;
    if (label == 'Power Backup') icon = Icons.power;
    if (label == 'CCTV') icon = Icons.videocam;
    if (label == 'Water Purifier') icon = Icons.water_drop;

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBgColor,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.dividerColor, width: 0.5),
      ),
      child: Tooltip(
        message: label,
        child: Icon(icon, size: 18, color: AppTheme.primaryColor),
      ),
    );
  }
}


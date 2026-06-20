import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:triangle_home/theme/app_theme.dart';

class PropertyGallery extends StatefulWidget {
  final List<String> images;
  final Map<String, dynamic>? property;
  final Map<String, dynamic>? stats;

  const PropertyGallery({super.key, required this.images, this.property, this.stats});

  @override
  State<PropertyGallery> createState() => _PropertyGalleryState();
}

class _PropertyGalleryState extends State<PropertyGallery> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 240,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Dynamic height based on screen width but constrained
        double galleryHeight = (constraints.maxWidth * 0.6).clamp(220, 260);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: galleryHeight,
              child: PageView.builder(
                itemCount: widget.images.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  );
                },
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              child: _buildCircleButton(Icons.arrow_back, () => Navigator.pop(context)),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: Row(
                children: [
                  _buildCircleButton(Icons.favorite_border, () {}),
                  const SizedBox(width: 12),
                  _buildCircleButton(Icons.share, () {}),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (index) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (widget.property != null)
              Positioned(
                bottom: -30,
                left: 20,
                right: 20,
                child: _buildHeroInfoCard(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeroInfoCard() {
    final prop = widget.property!;
    final stats = widget.stats ?? {};
    
    final displayRating = stats['rating'] ?? prop['rating'] ?? 4.0;
    final availableBeds = stats['availableBeds'] ?? prop['availableBeds'] ?? prop['beds_available'] ?? '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  prop['title'] ?? prop['name'] ?? 'Property',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber[700], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$displayRating',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ' | ₹${prop['monthlyRent'] ?? prop['price'] ?? 'N/A'}/mo',
                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$availableBeds Beds Left',
              style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:triangle_home/theme/app_theme.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> images;
  /// Optional parallel list of labels for each image (Room, Bathroom, etc.)
  final List<String> imageTags;

  const ImageCarousel({
    super.key,
    required this.images,
    this.imageTags = const [],
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentIndex = 0;
  late final CarouselSliderController _controller;
  bool _isBookmarked = false;
  bool _swipeHintVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = CarouselSliderController();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _swipeHintVisible = false);
    });
  }

  String? _tagForIndex(int index) {
    if (widget.imageTags.isNotEmpty && index < widget.imageTags.length) {
      final t = widget.imageTags[index];
      return t.isNotEmpty ? t : null;
    }
    return null;
  }

  void _openFullScreen(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullScreenGallery(
          images: widget.images,
          imageTags: widget.imageTags,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // ── Main image with overlays ──
        Stack(
          children: [
            GestureDetector(
              onTap: () => _openFullScreen(_currentIndex),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CarouselSlider.builder(
                  carouselController: _controller,
                  options: CarouselOptions(
                    autoPlayCurve: Curves.easeInOut,
                    autoPlay: images.length > 1,
                    height: 260,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: false,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentIndex = index;
                        _swipeHintVisible = false;
                      });
                    },
                  ),
                  itemCount: images.isNotEmpty ? images.length : 1,
                  itemBuilder: (context, index, realIdx) {
                    if (images.isEmpty) {
                      return Container(
                        width: screenWidth,
                        height: 260,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 60, color: Colors.grey),
                      );
                    }
                    return CachedNetworkImage(
                      imageUrl: images[index],
                      key: ValueKey(images[index]),
                      fit: BoxFit.cover,
                      width: screenWidth,
                      height: 260,
                      placeholder: (context, url) => Container(
                        width: screenWidth,
                        height: 260,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: screenWidth,
                        height: 260,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Back button — top-left
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: SvgPicture.asset('assets/images/backicon.svg', width: 18, height: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ).animate().scale(),
            ),

            // Bookmark button — top-right
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked ? AppTheme.primaryColor : Colors.grey[700],
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isBookmarked = !_isBookmarked),
                ),
              ).animate().scale(),
            ),

            // Image tag label — bottom-left
            if (images.isNotEmpty && _tagForIndex(_currentIndex) != null)
              Positioned(
                bottom: images.length > 1 ? 36 : 12,
                left: 12,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    key: ValueKey(_tagForIndex(_currentIndex)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _tagForIndex(_currentIndex)!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            // Swipe hint
            if (images.length > 1 && _swipeHintVisible)
              Positioned(
                bottom: 36,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _swipeHintVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swipe_outlined, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Swipe to see more photos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Segmented dot indicator
            if (images.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: _SegmentedDots(total: images.length, current: _currentIndex),
                ),
              ),

            // Full-screen tap hint icon — top-right of image
            if (images.isNotEmpty)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56,
                right: 16,
                child: GestureDetector(
                  onTap: () => _openFullScreen(_currentIndex),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // ── Thumbnail strip ──
        if (images.length > 1)
          SizedBox(
            height: 66,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final isSelected = index == _currentIndex;
                final tag = _tagForIndex(index);
                return GestureDetector(
                  onTap: () => _controller.jumpToPage(index),
                  child: Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: images[index],
                            width: 72,
                            height: 54,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(width: 72, height: 54, color: Colors.grey[200]),
                            errorWidget: (context, url, error) =>
                                Container(width: 72, height: 54, color: Colors.grey[300]),
                          ),
                        ),
                      ),
                      // Selected overlay with index counter
                      if (isSelected)
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${_currentIndex + 1}/${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Tag label at bottom of thumbnail
                      if (tag != null && !isSelected)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 8,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(6),
                              bottomRight: Radius.circular(6),
                            ),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.5),
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                tag,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Full-screen gallery viewer ──
class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final List<String> imageTags;
  final int initialIndex;

  const _FullScreenGallery({
    required this.images,
    required this.imageTags,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _current;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String? _tag(int index) {
    if (widget.imageTags.isNotEmpty && index < widget.imageTags.length) {
      final t = widget.imageTags[index];
      return t.isNotEmpty ? t : null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipeable page view with pinch-zoom
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, color: Colors.grey, size: 60),
                  ),
                ),
              );
            },
          ),

          // Top bar: close + counter
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                  Text(
                    '${_current + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 36), // balance
                ],
              ),
            ),
          ),

          // Bottom tag label
          if (_tag(_current) != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    key: ValueKey(_tag(_current)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _tag(_current)!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Dot indicator
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 56,
            left: 0,
            right: 0,
            child: Center(
              child: _SegmentedDots(total: widget.images.length, current: _current),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Segmented dot indicator ──
class _SegmentedDots extends StatelessWidget {
  final int total;
  final int current;

  const _SegmentedDots({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    if (total > 8) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${current + 1}/$total',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

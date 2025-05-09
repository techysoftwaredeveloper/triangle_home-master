import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
//import 'package:carousel_slider/carousel_slider_controller.dart'; // ADD THIS

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({super.key});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final List<String> images = [
    'https://images.pexels.com/photos/271624/pexels-photo-271624.jpeg',
    'https://images.pexels.com/photos/271618/pexels-photo-271618.jpeg',
    'https://images.pexels.com/photos/1457842/pexels-photo-1457842.jpeg',
  ];

  int _currentIndex = 0;
  //final CarouselController _controller = CarouselController();
  late final CarouselSliderController _controller;

@override
void initState() {
  super.initState();
  _controller = CarouselSliderController();
}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: CarouselSlider.builder(
                carouselController: _controller,
                options: CarouselOptions(
                  autoPlay: true,
                  height: 300,
                  aspectRatio: 16 / 9,
                  viewportFraction: 1.5,
                  enableInfiniteScroll: false,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
                itemCount: images.length,
                itemBuilder: (context, index, realIdx) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Image.network(
                      images[index],
                      key: ValueKey(images[index]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                },
              ),
            ),

            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ).animate().scale(),
            ),

            // Wishlist button (Checkmark icon)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () {},
                ),
              ).animate().scale(),
            ),
          ],
        ),

        const SizedBox(height: 5),

        // Image counter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_currentIndex + 1}/${images.length}',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),

        const SizedBox(height: 10),

        // Thumbnail previews
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _controller.animateToPage(index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: index == _currentIndex ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      images[index],
                      width: 80,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

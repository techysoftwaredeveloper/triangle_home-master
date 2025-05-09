import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AccommodationSearch extends StatefulWidget {
  final List<String> items;
  final CarouselController controller;
  final int currentIndex;

  const AccommodationSearch({
    super.key,
    required this.items,
    required this.controller,
    required this.currentIndex,
  });

  @override
  State<AccommodationSearch> createState() => _AccommodationSearchState();
}

class _AccommodationSearchState extends State<AccommodationSearch> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CarouselSlider(
          //    carouselController: widget.controller,
              options: CarouselOptions(
                height: 40,
                viewportFraction: 1.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                scrollDirection: Axis.horizontal,
                onPageChanged: (index, reason) {
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
              items: widget.items.map((item) {
                return Builder(
                  builder: (BuildContext context) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate()
      .shimmer(delay: 2.seconds, duration: 1.seconds)
      .then(delay: 30.seconds);
  }
}
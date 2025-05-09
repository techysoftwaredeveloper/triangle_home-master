import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TopHostels extends StatelessWidget {
  final List<Map<String, String>> hostels;

  const TopHostels({
    super.key,
    required this.hostels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Highest Rated College Hostels of 2025',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily:  'outfit',
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: hostels.length,
            itemBuilder: (context, index) {
              final hostel = hostels[index];
              return Container(
                width: 300,
                height: 300,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(

                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      hostel['image']!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(hostel['name']! ,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily:  'outfit',
                  )),
                  subtitle: Text(hostel['location']! ,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    fontFamily:  'outfit',
                  )),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ).animate().fadeIn(delay: (600 + (index * 200)).ms);
            },
          ),
        ),
      ],
    );
  }
}
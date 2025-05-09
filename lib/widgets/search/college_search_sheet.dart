// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class CollegeSearchSheet extends StatelessWidget {
//   const CollegeSearchSheet({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       expand: false,
//       builder: (_, controller) => Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Search for Your College/Institution',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: TextField(
//                 decoration: InputDecoration(
//                   hintText: 'Search for College Name',
//                   prefixIcon: const Icon(Icons.search),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ).animate().fadeIn().slideY(begin: 0.2, end: 0),
//             ),
//             const SizedBox(height: 20),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Text(
//                 'Popular Institutions',
//                 style: Theme.of(context).textTheme.titleMedium,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Expanded(
//               child: ListView.builder(
//                 controller: controller,
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: 10,
//                 itemBuilder: (context, index) {
//                   return ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: Colors.grey[200],
//                       child: Text('${index + 1}'),
//                     ),
//                     title: Text('College ${index + 1}'),
//                     subtitle: Text('Location ${index + 1}'),
//                     onTap: () => Navigator.pop(context),
//                   ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class CollegeSearchSheet extends StatefulWidget {
  const CollegeSearchSheet({super.key});

  @override
  State<CollegeSearchSheet> createState() => _CollegeSearchSheetState();
}

class _CollegeSearchSheetState extends State<CollegeSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  String query = '';

  final colleges = [
    {
      'name': 'Yenepoya University',
      'location': 'Mangaluru, Karnataka',
      'image': 'https://demo3.chillipages.com/Yenepoya-2023/yenepoya-ayurveda-college/og.png',
    },
    {
      'name': 'Madras Christian College',
      'location': 'Chennai, Tamil Nadu',
      'image': 'https://demo3.chillipages.com/Yenepoya-2023/yenepoya-ayurveda-college/og.png',
    },
     {
      'name': 'Yenepoya University',
      'location': 'Mangaluru, Karnataka',
      'image': 'https://demo3.chillipages.com/Yenepoya-2023/yenepoya-ayurveda-college/og.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final searchResults = colleges
        .where((college) =>
            college['name']!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.only(top: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Search for Your College/Institution',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                onChanged: (val) => setState(() => query = val),
                decoration: InputDecoration(
                  hintText: 'Search for College Name',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Search Results
            if (query.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Search Results',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...searchResults.map((college) => ListTile(
                    leading: const Icon(Icons.circle, size: 12, color: Colors.indigo),
                    title: Text(
                      college['name']!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () {
                      Navigator.pop(context, college);
                    },
                  )),
              const Divider(),
            ],

            // Popular Institutions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Our Popular Institutions',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: colleges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 20),
                itemBuilder: (_, index) {
                  final college = colleges[index];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, college),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          college['image']!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          college['name']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          college['location']!,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

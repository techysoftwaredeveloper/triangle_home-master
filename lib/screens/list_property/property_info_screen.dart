// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:triangle_home/widgets/list_property/image_upload.dart';
// import 'package:triangle_home/widgets/list_property/toggle_buttons.dart';

// class PropertyInfoScreen extends StatefulWidget {
//   final VoidCallback onContinue;

//   const PropertyInfoScreen({super.key, required this.onContinue});

//   @override
//   State<PropertyInfoScreen> createState() => _PropertyInfoScreenState();
// }

// class _PropertyInfoScreenState extends State<PropertyInfoScreen> {
//   String _selectedAvailability = 'Men';
//   String _selectedSharing = '4 Sharing';
//   final List<String> _uploadedImages = [
//     'front-aadhaar_20260912.jpeg',
//     'back-aadhaar_20260912.jpeg',
//     'back-aadhaar_20260912.jpeg',
//     'back-aadhaar_20260912.jpeg',
//     'back-aadhaar_20260912.jpeg',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Property Information',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1E293B),
//             ),
//           ).animate().fadeIn().slideX(begin: -0.2, end: 0),
//           const SizedBox(height: 24),
//           const Text(
//             'Availability for:',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: Color(0xFF64748B),
//             ),
//           ),
//           const SizedBox(height: 8),
//           CustomToggleButtons(
//             options: const ['Men', 'Women'],
//             selectedOption: _selectedAvailability,
//             onOptionSelected: (value) => setState(() => _selectedAvailability = value),
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             'Type of sharing:',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: Color(0xFF64748B),
//             ),
//           ),
//           const SizedBox(height: 8),
//           CustomToggleButtons(
//             options: const ['Single', '2 Sharing', '3 Sharing', '4 Sharing'],
//             selectedOption: _selectedSharing,
//             onOptionSelected: (value) => setState(() => _selectedSharing = value),
//             wrap: true,
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             'Please upload images of the premises:',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: Color(0xFF64748B),
//             ),
//           ),
//           const SizedBox(height: 8),
//           ImageUploadWidget(
//             uploadedImages: _uploadedImages,
//             onImageRemoved: (index) {
//               setState(() {
//                 _uploadedImages.removeAt(index);
//               });
//             },
//             onRemoveAll: () {
//               setState(() {
//                 _uploadedImages.clear();
//               });
//             },
//           ),
//           const SizedBox(height: 24),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: widget.onContinue,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF1E3A8A),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: const Text(
//                 'Continue',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ).animate().fadeIn().slideY(begin: 0.2, end: 0),
//         ],
//       ),
//     );
//   }
// }
//--------------------------------------------------------------------------------

// import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path/path.dart';
// import 'package:triangle_home/widgets/list_property/toggle_buttons.dart';

// class PropertyInfoScreen extends StatefulWidget {
//   final VoidCallback onContinue;

//   const PropertyInfoScreen({super.key, required this.onContinue});

//   @override
//   State<PropertyInfoScreen> createState() => _PropertyInfoScreenState();
// }

// class _PropertyInfoScreenState extends State<PropertyInfoScreen> {
//   String _selectedAvailability = 'Men';
//   String _selectedSharing = '4 Sharing';
//   final List<File> _selectedImages = [];

//   Future<void> _pickImage(ImageSource source) async {
//     final pickedFile = await ImagePicker().pickImage(
//       source: source,
//       imageQuality: 80,
//     );
//     if (pickedFile != null) {
//       setState(() => _selectedImages.add(File(pickedFile.path)));
//     }
//   }

//   Future<void> _pickFromCloud() async {
//     final result = await FilePicker.platform.pickFiles(
//       allowMultiple: true,
//       type: FileType.image,
//     );
//     if (result != null) {
//       setState(() {
//         _selectedImages.addAll(result.paths.map((path) => File(path!)));
//       });
//     }
//   }

//   Future<List<String>> _uploadImagesToFirebase() async {
//     List<String> urls = [];
//     for (var file in _selectedImages) {
//       final fileName = basename(file.path);
//       final ref = FirebaseStorage.instance.ref('property_images/$fileName');
//       await ref.putFile(file);
//       final url = await ref.getDownloadURL();
//       urls.add(url);
//     }
//     return urls;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Property Information',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1E293B),
//             ),
//           ).animate().fadeIn().slideX(begin: -0.2, end: 0),
//           const SizedBox(height: 24),
//           const Text(
//             'Availability for:',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: Color(0xFF64748B),
//             ),
//           ),
//           const SizedBox(height: 8),
//           CustomToggleButtons(
//             options: const ['Men', 'Women'],
//             selectedOption: _selectedAvailability,
//             onOptionSelected:
//                 (value) => setState(() => _selectedAvailability = value),
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             'Type of sharing:',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: Color(0xFF64748B),
//             ),
//           ),
//           const SizedBox(height: 8),
//           CustomToggleButtons(
//             options: const ['Single', '2 Sharing', '3 Sharing', '4 Sharing'],
//             selectedOption: _selectedSharing,
//             onOptionSelected:
//                 (value) => setState(() => _selectedSharing = value),
//             wrap: true,
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             'Please upload images of the premises:',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: Color(0xFF64748B),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             children: [
//               ElevatedButton.icon(
//                 onPressed: () => _pickImage(ImageSource.camera),
//                 icon: const Icon(Icons.camera_alt),
//                 label: const Text("Camera"),
//               ),
//               ElevatedButton.icon(
//                 onPressed: () => _pickImage(ImageSource.gallery),
//                 icon: const Icon(Icons.photo),
//                 label: const Text("Gallery"),
//               ),
//               ElevatedButton.icon(
//                 onPressed: _pickFromCloud,
//                 icon: const Icon(Icons.cloud_upload),
//                 label: const Text("Cloud"),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Wrap(
//             spacing: 8,
//             children:
//                 _selectedImages.map((file) {
//                   return Stack(
//                     alignment: Alignment.topRight,
//                     children: [
//                       Image.file(
//                         file,
//                         width: 100,
//                         height: 100,
//                         fit: BoxFit.cover,
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.cancel, color: Colors.red),
//                         onPressed: () {
//                           setState(() => _selectedImages.remove(file));
//                         },
//                       ),
//                     ],
//                   );
//                 }).toList(),
//           ),
//           const SizedBox(height: 24),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: () async {
//                 final imageUrls = await _uploadImagesToFirebase();
//                 // You can pass `imageUrls`, `_selectedAvailability`, `_selectedSharing` back if needed
//                 widget.onContinue();
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF1E3A8A),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: const Text(
//                 'Continue',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//               ),
//             ),
//           ).animate().fadeIn().slideY(begin: 0.2, end: 0),
//         ],
//       ),
//     );
//   }
// }

//--------------------------------------------------------------------------------

// import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path/path.dart';
// import 'package:triangle_home/widgets/list_property/toggle_buttons.dart';

// class PropertyInfoScreen extends StatefulWidget {
//   final Function(Map<String, dynamic>) onContinue;

//   const PropertyInfoScreen({super.key, required this.onContinue});

//   @override
//   State<PropertyInfoScreen> createState() => _PropertyInfoScreenState();
// }

// class _PropertyInfoScreenState extends State<PropertyInfoScreen> {
//   String _selectedAvailability = 'Men';
//   String _selectedSharing = '4 Sharing';
//   final List<File> _selectedImages = [];

//   Future<void> _pickImage(ImageSource source) async {
//     final pickedFile = await ImagePicker().pickImage(
//       source: source,
//       imageQuality: 80,
//     );
//     if (pickedFile != null) {
//       setState(() => _selectedImages.add(File(pickedFile.path)));
//     }
//   }

//   Future<void> _pickFromCloud() async {
//     final result = await FilePicker.platform.pickFiles(
//       allowMultiple: true,
//       type: FileType.image,
//     );
//     if (result != null) {
//       setState(() {
//         _selectedImages.addAll(result.paths.map((path) => File(path!)));
//       });
//     }
//   }

//   Future<List<String>> _uploadImagesToFirebase() async {
//     List<String> urls = [];
//     for (var file in _selectedImages) {
//       final fileName = basename(file.path);
//       final ref = FirebaseStorage.instance.ref('property_images/$fileName');
//       await ref.putFile(file);
//       final url = await ref.getDownloadURL();
//       urls.add(url);
//     }
//     return urls;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Property Information',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1E293B),
//             ),
//           ).animate().fadeIn().slideX(begin: -0.2, end: 0),
//           const SizedBox(height: 24),
//           _buildSectionTitle('Availability for:'),
//           CustomToggleButtons(
//             options: const ['Men', 'Women'],
//             selectedOption: _selectedAvailability,
//             onOptionSelected:
//                 (value) => setState(() => _selectedAvailability = value),
//           ),
//           const SizedBox(height: 24),
//           _buildSectionTitle('Type of sharing:'),
//           CustomToggleButtons(
//             options: const ['Single', '2 Sharing', '3 Sharing', '4 Sharing'],
//             selectedOption: _selectedSharing,
//             onOptionSelected:
//                 (value) => setState(() => _selectedSharing = value),
//             wrap: true,
//           ),
//           const SizedBox(height: 24),
//           _buildSectionTitle('Please upload images of the premises:'),
//           Wrap(
//             spacing: 8,
//             children: [
//               ElevatedButton.icon(
//                 onPressed: () => _pickImage(ImageSource.camera),
//                 icon: const Icon(Icons.camera_alt),
//                 label: const Text("Camera"),
//               ),
//               ElevatedButton.icon(
//                 onPressed: () => _pickImage(ImageSource.gallery),
//                 icon: const Icon(Icons.photo),
//                 label: const Text("Gallery"),
//               ),
//               ElevatedButton.icon(
//                 onPressed: _pickFromCloud,
//                 icon: const Icon(Icons.cloud_upload),
//                 label: const Text("Cloud"),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Wrap(
//             spacing: 8,
//             children:
//                 _selectedImages.map((file) {
//                   return Stack(
//                     alignment: Alignment.topRight,
//                     children: [
//                       Image.file(
//                         file,
//                         width: 100,
//                         height: 100,
//                         fit: BoxFit.cover,
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.cancel, color: Colors.red),
//                         onPressed:
//                             () => setState(() => _selectedImages.remove(file)),
//                       ),
//                     ],
//                   );
//                 }).toList(),
//           ),
//           const SizedBox(height: 24),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: () async {
//                 final imageUrls = await _uploadImagesToFirebase();
//                 widget.onContinue({
//                   'availability': _selectedAvailability,
//                   'sharing': _selectedSharing,
//                   'images': imageUrls,
//                 });
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF1E3A8A),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: const Text(
//                 'Continue',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//               ),
//             ),
//           ).animate().fadeIn().slideY(begin: 0.2, end: 0),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: Color(0xFF64748B),
//           ),
//         ),
//         const SizedBox(height: 8),
//       ],
//     );
//   }
// }

// lib/screens/list_property/property_info_screen.dart

// import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path/path.dart';
// import 'package:triangle_home/widgets/list_property/toggle_buttons.dart';

// class PropertyInfoScreen extends StatefulWidget {
//   final Function(Map<String, dynamic>) onContinue;

//   const PropertyInfoScreen({super.key, required this.onContinue});

//   @override
//   State<PropertyInfoScreen> createState() => _PropertyInfoScreenState();
// }

// class _PropertyInfoScreenState extends State<PropertyInfoScreen> {
//   String _selectedAvailability = 'Men';
//   String _selectedSharing = 'Single';
//   final List<File> _selectedImages = [];
//   final Map<String, bool> _features = {
//     'Air Conditioning': false,
//     'Washing Machine': false,
//     'WiFi': false,
//     'TV': false,
//     'Refrigerator': false,
//     'Geyser': false,
//     'Power Backup': false,
//     'Parking': false,
//     'Security': false,
//     'CCTV': false,
//     'Food': false,
//     'Housekeeping': false,
//   };
//   bool _isUploading = false;

//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final pickedFile = await ImagePicker().pickImage(
//         source: source,
//         imageQuality: 80,
//       );
//       if (pickedFile != null) {
//         setState(() => _selectedImages.add(File(pickedFile.path)));
//       }
//     } catch (e) {
//       _showErrorSnackbar('Error picking image: $e');
//     }
//   }

//   Future<void> _pickFromCloud() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         allowMultiple: true,
//         type: FileType.image,
//       );
//       if (result != null) {
//         setState(() {
//           _selectedImages.addAll(result.paths.map((path) => File(path!)));
//         });
//       }
//     } catch (e) {
//       _showErrorSnackbar('Error picking images: $e');
//     }
//   }

//   Future<List<String>> _uploadImagesToFirebase() async {
//     List<String> urls = [];
//     try {
//       for (var file in _selectedImages) {
//         final fileName = basename(file.path);
//         final ref = FirebaseStorage.instance.ref('property_images/$fileName');
//         await ref.putFile(file);
//         final url = await ref.getDownloadURL();
//         urls.add(url);
//       }
//     } catch (e) {
//       _showErrorSnackbar('Error uploading images: $e');
//     }
//     return urls;
//   }

//   void _showErrorSnackbar(String message) {
//     ScaffoldMessenger.of(context as BuildContext).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   bool _validateForm() {
//     if (_selectedImages.isEmpty) {
//       _showErrorSnackbar('Please select at least one image');
//       return false;
//     }

//     final selectedFeatures = _features.entries.where((e) => e.value).length;
//     if (selectedFeatures == 0) {
//       _showErrorSnackbar('Please select at least one feature');
//       return false;
//     }

//     return true;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Property Information',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF1E293B),
//             ),
//           ).animate().fadeIn().slideX(begin: -0.2, end: 0),
//           const SizedBox(height: 24),
//           _buildSectionTitle('Availability for:'),
//           CustomToggleButtons(
//             options: const ['Men', 'Women'],
//             selectedOption: _selectedAvailability,
//             onOptionSelected: (value) => setState(() => _selectedAvailability = value),
//           ),
//           const SizedBox(height: 24),
//           _buildSectionTitle('Type of sharing:'),
//           CustomToggleButtons(
//             options: const ['Single', '2 Sharing', '3 Sharing', '4 Sharing'],
//             selectedOption: _selectedSharing,
//             onOptionSelected: (value) => setState(() => _selectedSharing = value),
//             wrap: true,
//           ),
//           const SizedBox(height: 24),
//           _buildSectionTitle('Features Available:'),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: _features.entries.map((entry) {
//               return FilterChip(
//                 label: Text(entry.key),
//                 selected: entry.value,
//                 onSelected: (bool selected) {
//                   setState(() => _features[entry.key] = selected);
//                 },
//                 selectedColor: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
//                 checkmarkColor: const Color(0xFF1E3A8A),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 24),
//           _buildSectionTitle('Please upload images of the premises:'),
//           Wrap(
//             spacing: 8,
//             children: [
//               ElevatedButton.icon(
//                 onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
//                 icon: const Icon(Icons.camera_alt),
//                 label: const Text("Camera"),
//               ),
//               ElevatedButton.icon(
//                 onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
//                 icon: const Icon(Icons.photo),
//                 label: const Text("Gallery"),
//               ),
//               ElevatedButton.icon(
//                 onPressed: _isUploading ? null : _pickFromCloud,
//                 icon: const Icon(Icons.cloud_upload),
//                 label: const Text("Cloud"),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           if (_selectedImages.isNotEmpty)
//             Wrap(
//               spacing: 8,
//               children: _selectedImages.map((file) {
//                 return Stack(
//                   alignment: Alignment.topRight,
//                   children: [
//                     Image.file(
//                       file,
//                       width: 100,
//                       height: 100,
//                       fit: BoxFit.cover,
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.cancel, color: Colors.red),
//                       onPressed: _isUploading ? null : () => setState(() => _selectedImages.remove(file)),
//                     ),
//                   ],
//                 );
//               }).toList(),
//             ),
//           const SizedBox(height: 24),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _isUploading
//                   ? null
//                   : () async {
//                       if (!_validateForm()) return;

//                       setState(() => _isUploading = true);
//                       try {
//                         final imageUrls = await _uploadImagesToFirebase();
//                         if (mounted) {
//                           widget.onContinue({
//                             'availability': _selectedAvailability,
//                             'sharing': _selectedSharing,
//                             'features': _features.entries
//                                 .where((e) => e.value)
//                                 .map((e) => e.key)
//                                 .toList(),
//                             'images': imageUrls,
//                           });
//                         }
//                       } finally {
//                         setState(() => _isUploading = false);
//                       }
//                     },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF1E3A8A),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: _isUploading
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text(
//                       'Continue',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                     ),
//             ),
//           ).animate().fadeIn().slideY(begin: 0.2, end: 0),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: Color(0xFF64748B),
//           ),
//         ),
//         const SizedBox(height: 8),
//       ],
//     );
//   }
// }

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:uuid/uuid.dart';
import 'package:triangle_home/widgets/list_property/toggle_buttons.dart';

class PropertyInfoScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;

  const PropertyInfoScreen({super.key, required this.onContinue});

  @override
  State<PropertyInfoScreen> createState() => _PropertyInfoScreenState();
}

class _PropertyInfoScreenState extends State<PropertyInfoScreen> {
  String _selectedAvailability = 'Men';
  String _selectedSharing = 'Single';
  final List<File> _selectedImages = [];
  final Map<String, bool> _features = {
    'Air Conditioning': false,
    'Washing Machine': false,
    'WiFi': false,
    'TV': false,
    'Refrigerator': false,
    'Geyser': false,
    'Power Backup': false,
    'Parking': false,
    'Security': false,
    'CCTV': false,
    'Food': false,
    'Housekeeping': false,
  };
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 10) {
      _showErrorSnackbar('Maximum 10 images allowed');
      return;
    }
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() => _selectedImages.add(File(pickedFile.path)));
      }
    } catch (e) {
      _showErrorSnackbar('Error picking image: $e');
    }
  }

  Future<void> _pickFromCloud() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );
      if (result != null) {
        final files = result.paths.map((path) => File(path!));
        if (_selectedImages.length + files.length > 10) {
          _showErrorSnackbar('Maximum 10 images allowed');
        } else {
          setState(() => _selectedImages.addAll(files));
        }
      }
    } catch (e) {
      _showErrorSnackbar('Error picking images: $e');
    }
  }

  Future<List<String>> _uploadImagesToFirebase() async {
    List<String> urls = [];
    try {
      for (var file in _selectedImages) {
        final fileName = '${const Uuid().v4()}_${basename(file.path)}';
        final ref = FirebaseStorage.instance.ref('property_images/$fileName');
        final uploadTask = ref.putFile(file);
        await uploadTask;
        final url = await ref.getDownloadURL();
        urls.add(url);
      }
    } catch (e) {
      _showErrorSnackbar('Error uploading images: $e');
    }
    return urls;
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      (context as BuildContext),
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateForm() {
    if (_selectedImages.isEmpty) {
      _showErrorSnackbar('Please select at least one image');
      return false;
    }
    if (_features.values.every((v) => v == false)) {
      _showErrorSnackbar('Please select at least one feature');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ).animate().fadeIn().slideX(begin: -0.2, end: 0),
          const SizedBox(height: 24),

          _buildSectionTitle('Availability for:'),
          CustomToggleButtons(
            options: const ['Men', 'Women'],
            selectedOption: _selectedAvailability,
            onOptionSelected:
                (value) => setState(() => _selectedAvailability = value),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Type of sharing:'),
          CustomToggleButtons(
            options: const ['Single', '2 Sharing', '3 Sharing', '4 Sharing'],
            selectedOption: _selectedSharing,
            onOptionSelected:
                (value) => setState(() => _selectedSharing = value),
            wrap: true,
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Features Available:'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _features.entries.map((entry) {
                  return FilterChip(
                    label: Text(entry.key),
                    selected: entry.value,
                    onSelected:
                        (bool selected) =>
                            setState(() => _features[entry.key] = selected),
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  );
                }).toList(),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Please upload images of the premises:'),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed:
                    _isUploading ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text("Camera"),
              ),
              ElevatedButton.icon(
                onPressed:
                    _isUploading ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo),
                label: const Text("Gallery"),
              ),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickFromCloud,
                icon: const Icon(Icons.cloud_upload),
                label: const Text("Cloud"),
              ),
            ],
          ),

          const SizedBox(height: 12),
          if (_selectedImages.isNotEmpty)
            Wrap(
              spacing: 8,
              children:
                  _selectedImages.map((file) {
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.file(
                          file,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: AppTheme.primaryColor),
                          onPressed:
                              _isUploading
                                  ? null
                                  : () => setState(
                                    () => _selectedImages.remove(file),
                                  ),
                        ),
                      ],
                    );
                  }).toList(),
            ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _isUploading
                      ? null
                      : () async {
                        if (!_validateForm()) return;

                        setState(() => _isUploading = true);
                        try {
                          final imageUrls = await _uploadImagesToFirebase();
                          if (mounted) {
                            widget.onContinue({
                              'availability': _selectedAvailability,
                              'sharing': _selectedSharing,
                              'features':
                                  _features.entries
                                      .where((e) => e.value)
                                      .map((e) => e.key)
                                      .toList(),
                              'images': imageUrls,
                            });
                          }
                        } finally {
                          setState(() => _isUploading = false);
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}


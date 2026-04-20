// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:image_picker/image_picker.dart';

// class EditProfileScreen extends StatefulWidget {
//   const EditProfileScreen({super.key});

//   @override
//   State<EditProfileScreen> createState() => _EditProfileScreenState();
// }

// class _EditProfileScreenState extends State<EditProfileScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController(text: 'John Doe');
//   final _emailController = TextEditingController(text: 'john.doe@example.com');
//   final _phoneController = TextEditingController(text: '+91 98765 43210');
//   String? _profileImage;

//   Future<void> _pickImage() async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? image = await picker.pickImage(source: ImageSource.gallery);

//     if (image != null) {
//       setState(() {
//         _profileImage = image.path;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Edit Profile'),
//         backgroundColor: const Color(0xFF1E3A8A),
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               Stack(
//                 alignment: Alignment.bottomRight,
//                 children: [
//                   CircleAvatar(
//                     radius: 50,
//                     backgroundImage: _profileImage != null
//                         ? AssetImage(_profileImage!) as ImageProvider
//                         : const NetworkImage('https://i.pravatar.cc/300'),
//                   ),
//                   CircleAvatar(
//                     radius: 18,
//                     backgroundColor: const Color(0xFF1E3A8A),
//                     child: IconButton(
//                       icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
//                       onPressed: _pickImage,
//                     ),
//                   ),
//                 ],
//               ).animate().scale(),
//               const SizedBox(height: 24),
//               TextFormField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(
//                   labelText: 'Full Name',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value?.isEmpty ?? true) {
//                     return 'Please enter your name';
//                   }
//                   return null;
//                 },
//               ).animate().fadeIn().slideX(),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value?.isEmpty ?? true) {
//                     return 'Please enter your email';
//                   }
//                   return null;
//                 },
//               ).animate().fadeIn().slideX(),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _phoneController,
//                 decoration: const InputDecoration(
//                   labelText: 'Phone Number',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value?.isEmpty ?? true) {
//                     return 'Please enter your phone number';
//                   }
//                   return null;
//                 },
//               ).animate().fadeIn().slideX(),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     if (_formKey.currentState?.validate() ?? false) {
//                       // Save profile changes
//                       Navigator.pop(context);
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF1E3A8A),
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: const Text('Save Changes'),
//                 ),
//               ).animate().fadeIn().slideY(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:triangle_home/theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _profileImageUrl;
  File? _newImageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final phone = user.phoneNumber!;
    final collections = ['hoster', 'student', 'guest'];

    for (final collection in collections) {
      final doc =
          await FirebaseFirestore.instance
              .collection(collection)
              .doc(phone)
              .get();

      if (doc.exists) {
        final data = doc.data()!['info'] ?? {};
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = phone;
          _profileImageUrl = data['profileImage'];
        });
        break;
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _newImageFile = File(pickedImage.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile, String phone) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'profile_images/$phone.jpg',
      );
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final phone = user.phoneNumber!;
    final collections = ['hoster', 'student', 'guest'];
    String? imageUrl = _profileImageUrl;

    if (_newImageFile != null) {
      imageUrl = await _uploadImage(_newImageFile!, phone);
    }

    for (final collection in collections) {
      final docRef = FirebaseFirestore.instance
          .collection(collection)
          .doc(phone);
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.update({
          'info.name': _nameController.text.trim(),
          'info.email': _emailController.text.trim(),
          'info.profileImage': imageUrl,
        });
        break;
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image =
        _newImageFile != null
            ? FileImage(_newImageFile!)
            : (_profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : const AssetImage('assets/images/default_avatar.png'))
                as ImageProvider;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[200],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(radius: 50, backgroundImage: image),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryColor,
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ).animate().scale(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter your name'
                            : null,
              ).animate().fadeIn().slideX(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter your email'
                            : null,
              ).animate().fadeIn().slideX(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ).animate().fadeIn().slideX(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Changes'),
                ),
              ).animate().fadeIn().slideY(),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

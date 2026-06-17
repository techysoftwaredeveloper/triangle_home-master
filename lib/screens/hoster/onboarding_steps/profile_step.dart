import 'package:flutter/material.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';



class ProfileStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic> initialData;

  const ProfileStep({super.key, required this.onContinue, required this.initialData});

  @override
  State<ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<ProfileStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  DateTime? _dob;
  String? _gender;
  String? _profileImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['name'] ?? '');
    _gender = widget.initialData['gender'];
    _profileImageUrl = widget.initialData['profileImage'];
    if (widget.initialData['dob'] != null) {
      _dob = DateTime.tryParse(widget.initialData['dob']);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final status = Platform.isIOS 
        ? await Permission.photos.request() 
        : await Permission.storage.request();
        
    if (status.isDenied || status.isPermanentlyDenied) {
      if (Platform.isAndroid) {
        final photoStatus = await Permission.photos.request();
        if (photoStatus.isDenied || photoStatus.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gallery access is required to upload a profile image')),
            );
          }
          if (photoStatus.isPermanentlyDenied) openAppSettings();
          return;
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gallery access is required to upload a profile image')),
          );
        }
        if (status.isPermanentlyDenied) openAppSettings();
        return;
      }
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final ref = FirebaseStorage.instance.ref().child('profile_images/${user!.uid}.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      setState(() => _profileImageUrl = url);
    } catch (e) {
      debugPrint('Error uploading image: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showBottomDatePicker() {
    DateTime tempDate = _dob ?? DateTime(1995);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          height: 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Set your Birthday',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.black, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  minimumYear: 1950,
                  maximumYear: DateTime.now().year - 18,
                  onDateTimeChanged: (DateTime newDate) {
                    tempDate = newDate;
                  },
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  setState(() => _dob = tempDate);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x406366F1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                    child: _profileImageUrl == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                  ),
                  if (_isUploading)
                    const Positioned.fill(child: CircularProgressIndicator()),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppTheme.successColor, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            InputField(
              label: 'Full Name (as per ID)',
              controller: _nameController,
              required: true,
            ),
            const SizedBox(height: 20),
            const Text('Gender', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: ['Male', 'Female', 'Other'].map((g) {
                final isSelected = _gender == g;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _gender = g),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.successColor : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          g,
                          style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Date of Birth', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showBottomDatePicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: AppTheme.successColor),
                    const SizedBox(width: 12),
                    Text(
                      _dob != null ? DateFormat('dd MMM yyyy').format(_dob!) : 'Select DOB',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && _gender != null && _dob != null) {
                    widget.onContinue({
                      'name': _nameController.text,
                      'gender': _gender,
                      'dob': _dob!.toIso8601String(),
                      'profileImage': _profileImageUrl,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

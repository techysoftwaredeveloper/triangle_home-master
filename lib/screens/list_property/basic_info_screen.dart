import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/widgets/list_property/dropdown_field.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class BasicInfoScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;

  const BasicInfoScreen({super.key, required this.onContinue});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _propertyTypeController = TextEditingController(text: 'College Hostel');
  final _collegeNameController = TextEditingController(text: 'Yenepoya University');
  final _wardenNameController = TextEditingController(text: 'Yenepoya University');
  final _phoneController = TextEditingController(text: '+91 98264 91827');
  final _emailController = TextEditingController(text: 'pradeep.aravind@gmail.com');
  final _idTypeController = TextEditingController(text: 'Aadhaar Card');
  final _idNumberController = TextEditingController(text: '7501 2974 0109 2855');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
            const SizedBox(height: 24),
            DropdownField(
              label: 'Property Type',
              controller: _propertyTypeController,
              items: const ['College Hostel', 'Paying Guest Accommodation', 'Apartments'],
            ),
            InputField(
              label: 'Name of College/University',
              controller: _collegeNameController,
              required: true,
              maxLines: 3,
            ),
            InputField(
              label: 'Full name of hostel warden',
              controller: _wardenNameController,
              required: true,
              maxLines: 3,
            ),
            InputField(
              label: 'Contact number',
              controller: _phoneController,
              required: true,
              maxLines: 1,
              keyboardType: TextInputType.phone,
            ),
            InputField(
              label: 'E-Mail ID',
              controller: _emailController,
              required: true,
              maxLines: 1,
              keyboardType: TextInputType.emailAddress,
            ),
            DropdownField(
              label: 'Type of identification document',
              controller: _idTypeController,
              items: const ['Aadhaar Card', 'PAN Card', 'Driving License'],
              required: true,
            ),
            InputField(
              label: 'Document number',
              controller: _idNumberController,
              required: true,
              maxLines: 1,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onContinue({
                      'type': _propertyTypeController.text,
                      'collegeName': _collegeNameController.text,
                      'wardenName': _wardenNameController.text,
                      'phone': _phoneController.text,
                      'email': _emailController.text,
                      'idType': _idTypeController.text,
                      'idNumber': _idNumberController.text,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
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
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:triangle_home/providers/property_provider.dart';
// import 'package:triangle_home/widgets/list_property/input_field.dart';
// import 'package:triangle_home/widgets/list_property/dropdown_field.dart';

// class BasicInfoScreen extends ConsumerStatefulWidget {
//   final Function(Map<String, dynamic>) onContinue;

//   const BasicInfoScreen({super.key, required this.onContinue});

//   @override
//   ConsumerState<BasicInfoScreen> createState() => _BasicInfoScreenState();
// }

// class _BasicInfoScreenState extends ConsumerState<BasicInfoScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _propertyTypeController = TextEditingController();
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _ownerNameController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _emailController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Basic Information',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1E293B),
//               ),
//             ).animate().fadeIn().slideX(begin: -0.2, end: 0),
//             const SizedBox(height: 24),
//             DropdownField(
//               label: 'Property Type',
//               controller: _propertyTypeController,
//               items: const [
//                 'College Hostel',
//                 'Paying Guest Accommodation',
//                 'Apartments',
//               ],
//               required: true,
//             ),
//             InputField(
//               label: 'Property Title',
//               controller: _titleController,
//               required: true,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'Description',
//               controller: _descriptionController,
//               required: true,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'Owner Name',
//               controller: _ownerNameController,
//               required: true,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'Contact Number',
//               controller: _phoneController,
//               required: true,
//               keyboardType: TextInputType.phone,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'Email',
//               controller: _emailController,
//               required: true,
//               keyboardType: TextInputType.emailAddress,
//               maxLines: 3,
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState?.validate() ?? false) {
//                     widget.onContinue({
//                       'type': _propertyTypeController.text,
//                       'title': _titleController.text,
//                       'description': _descriptionController.text,
//                       'ownerName': _ownerNameController.text,
//                       'phone': _phoneController.text,
//                       'email': _emailController.text,
//                     });
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF1E3A8A),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: const Text(
//                   'Continue',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                 ),
//               ),
//             ).animate().fadeIn().slideY(begin: 0.2, end: 0),
//           ],
//         ),
//       ),
//     );
//   }
// }

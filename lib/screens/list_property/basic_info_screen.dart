// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:triangle_home/widgets/list_property/dropdown_field.dart';
// import 'package:triangle_home/widgets/list_property/input_field.dart';

// class BasicInfoScreen extends StatefulWidget {
//   final Function(Map<String, dynamic>) onContinue;

//   const BasicInfoScreen({super.key, required this.onContinue});

//   @override
//   State<BasicInfoScreen> createState() => _BasicInfoScreenState();
// }

// class _BasicInfoScreenState extends State<BasicInfoScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _propertyTypeController = TextEditingController();
//   final _collegeNameController = TextEditingController();
//   final _wardenNameController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _idTypeController = TextEditingController();
//   final _idNumberController = TextEditingController();

//   void _showDropdownDialog(String label, List<String> items, TextEditingController controller) {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Select $label',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ],
//               ),
//             ),
//             const Divider(height: 1),
//             ListView.builder(
//               shrinkWrap: true,
//               itemCount: items.length,
//               itemBuilder: (context, index) {
//                 final item = items[index];
//                 final isSelected = controller.text == item;
//                 return ListTile(
//                   title: Text(item),
//                   trailing: isSelected
//                       ? const Icon(Icons.check_circle, color: Color(0xFF1E3A8A))
//                       : null,
//                   onTap: () {
//                     setState(() {
//                       controller.text = item;
//                       // Clear other fields when property type changes
//                       if (label == 'Property Type') {
//                         _collegeNameController.clear();
//                         _wardenNameController.clear();
//                         _phoneController.clear();
//                         _emailController.clear();
//                         _idTypeController.clear();
//                         _idNumberController.clear();
//                       }
//                     });
//                     Navigator.pop(context);
//                   },
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getNameLabel() {
//     switch (_propertyTypeController.text) {
//       case 'College Hostel':
//         return 'College/University Name';
//       case 'Paying Guest Accommodation':
//         return 'Owner Full Name';
//       case 'Apartments':
//         return 'Owner/Builder Name';
//       default:
//         return 'Full Name';
//     }
//   }

//   String _getSecondaryNameLabel() {
//     switch (_propertyTypeController.text) {
//       case 'College Hostel':
//         return 'Warden Name';
//       case 'Paying Guest Accommodation':
//         return 'Business Name (Optional)';
//       case 'Apartments':
//         return 'Building Name';
//       default:
//         return '';
//     }
//   }

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

//             // Property Type Selection
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Property Type',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 GestureDetector(
//                   onTap: () => _showDropdownDialog(
//                     'Property Type',
//                     ['College Hostel', 'Paying Guest Accommodation', 'Apartments'],
//                     _propertyTypeController,
//                   ),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 12,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.grey[300]!),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           _propertyTypeController.text.isEmpty
//                               ? 'Select Property Type'
//                               : _propertyTypeController.text,
//                           style: TextStyle(
//                             color: _propertyTypeController.text.isEmpty
//                                 ? Colors.grey[600]
//                                 : Colors.black,
//                           ),
//                         ),
//                         const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             if (_propertyTypeController.text.isNotEmpty) ...[
//               const SizedBox(height: 16),
//               InputField(
//                 label: _getNameLabel(),
//                 controller: _collegeNameController,
//                 required: true,
//                 maxLines: 2,
//               ),
//               InputField(
//                 label: _getSecondaryNameLabel(),
//                 controller: _wardenNameController,
//                 required: _propertyTypeController.text != 'Paying Guest Accommodation',
//                 maxLines: 2,
//               ),
//               InputField(
//                 label: 'Contact Number',
//                 controller: _phoneController,
//                 required: true,
//                 keyboardType: TextInputType.phone,
//                 maxLines: 1,
//               ),
//               InputField(
//                 label: 'Email ID',
//                 controller: _emailController,
//                 required: true,
//                 keyboardType: TextInputType.emailAddress,
//                 maxLines: 1,
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Type of identification document',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   GestureDetector(
//                     onTap: () => _showDropdownDialog(
//                       'ID Type',
//                       ['Aadhaar Card', 'PAN Card', 'Driving License'],
//                       _idTypeController,
//                     ),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey[300]!),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             _idTypeController.text.isEmpty
//                                 ? 'Select ID Type'
//                                 : _idTypeController.text,
//                             style: TextStyle(
//                               color: _idTypeController.text.isEmpty
//                                   ? Colors.grey[600]
//                                   : Colors.black,
//                             ),
//                           ),
//                           const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               InputField(
//                 label: 'Document number',
//                 controller: _idNumberController,
//                 required: true,
//                 maxLines: 1,
//               ),
//             ],

//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState?.validate() ?? false) {
//                     widget.onContinue({
//                       'type': _propertyTypeController.text,
//                       'collegeName': _collegeNameController.text,
//                       'wardenName': _wardenNameController.text,
//                       'phone': _phoneController.text,
//                       'email': _emailController.text,
//                       'idType': _idTypeController.text,
//                       'idNumber': _idNumberController.text,
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
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ).animate().fadeIn().slideY(begin: 0.2, end: 0),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _propertyTypeController.dispose();
//     _collegeNameController.dispose();
//     _wardenNameController.dispose();
//     _phoneController.dispose();
//     _emailController.dispose();
//     _idTypeController.dispose();
//     _idNumberController.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class BasicInfoScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;

  const BasicInfoScreen({super.key, required this.onContinue});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _propertyTypeController = TextEditingController();
  final _collegeNameController = TextEditingController();
  final _wardenNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _idTypeController = TextEditingController();
  final _idNumberController = TextEditingController();

  final List<String> propertyTypes = [
    'College Hostel',
    'Paying Guest Accommodation',
    'Apartments',
  ];

  final List<String> idTypes = ['Aadhaar Card', 'PAN Card', 'Driving License'];

  void _showDropdownDialog(
    String label,
    List<String> items,
    TextEditingController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select $label',
                        style: const TextStyle(
                          fontSize: AppTheme.fontLG,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = controller.text == item;
                    return ListTile(
                      title: Text(item),
                      trailing:
                          isSelected
                              ? const Icon(
                                Icons.check_circle,
                                color: AppTheme.primaryColor,
                              )
                              : null,
                      onTap: () {
                        setState(() {
                          controller.text = item;
                          if (label == 'Property Type') {
                            _collegeNameController.clear();
                            _wardenNameController.clear();
                            _phoneController.clear();
                            _emailController.clear();
                            _idTypeController.clear();
                            _idNumberController.clear();
                          }
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  String _getNameLabel() {
    switch (_propertyTypeController.text) {
      case 'College Hostel':
        return 'College/University Name';
      case 'Paying Guest Accommodation':
        return 'Owner Full Name';
      case 'Apartments':
        return 'Owner/Builder Name';
      default:
        return 'Full Name';
    }
  }

  String _getSecondaryNameLabel() {
    switch (_propertyTypeController.text) {
      case 'College Hostel':
        return 'Warden Name';
      case 'Paying Guest Accommodation':
        return 'Business Name (Optional)';
      case 'Apartments':
        return 'Building Name';
      default:
        return '';
    }
  }

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
                fontSize: AppTheme.font2XL,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
            const SizedBox(height: 24),

            // Property Type Dropdown
            Text(
              'Property Type',
              style: TextStyle(
                fontSize: AppTheme.fontBase,
                color: AppTheme.textLightColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap:
                  () => _showDropdownDialog(
                    'Property Type',
                    propertyTypes,
                    _propertyTypeController,
                  ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _propertyTypeController.text.isEmpty
                          ? 'Select Property Type'
                          : _propertyTypeController.text,
                      style: TextStyle(
                        color:
                            _propertyTypeController.text.isEmpty
                                ? Colors.grey[600]
                                : Colors.black,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),

            if (_propertyTypeController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              InputField(
                label: _getNameLabel(),
                controller: _collegeNameController,
                required: true,
                maxLines: 2,
              ),
              InputField(
                label: _getSecondaryNameLabel(),
                controller: _wardenNameController,
                required:
                    _propertyTypeController.text !=
                    'Paying Guest Accommodation',
                maxLines: 2,
              ),
              InputField(
                label: 'Contact Number',
                controller: _phoneController,
                required: true,
                keyboardType: TextInputType.phone,
                maxLines: 1,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  final cleaned = value.trim();
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
                    return 'Enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),

              InputField(
                label: 'Email ID',
                controller: _emailController,
                required: true,
                keyboardType: TextInputType.emailAddress,
                maxLines: 1,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  final email = value.trim();
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                  ).hasMatch(email)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              Text(
                'Type of identification document',
                style: TextStyle(
                  fontSize: AppTheme.fontBase,
                  color: AppTheme.textLightColor,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap:
                    () => _showDropdownDialog(
                      'ID Type',
                      idTypes,
                      _idTypeController,
                    ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _idTypeController.text.isEmpty
                            ? 'Select ID Type'
                            : _idTypeController.text,
                        style: TextStyle(
                          color:
                              _idTypeController.text.isEmpty
                                  ? Colors.grey[600]
                                  : Colors.black,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InputField(
                label: 'Document number',
                controller: _idNumberController,
                required: true,
                maxLines: 1,
              ),
            ],

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
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: AppTheme.fontMD,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _propertyTypeController.dispose();
    _collegeNameController.dispose();
    _wardenNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _idTypeController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }
}

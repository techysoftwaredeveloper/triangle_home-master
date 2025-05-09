// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:triangle_home/screens/OtpVerificationScreen.dart';


// class PhoneInput extends StatefulWidget {
//   const PhoneInput({super.key});

//   @override
//   State<PhoneInput> createState() => _PhoneInputState();
// }

// class _PhoneInputState extends State<PhoneInput> {
//   final _phoneController = TextEditingController(text: "98972 36559");
//   String _countryCode = "+91";

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     super.dispose();
//   }

//   void _handleSubmit() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => OtpVerificationScreen(
//           phoneNumber: _phoneController.text,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.20),
//                 blurRadius: 10,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: TextFormField(
//             controller: _phoneController,
//             keyboardType: TextInputType.phone,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//             decoration: InputDecoration(
//               hintText: '10 Digit Phone Number',
//               prefixIcon: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 margin: const EdgeInsets.only(right: 8),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       _countryCode,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(width: 4),
//                     const Icon(
//                       Icons.arrow_drop_down,
//                       color: Colors.grey,
//                       size: 20,
//                     ),
//                     Container(
//                       height: 24,
//                       width: 1,
//                       color: Colors.grey.withOpacity(0.5),
//                       margin: const EdgeInsets.symmetric(horizontal: 8),
//                     ),
//                   ],
//                 ),
//               ),
//               border: InputBorder.none,
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 16,
//               ),
//             ),
//             inputFormatters: [
//               FilteringTextInputFormatter.digitsOnly,
//               LengthLimitingTextInputFormatter(10),
//             ],
//             onFieldSubmitted: (_) => _handleSubmit(),
//           ),
//         ).animate(onPlay: (controller) => controller.repeat(reverse: true))
//           .shimmer(delay: 3.seconds, duration: 1.seconds)
//           .then(delay: 10.seconds),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/screens/OtpVerificationScreen.dart';


class PhoneInput extends StatefulWidget {
  const PhoneInput({super.key});

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormFieldState>();
  final String _countryCode = "+91";
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _validatePhoneNumber(String value) {
    // Remove any spaces or special characters
    final cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');
    return cleanNumber.length == 10;
  }

  void _handleSubmit() {
    final isValid = _validatePhoneNumber(_phoneController.text);
    setState(() {
      _errorText = isValid ? null : 'Please enter a valid 10-digit phone number';
    });

    if (isValid) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            phoneNumber: _phoneController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            key: _formKey,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '10 Digit Phone Number',
              errorText: _errorText,
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _countryCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey,
                      size: 20,
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: Colors.grey.withOpacity(0.5),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onFieldSubmitted: (_) => _handleSubmit(),
            onChanged: (value) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(delay: 3.seconds, duration: 1.seconds)
          .then(delay: 10.seconds),
      ],
    );
  }
}
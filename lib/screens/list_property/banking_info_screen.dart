// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:triangle_home/widgets/list_property/dropdown_field.dart';
// import 'package:triangle_home/widgets/list_property/input_field.dart';

// class BankingInfoScreen extends StatefulWidget {
//   final Function(Map<String, dynamic>) onContinue;

//   const BankingInfoScreen({super.key, required this.onContinue});

//   @override
//   State<BankingInfoScreen> createState() => _BankingInfoScreenState();
// }

// class _BankingInfoScreenState extends State<BankingInfoScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _accountNameController = TextEditingController();
//   final _bankNameController = TextEditingController();
//   final _accountNumberController = TextEditingController();
//   final _confirmAccountController = TextEditingController();
//   final _ifscController = TextEditingController();
//   final _upiController = TextEditingController();

//   void _showBankSelectionDialog() {
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
//                   const Text(
//                     'Select Bank',
//                     style: TextStyle(
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
//             ListView(
//               shrinkWrap: true,
//               children: [
//                 'HDFC Bank',
//                 'SBI',
//                 'ICICI Bank',
//                 'Axis Bank',
//               ].map((bank) => ListTile(
//                 title: Text(bank),
//                 trailing: _bankNameController.text == bank
//                     ? const Icon(Icons.check_circle, color: Color(0xFF1E3A8A))
//                     : null,
//                 onTap: () {
//                   setState(() {
//                     _bankNameController.text = bank;
//                   });
//                   Navigator.pop(context);
//                 },
//               )).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
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
//               'Banking Information',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1E293B),
//               ),
//             ).animate().fadeIn().slideX(begin: -0.2, end: 0),
//             const SizedBox(height: 24),
//             InputField(
//               label: 'Name as per bank account',
//               controller: _accountNameController,
//               required: true,
//               textCapitalization: TextCapitalization.words,
//               maxLines: 2,
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Name of bank*',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 GestureDetector(
//                   onTap: _showBankSelectionDialog,
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
//                           _bankNameController.text.isEmpty
//                               ? 'Select bank'
//                               : _bankNameController.text,
//                           style: TextStyle(
//                             color: _bankNameController.text.isEmpty
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
//             InputField(
//               label: 'Bank account number',
//               controller: _accountNumberController,
//               required: true,
//               keyboardType: TextInputType.number,
//               maxLines: 1,
//             ),
//             InputField(
//               label: 'Re-enter bank account number',
//               controller: _confirmAccountController,
//               required: true,
//               keyboardType: TextInputType.number,
//               obscureText: true,
//               maxLines: 1,
//               validator: (value) {
//                 if (value != _accountNumberController.text) {
//                   return 'Account numbers do not match';
//                 }
//                 return null;
//               },
//             ),
//             InputField(
//               label: 'IFSC Code',
//               controller: _ifscController,
//               required: true,
//               maxLines: 1,
//               textCapitalization: TextCapitalization.characters,
//             ),
//             InputField(
//               label: 'UPI ID for incoming payments',
//               controller: _upiController,
//               keyboardType: TextInputType.emailAddress,
//               maxLines: 1,
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState?.validate() ?? false) {
//                     widget.onContinue(
//                       {
//                         'accountName': _accountNameController.text,
//                         'bankName': _bankNameController.text,
//                         'accountNumber': _accountNumberController.text,
//                         'ifscCode': _ifscController.text,
//                         'upiId': _upiController.text,
//                       },
//                     );
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
//     _accountNameController.dispose();
//     _bankNameController.dispose();
//     _accountNumberController.dispose();
//     _confirmAccountController.dispose();
//     _ifscController.dispose();
//     _upiController.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class BankingInfoScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;

  const BankingInfoScreen({super.key, required this.onContinue});

  @override
  State<BankingInfoScreen> createState() => _BankingInfoScreenState();
}

class _BankingInfoScreenState extends State<BankingInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();

  bool _isLoading = false;

  void _showBankSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 16),
            children:
                [
                      'HDFC Bank',
                      'SBI',
                      'ICICI Bank',
                      'Axis Bank',
                      'Canara Bank',
                      'Kotak Mahindra',
                    ]
                    .map(
                      (bank) => ListTile(
                        title: Text(bank),
                        trailing:
                            _bankNameController.text == bank
                                ? const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryColor,
                                )
                                : null,
                        onTap: () {
                          setState(() => _bankNameController.text = bank);
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
          ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      Future.delayed(const Duration(seconds: 1), () {
        widget.onContinue({
          'accountName': _accountNameController.text.trim(),
          'bankName': _bankNameController.text.trim(),
          'accountNumber': _accountNumberController.text.trim(),
          'ifscCode': _ifscController.text.trim(),
          'upiId': _upiController.text.trim(),
        });

        setState(() => _isLoading = false);
      });
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
              'Banking Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
            const SizedBox(height: 24),

            InputField(
              label: 'Name as per bank account',
              controller: _accountNameController,
              required: true,
              textCapitalization: TextCapitalization.words,
              maxLines: 1,
            ),

            const SizedBox(height: 16),
            Text(
              'Name of bank*',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showBankSelectionSheet,
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
                      _bankNameController.text.isEmpty
                          ? 'Select bank'
                          : _bankNameController.text,
                      style: TextStyle(
                        color:
                            _bankNameController.text.isEmpty
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
              label: 'Bank account number',
              controller: _accountNumberController,
              required: true,
              keyboardType: TextInputType.number,
              maxLines: 1,
            ),
            InputField(
              label: 'Re-enter bank account number',
              controller: _confirmAccountController,
              required: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLines: 1,
              validator: (value) {
                if (value != _accountNumberController.text) {
                  return 'Account numbers do not match';
                }
                return null;
              },
            ),
            InputField(
              label: 'IFSC Code',
              controller: _ifscController,
              required: true,
              textCapitalization: TextCapitalization.characters,
              maxLines: 1,
              validator: (value) {
                if (!RegExp(
                  r'^[A-Z]{4}0[A-Z0-9]{6}$',
                ).hasMatch(value!.trim())) {
                  return 'Enter valid IFSC code';
                }
                return null;
              },
            ),

            InputField(
              label: 'UPI ID (optional)',
              controller: _upiController,
              keyboardType: TextInputType.emailAddress,
              maxLines: 1,
              validator: (value) {
                if (value != null &&
                    value.trim().isNotEmpty &&
                    !RegExp(r'^[\w.-]+@[\w]{3,}$').hasMatch(value.trim())) {
                  return 'Enter valid UPI ID';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isLoading
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
      ),
    );
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }
}

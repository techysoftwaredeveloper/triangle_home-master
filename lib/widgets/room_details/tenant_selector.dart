// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class TenantSelector extends StatefulWidget {
//   const TenantSelector({super.key});

//   @override
//   State<TenantSelector> createState() => _TenantSelectorState();
// }

// class _TenantSelectorState extends State<TenantSelector> {
//   int? selectedTenant;

//   void _selectTenant(int index) {
//     setState(() {
//       selectedTenant = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.only(bottom: 12),
//             child: Text(
//               'Number of Tenants In Room:',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 fontFamily: 'Outfit',
//                 color: Colors.white,
//               ),
//             ),
//           ).animate().fadeIn(duration: 300.ms),
//           Row(
//             children: List.generate(4, (index) {
//               final isSelected = selectedTenant == index;
//               return Padding(
//                 padding: const EdgeInsets.only(right: 15),
//                 child: GestureDetector(
//                   onTap: () => _selectTenant(index),
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 300),
//                     curve: Curves.easeInOut,
//                     padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: isSelected ? Colors.white : Colors.transparent,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       '${index + 1}',
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontFamily: 'Outfit',
//                         fontWeight: FontWeight.w500,
//                         color: isSelected ? const Color(0xFF1E4373) : Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             }),
//           ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2, end: 0),

//           // Optional validation message
//           if (selectedTenant == null)
//             Padding(
//               padding: const EdgeInsets.only(top: 10),
//               child: const Text(
//                 '* Please select number of tenants',
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.redAccent,
//                   fontFamily: 'Outfit',
//                 ),
//               ).animate().fadeIn(duration: 300.ms),
//             ),
//         ],
//       ),
//     );
//   }
// }


// // lib/widgets/room_details/tenant_selector.dart

// lib/widgets/room_details/tenant_selector.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class TenantSelector extends StatefulWidget {
//   const TenantSelector({super.key});

//   @override
//   State<TenantSelector> createState() => _TenantSelectorState();
// }

// class _TenantSelectorState extends State<TenantSelector> {
//   int? selectedTenant;
//   final _formKey = GlobalKey<FormState>();
//   final List<Map<String, TextEditingController>> _tenantControllers = [];

//   void _selectTenant(int index) {
//     setState(() {
//       selectedTenant = index;
//       _tenantControllers.clear();
      
//       // Create controllers for each tenant except the first one
//       if (index > 0) {
//         for (var i = 0; i < index; i++) {
//           _tenantControllers.add({
//             'name': TextEditingController(),
//             'phone': TextEditingController(),
//             'email': TextEditingController(),
//             'college': TextEditingController(),
//           });
//         }
//       }
//     });
//   }

//   @override
//   void dispose() {
//     for (var controllers in _tenantControllers) {
//       controllers.values.forEach((controller) => controller.dispose());
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Padding(
//               padding: EdgeInsets.only(bottom: 12),
//               child: Text(
//                 'Number of Tenants In Room:',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   fontFamily: 'Outfit',
//                   color: Colors.white,
//                 ),
//               ),
//             ).animate().fadeIn(duration: 300.ms),
            
//             Row(
//               children: List.generate(4, (index) {
//                 final isSelected = selectedTenant == index;
//                 return Padding(
//                   padding: const EdgeInsets.only(right: 15),
//                   child: GestureDetector(
//                     onTap: () => _selectTenant(index),
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       curve: Curves.easeInOut,
//                       padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: isSelected ? Colors.white : Colors.transparent,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         '${index + 1}',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontFamily: 'Outfit',
//                           fontWeight: FontWeight.w500,
//                           color: isSelected ? const Color(0xFF1E4373) : Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               }),
//             ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2, end: 0),

//             if (selectedTenant != null && selectedTenant! > 0)
//               ..._buildTenantForms(),

//             if (selectedTenant == null)
//               Padding(
//                 padding: const EdgeInsets.only(top: 10),
//                 child: const Text(
//                   '* Please select number of tenants',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.redAccent,
//                     fontFamily: 'Outfit',
//                   ),
//                 ).animate().fadeIn(duration: 300.ms),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   List<Widget> _buildTenantForms() {
//     return List.generate(_tenantControllers.length, (index) {
//       return Container(
//         margin: const EdgeInsets.only(top: 20),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.05),
//               blurRadius: 10,
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Additional Tenant ${index + 1}',
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1E4373),
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildTextField(
//               'Full Name',
//               _tenantControllers[index]['name']!,
//               validator: (value) => value?.isEmpty ?? true ? 'Please enter name' : null,
//             ),
//             const SizedBox(height: 12),
//             _buildTextField(
//               'Phone Number',
//               _tenantControllers[index]['phone']!,
//               keyboardType: TextInputType.phone,
//               validator: (value) => value?.isEmpty ?? true ? 'Please enter phone number' : null,
//             ),
//             const SizedBox(height: 12),
//             _buildTextField(
//               'Email',
//               _tenantControllers[index]['email']!,
//               keyboardType: TextInputType.emailAddress,
//               validator: (value) => value?.isEmpty ?? true ? 'Please enter email' : null,
//             ),
//             const SizedBox(height: 12),
//             _buildTextField(
//               'College/University',
//               _tenantControllers[index]['college']!,
//               validator: (value) => value?.isEmpty ?? true ? 'Please enter college name' : null,
//             ),
//           ],
//         ),
//       ).animate().fadeIn().slideY(begin: 0.2, end: 0);
//     });
//   }

//   Widget _buildTextField(
//     String label,
//     TextEditingController controller, {
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       ),
//       validator: validator,
//     );
//   }
// }

// lib/widgets/room_details/tenant_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:triangle_home/theme/app_theme.dart';

class TenantSelector extends StatefulWidget {
  final Function(int) onTenantSelected;

  const TenantSelector({
    super.key, 
    required this.onTenantSelected,
  });

  @override
  State<TenantSelector> createState() => _TenantSelectorState();
}

class _TenantSelectorState extends State<TenantSelector> {
  int? selectedTenant;

  void _selectTenant(int index) {
    setState(() {
      selectedTenant = index;
      widget.onTenantSelected(index + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Number of Tenants In Room:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Outfit',
                color: Colors.white,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
          Row(
            children: List.generate(4, (index) {
              final isSelected = selectedTenant == index;
              return Padding(
                padding: const EdgeInsets.only(right: 15),
                child: GestureDetector(
                  onTap: () => _selectTenant(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                        color: isSelected ? const Color(0xFF1E4373) : Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2, end: 0),

          if (selectedTenant == null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: const Text(
                '* Please select number of tenants',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                  fontFamily: 'Outfit',
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
        ],
      ),
    );
  }
}



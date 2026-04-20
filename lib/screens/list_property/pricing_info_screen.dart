// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:triangle_home/screens/property_management_screen.dart';
// import 'package:triangle_home/widgets/list_property/dropdown_field.dart';
// import 'package:triangle_home/widgets/list_property/input_field.dart';

// class PricingInfoScreen extends StatefulWidget {
//   final Function(Map<String, dynamic>) onContinue;

//   const PricingInfoScreen({super.key, required this.onContinue, required Map<String, dynamic> propertyData});

//   @override
//   State<PricingInfoScreen> createState() => _PricingInfoScreenState();
// }

// class _PricingInfoScreenState extends State<PricingInfoScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _price1Controller = TextEditingController(text: '7,500');
//   final _price2Controller = TextEditingController(text: '7,500');
//   final _price3Controller = TextEditingController(text: '7,500');
//   final _price4Controller = TextEditingController(text: '5,300');
//   final _addressLine1Controller = TextEditingController(text: '14/44');
//   final _addressLine2Controller = TextEditingController(
//     text: '4th Cross Street',
//   );
//   final _localityController = TextEditingController(text: 'Anna Nagar');
//   final _cityController = TextEditingController(text: 'Chennai');
//   final _stateController = TextEditingController(text: 'Tamil Nadu');

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
//               'Pricing and Address Information',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1E293B),
//               ),
//             ).animate().fadeIn().slideX(begin: -0.2, end: 0),
//             const SizedBox(height: 24),
//             const Text(
//               'Pricing Details:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//             InputField(
//               label: 'Men - 1 Sharing | Yearly (In Rupees)',
//               controller: _price1Controller,
//               required: true,
//               keyboardType: TextInputType.number,
//               prefix: '₹',
//               maxLines: 2,
//             ),
//             InputField(
//               label: 'Men - 2 Sharing | Yearly (In Rupees)',
//               controller: _price2Controller,
//               required: true,
//               keyboardType: TextInputType.number,
//               prefix: '₹',
//               maxLines: 2,
//             ),
//             InputField(
//               label: 'Men - 3 Sharing | Yearly (In Rupees)',
//               controller: _price3Controller,
//               required: true,
//               keyboardType: TextInputType.number,
//               prefix: '₹',
//               maxLines: 2,
//             ),
//             InputField(
//               label: 'Men - 4 Sharing | Yearly (In Rupees)',
//               controller: _price4Controller,
//               required: true,
//               keyboardType: TextInputType.number,
//               prefix: '₹',
//               maxLines: 2,
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Address And Location:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//             InputField(
//               label: 'Address Line 1',
//               controller: _addressLine1Controller,
//               required: true,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'Address Line 2',
//               controller: _addressLine2Controller,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'Locality',
//               controller: _localityController,
//               required: true,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'City',
//               controller: _cityController,
//               required: true,
//               maxLines: 3,
//             ),
//             DropdownField(
//               label: 'State',
//               controller: _stateController,
//               items: const [
//                 'Tamil Nadu',
//                 'Karnataka',
//                 'Kerala',
//                 'Andhra Pradesh',
//               ],
//               required: true,
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState?.validate() ?? false) {
//                     widget.onContinue({
//                       '1 sharing': _price1Controller.text,
//                       '2 sharing': _price2Controller.text,
//                       '3 sharing': _price3Controller.text,
//                       '4 sharing': _price4Controller.text,
//                       'addressLine1': _addressLine1Controller.text,
//                       'addressLine2': _addressLine2Controller.text,
//                       'locality': _localityController.text,
//                       'city': _cityController.text,
//                       'state': _stateController.text,
//                     });
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const PropertyManagementScreen(),
//                       ),
//                     );
//                   }
//                 },
//                 // onPressed: () {
//                 //   if (_formKey.currentState?.validate() ?? false) {
//                 //     Navigator.push(
//                 //       context,
//                 //       MaterialPageRoute(
//                 //         builder: (context) => const PropertyManagementScreen(),
//                 //       ),
//                 //     );
//                 //   }
//                 // },
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

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:triangle_home/widgets/list_property/dropdown_field.dart';
// import 'package:triangle_home/widgets/list_property/input_field.dart';

// class PricingInfoScreen extends StatefulWidget {
//   final Function(Map<String, dynamic>) onContinue;
//   final Map<String, dynamic> propertyData;

//   const PricingInfoScreen({
//     super.key,
//     required this.onContinue,
//     required this.propertyData,
//   });

//   @override
//   State<PricingInfoScreen> createState() => _PricingInfoScreenState();
// }

// class _PricingInfoScreenState extends State<PricingInfoScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final List<TextEditingController> _priceControllers = [];
//   final _advanceController = TextEditingController();
//   final _addressLine1Controller = TextEditingController();
//   final _addressLine2Controller = TextEditingController();
//   final _localityController = TextEditingController();
//   final _cityController = TextEditingController();
//   final _stateController = TextEditingController();
//   LatLng? _selectedLocation;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializePriceControllers();
//   }

//   void _initializePriceControllers() {
//     _priceControllers.clear();
//     final sharing = widget.propertyData['sharing'] as String;
//     final count = int.parse(sharing.split(' ')[0]);
//     for (var i = 0; i < count; i++) {
//       _priceControllers.add(TextEditingController());
//     }
//   }

//   Future<void> _getCurrentLocation() async {
//     setState(() => _isLoading = true);
//     try {
//       final permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         throw Exception('Location permission denied');
//       }

//       final position = await Geolocator.getCurrentPosition();
//       _selectedLocation = LatLng(position.latitude, position.longitude);

//       final placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );

//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;
//         _addressLine1Controller.text = '${place.street}';
//         _addressLine2Controller.text = '${place.subLocality}';
//         _localityController.text = '${place.locality}';
//         _cityController.text = '${place.subAdministrativeArea}';
//         _stateController.text = '${place.administrativeArea}';
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error getting location: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _selectFromMap() async {
//     // Implement map selection
//     // You'll need to create a new screen with Google Maps widget
//     // and return the selected location
//   }

//   Future<void> _searchPlace() async {
//     // Implement place search
//     // You can use Google Places API or similar service
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isForMen = widget.propertyData['availability'] == 'Men';
//     final sharing = widget.propertyData['sharing'] as String;
//     final count = int.parse(sharing.split(' ')[0]);

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Pricing and Location Details',
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF1E293B),
//               ),
//             ).animate().fadeIn().slideX(begin: -0.2, end: 0),
//             const SizedBox(height: 24),

//             // Pricing Section
//             const Text(
//               'Pricing Details:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//             const SizedBox(height: 16),

//             // Dynamic price fields based on sharing type
//             ...List.generate(count, (index) {
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 16),
//                 child: InputField(
//                   label: '${isForMen ? "Men" : "Women"} - ${index + 1} Sharing | Monthly (In Rupees)',
//                   controller: _priceControllers[index],
//                   required: true,
//                   keyboardType: TextInputType.number,
//                   prefix: '₹',
//                   maxLines: 1,
//                 ),
//               );
//             }),

//             // Advance Payment
//             InputField(
//               label: 'Advance Payment (In Rupees)',
//               controller: _advanceController,
//               required: true,
//               keyboardType: TextInputType.number,
//               prefix: '₹',
//               maxLines: 1,
//             ),

//             const SizedBox(height: 24),
//             const Text(
//               'Location Details:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//             const SizedBox(height: 16),

//             // Location Selection Buttons
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: _getCurrentLocation,
//                     icon: const Icon(Icons.my_location),
//                     label: const Text('Current Location'),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: _selectFromMap,
//                     icon: const Icon(Icons.map),
//                     label: const Text('Select from Map'),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             ElevatedButton.icon(
//               onPressed: _searchPlace,
//               icon: const Icon(Icons.search),
//               label: const Text('Search Place'),
//               style: ElevatedButton.styleFrom(
//                 minimumSize: const Size(double.infinity, 40),
//               ),
//             ),

//             const SizedBox(height: 24),
//             InputField(
//               label: 'Address Line 1',
//               controller: _addressLine1Controller,
//               required: true,
//               maxLines: 2,
//             ),
//             InputField(
//               label: 'Address Line 2',
//               controller: _addressLine2Controller,
//               maxLines: 2,
//             ),
//             InputField(
//               label: 'Locality',
//               controller: _localityController,
//               required: true,
//               maxLines: 1,
//             ),
//             InputField(
//               label: 'City',
//               controller: _cityController,
//               required: true,
//               maxLines: 1,
//             ),
//             DropdownField(
//               label: 'State',
//               controller: _stateController,
//               items: const [
//                 'Tamil Nadu',
//                 'Karnataka',
//                 'Kerala',
//                 'Andhra Pradesh',
//               ],
//               required: true,
//             ),

//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isLoading
//                     ? null
//                     : () {
//                         if (_formKey.currentState?.validate() ?? false) {
//                           final priceData = Map.fromIterables(
//                             List.generate(count, (i) => '${i + 1} sharing'),
//                             _priceControllers.map((c) => c.text),
//                           );

//                           widget.onContinue({
//                             'prices': priceData,
//                             'advance': _advanceController.text,
//                             'addressLine1': _addressLine1Controller.text,
//                             'addressLine2': _addressLine2Controller.text,
//                             'locality': _localityController.text,
//                             'city': _cityController.text,
//                             'state': _stateController.text,
//                             'latitude': _selectedLocation?.latitude,
//                             'longitude': _selectedLocation?.longitude,
//                           });
//                         }
//                       },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF1E3A8A),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: _isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text(
//                         'Continue',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//               ),
//             ).animate().fadeIn().slideY(begin: 0.2, end: 0),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     for (var controller in _priceControllers) {
//       controller.dispose();
//     }
//     _advanceController.dispose();
//     _addressLine1Controller.dispose();
//     _addressLine2Controller.dispose();
//     _localityController.dispose();
//     _cityController.dispose();
//     _stateController.dispose();
//     super.dispose();
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:triangle_home/screens/property_management_screen.dart';
// import 'package:triangle_home/widgets/list_property/dropdown_field.dart';
// import 'package:triangle_home/widgets/list_property/input_field.dart';

// class PricingInfoScreen extends StatefulWidget {
//   final Function(Map<String, dynamic>) onContinue;

//   const PricingInfoScreen({super.key, required this.onContinue, required Map propertyData});

//   @override
//   State<PricingInfoScreen> createState() => _PricingInfoScreenState();
// }

// class _PricingInfoScreenState extends State<PricingInfoScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _price1Controller = TextEditingController(text: '7,500');
//   final _price2Controller = TextEditingController(text: '7,500');
//   final _price3Controller = TextEditingController(text: '7,500');
//   final _price4Controller = TextEditingController(text: '5,300');
//   final _addressLine1Controller = TextEditingController(text: '14/44');
//   final _addressLine2Controller = TextEditingController(
//     text: '4th Cross Street',
//   );
//   final _localityController = TextEditingController(text: 'Anna Nagar');
//   final _cityController = TextEditingController(text: 'Chennai');
//   final _stateController = TextEditingController(text: 'Tamil Nadu');

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
//               'Pricing and Address Information',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1E293B),
//               ),
//             ).animate().fadeIn().slideX(begin: -0.2, end: 0),
//             const SizedBox(height: 24),
//             const Text(
//               'Pricing Details:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//             InputField(
//               label: 'Men - 1 Sharing | Yearly (In Rupees)',
//               controller: _price1Controller,
//               required: true,
//               keyboardType: TextInputType.number,
//               prefix: '₹',
//               maxLines: 2,
//             ),
//             InputField(
//               label: 'Men - 2 Sharing | Yearly (In Rupees)',
//               controller: _price2Controller,
//               required: true,
//               keyboardType: TextInputType.number,
//               prefix: '₹',
//               maxLines: 2,
//             ),
//             InputField(
//               label: 'Men - 3 Sharing | Yearly (In Rupees)',
//               controller: _price3Controller,
//               required: true,
//               keyboardType: TextInputType.number,
//               prefix: '₹',
//               maxLines: 2,
//             ),
//             InputField(
//               label: 'Men - 4 Sharing | Yearly (In Rupees)',
//               controller: _price4Controller,
//               required: true,
//               keyboardType: TextInputType.number,
//               prefix: '₹',
//               maxLines: 2,
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Address And Location:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//             InputField(
//               label: 'Address Line 1',
//               controller: _addressLine1Controller,
//               required: true,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'Address Line 2',
//               controller: _addressLine2Controller,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'Locality',
//               controller: _localityController,
//               required: true,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'City',
//               controller: _cityController,
//               required: true,
//               maxLines: 3,
//             ),
//             DropdownField(
//               label: 'State',
//               controller: _stateController,
//               items: const [
//                 'Tamil Nadu',
//                 'Karnataka',
//                 'Kerala',
//                 'Andhra Pradesh',
//               ],
//               required: true, onChanged: (value) {  },
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState?.validate() ?? false) {
//                     widget.onContinue({
//                       '1 sharing': _price1Controller.text,
//                       '2 sharing': _price2Controller.text,
//                       '3 sharing': _price3Controller.text,
//                       '4 sharing': _price4Controller.text,
//                       'addressLine1': _addressLine1Controller.text,
//                       'addressLine2': _addressLine2Controller.text,
//                       'locality': _localityController.text,
//                       'city': _cityController.text,
//                       'state': _stateController.text,
//                     });
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const PropertyManagementScreen(),
//                       ),
//                     );
//                   }
//                 },
//                 // onPressed: () {
//                 //   if (_formKey.currentState?.validate() ?? false) {
//                 //     Navigator.push(
//                 //       context,
//                 //       MaterialPageRoute(
//                 //         builder: (context) => const PropertyManagementScreen(),
//                 //       ),
//                 //     );
//                 //   }
//                 // },
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

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:triangle_home/screens/property_management_screen.dart';
// import 'package:triangle_home/widgets/list_property/dropdown_field.dart';
// import 'package:triangle_home/widgets/list_property/input_field.dart';

// class PricingInfoScreen extends StatefulWidget {
//   final Function(Map<String, dynamic>) onContinue;
//   final Map<String, dynamic> propertyData;

//   const PricingInfoScreen({
//     super.key,
//     required this.onContinue,
//     required this.propertyData,
//   });

//   @override
//   State<PricingInfoScreen> createState() => _PricingInfoScreenState();
// }

// class _PricingInfoScreenState extends State<PricingInfoScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _price1Controller = TextEditingController();
//   final _deposit2Controller = TextEditingController();
//   // final _price3Controller = TextEditingController();
//   // final _price4Controller = TextEditingController();
//   final _addressLine1Controller = TextEditingController();
//   final _addressLine2Controller = TextEditingController();
//   final _localityController = TextEditingController();
//   final _cityController = TextEditingController();
//   final _stateController = TextEditingController();
//   final _locationController = TextEditingController();
//   LatLng? _selectedLocation;

//   List<Map<String, dynamic>> get _pricingFields {
//     final gender = widget.propertyData['availability'] ?? 'Men';
//     final sharing = widget.propertyData['sharing'] ?? '4 Sharing';
//     final maxSharing = int.parse(sharing.split(' ')[0]);

//     return List.generate(maxSharing, (index) {
//       final number = index + 1;
//       return {
//         'label': '$gender - $number Sharing | Yearly (In Rupees)',
//         'controller': [
//           _price1Controller,
//           _deposit2Controller,
//           // _price3Controller,
//           // _price4Controller,
//         ][index],
//       };
//     });
//   }

//   void _showStateSelectionDialog() {
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
//                     'Select State',
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
//                 'Tamil Nadu',
//                 'Karnataka',
//                 'Kerala',
//                 'Andhra Pradesh',
//               ].map((state) => ListTile(
//                 title: Text(state),
//                 trailing: _stateController.text == state
//                     ? const Icon(Icons.check_circle, color: Color(0xFF1E3A8A))
//                     : null,
//                 onTap: () {
//                   setState(() {
//                     _stateController.text = state;
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

//   void _showLocationDialog() {
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
//                     'Select Location Method',
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
//             ListTile(
//               leading: const Icon(Icons.my_location),
//               title: const Text('Get Current Location'),
//               onTap: () async {
//                 Navigator.pop(context);
//                 await _getCurrentLocation();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.map),
//               title: const Text('Select from Map'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showMapPicker();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.search),
//               title: const Text('Search Location'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showLocationSearch();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _getCurrentLocation() async {
//     try {
//       final position = await Geolocator.getCurrentPosition();
//       setState(() {
//         _selectedLocation = LatLng(position.latitude, position.longitude);
//         _locationController.text = 'Current Location Selected';
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to get current location')),
//       );
//     }
//   }

//   void _showMapPicker() {
//     // Navigator.push(
//     //   context,
//     //   MaterialPageRoute(
//     //     builder: (context) => MapPickerScreen(
//     //       onLocationSelected: (LatLng location) {
//     //         setState(() {
//     //           _selectedLocation = location;
//     //           _locationController.text = 'Location Selected from Map';
//     //         });
//     //       },
//     //     ),
//     //   ),
//     // );
//   }

//   void _showLocationSearch() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Search Location'),
//         content: TextField(
//           decoration: const InputDecoration(
//             hintText: 'Enter location',
//             prefixIcon: Icon(Icons.search),
//           ),
//           onSubmitted: (value) {
//             Navigator.pop(context);
//             _locationController.text = value;
//           },
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
//               'Pricing and Address Information',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1E293B),
//               ),
//             ).animate().fadeIn().slideX(begin: -0.2, end: 0),
//             const SizedBox(height: 24),
//             const Text(
//               'Pricing Details:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//             ..._pricingFields.map((field) => InputField(
//               label: field['label'],
//               controller: field['controller'],
//               required: true,
//               keyboardType: TextInputType.number,
//               prefix: '₹',
//               maxLines: 1,
//             )),
//             const SizedBox(height: 24),
//             const Text(
//               'Address And Location:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//             InputField(
//               label: 'Address Line 1',
//               controller: _addressLine1Controller,
//               required: true,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'Address Line 2',
//               controller: _addressLine2Controller,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'Locality',
//               controller: _localityController,
//               required: true,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'City',
//               controller: _cityController,
//               required: true,
//               maxLines: 3,
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'State*',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 GestureDetector(
//                   onTap: _showStateSelectionDialog,
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
//                           _stateController.text.isEmpty
//                               ? 'Select State'
//                               : _stateController.text,
//                           style: TextStyle(
//                             color: _stateController.text.isEmpty
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
//             const SizedBox(height: 16),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Location*',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 GestureDetector(
//                   onTap: _showLocationDialog,
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
//                       children: [
//                         Expanded(
//                           child: Text(
//                             _locationController.text.isEmpty
//                                 ? 'Select Location'
//                                 : _locationController.text,
//                             style: TextStyle(
//                               color: _locationController.text.isEmpty
//                                   ? Colors.grey[600]
//                                   : Colors.black,
//                             ),
//                           ),
//                         ),
//                         const Icon(Icons.location_on, color: Colors.grey),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState?.validate() ?? false) {
//                     final prices = _pricingFields.asMap().map((i, field) =>
//                       MapEntry('price${i + 1}', field['controller'].text));

//                     widget.onContinue({
//                       ...prices,
//                       'addressLine1': _addressLine1Controller.text,
//                       'addressLine2': _addressLine2Controller.text,
//                       'locality': _localityController.text,
//                       'city': _cityController.text,
//                       'state': _stateController.text,
//                       'location': _selectedLocation?.toJson(),
//                     });

//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const PropertyManagementScreen(),
//                       ),
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
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
//     _price1Controller.dispose();
//     _deposit2Controller.dispose();
//     // _price3Controller.dispose();
//     // _price4Controller.dispose();
//     _addressLine1Controller.dispose();
//     _addressLine2Controller.dispose();
//     _localityController.dispose();
//     _cityController.dispose();
//     _stateController.dispose();
//     _locationController.dispose();
//     super.dispose();
//   }
// }

// // MapPickerScreen remains unchanged
//----------------------------------------------------------------------------------------------------------

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:triangle_home/screens/property_management_screen.dart';
// import 'package:triangle_home/widgets/list_property/input_field.dart';

// class PricingInfoScreen extends StatefulWidget {
//   final Function(Map<String, dynamic>) onContinue;
//   final Map<String, dynamic> propertyData;

//   const PricingInfoScreen({
//     super.key,
//     required this.onContinue,
//     required this.propertyData, required pricingInfo,
//   });

//   @override
//   State<PricingInfoScreen> createState() => _PricingInfoScreenState();
// }

// class _PricingInfoScreenState extends State<PricingInfoScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _advanceAmountController = TextEditingController();
//   final _monthlyRentController = TextEditingController();
//   final _addressLine1Controller = TextEditingController();
//   final _addressLine2Controller = TextEditingController();
//   final _localityController = TextEditingController();
//   final _cityController = TextEditingController();
//   final _stateController = TextEditingController();
//   final _locationController = TextEditingController();
//   LatLng? _selectedLocation;

//   String get selectedSharing => widget.propertyData['sharing'] ?? 'Single';

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
//               'Pricing and Address Information',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1E293B),
//               ),
//             ).animate().fadeIn().slideX(begin: -0.2, end: 0),
//             const SizedBox(height: 24),
//             const Text(
//               'Pricing Details:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//             Text(
//               'Type of Sharing: $selectedSharing',
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//             InputField(
//               label: 'Advance Amount (₹)',
//               controller: _advanceAmountController,
//               required: true,
//               keyboardType: TextInputType.number,
//               prefix: '₹',
//               maxLines: 1,
//             ),
//             InputField(
//               label: 'Monthly Rent (₹)',
//               controller: _monthlyRentController,
//               required: true,
//               keyboardType: TextInputType.number,
//               prefix: '₹',
//               maxLines: 1,
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Address And Location:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//             InputField(
//               label: 'Address Line 1',
//               controller: _addressLine1Controller,
//               required: true,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'Address Line 2',
//               controller: _addressLine2Controller,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'Locality',
//               controller: _localityController,
//               required: true,
//               maxLines: 1,
//             ),
//             InputField(
//               label: 'City',
//               controller: _cityController,
//               required: true,
//               maxLines: 1,
//             ),
//             InputField(
//               label: 'State',
//               controller: _stateController,
//               required: true,
//               maxLines: 1,
//             ),
//             InputField(
//               label: 'Location (Optional)',
//               controller: _locationController,
//               maxLines: 1,
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState?.validate() ?? false) {
//                     widget.onContinue({
//                       'advanceAmount': _advanceAmountController.text,
//                       'monthlyRent': _monthlyRentController.text,
//                       'addressLine1': _addressLine1Controller.text,
//                       'addressLine2': _addressLine2Controller.text,
//                       'locality': _localityController.text,
//                       'city': _cityController.text,
//                       'state': _stateController.text,
//                       'location': _selectedLocation?.toJson(),
//                     });

//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const PropertyManagementScreen(),
//                       ),
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
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
//     _advanceAmountController.dispose();
//     _monthlyRentController.dispose();
//     _addressLine1Controller.dispose();
//     _addressLine2Controller.dispose();
//     _localityController.dispose();
//     _cityController.dispose();
//     _stateController.dispose();
//     _locationController.dispose();
//     super.dispose();
//   }
// }

// // Add this to PricingInfoScreen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_place/google_place.dart';
// import 'package:triangle_home/screens/property_management_screen.dart';
// import 'package:triangle_home/widgets/list_property/input_field.dart';

// class PricingInfoScreen extends StatefulWidget {
//   final Function(Map<String, dynamic>) onContinue;
//   final Map<String, dynamic> propertyData;

//   const PricingInfoScreen({
//     super.key,
//     required this.onContinue,
//     required this.propertyData,
//     required pricingInfo,
//   });

//   @override
//   State<PricingInfoScreen> createState() => _PricingInfoScreenState();
// }

// class _PricingInfoScreenState extends State<PricingInfoScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _advanceAmountController = TextEditingController();
//   final _monthlyRentController = TextEditingController();
//   final _addressLine1Controller = TextEditingController();
//   final _addressLine2Controller = TextEditingController();
//   final _localityController = TextEditingController();
//   final _cityController = TextEditingController();
//   final _stateController = TextEditingController();
//   final _locationController = TextEditingController();
//   LatLng? _selectedLocation;
//   late GooglePlace _googlePlace;

//   String get selectedSharing => widget.propertyData['sharing'] ?? 'Single';

//   @override
//   void initState() {
//     super.initState();
//     _googlePlace = GooglePlace("YOUR_GOOGLE_API_KEY");
//   }

//   Future<void> _handleLocationSearch() async {
//     final result = await showSearch(
//       context: context,
//       delegate: LocationSearchDelegate(_googlePlace),
//     );

//     if (result != null) {
//       setState(() {
//         _locationController.text = result.description ?? '';
//         _selectedLocation = LatLng(result.lat ?? 0, result.lng ?? 0);
//       });
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
//               'Pricing and Address Information',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF1E293B),
//               ),
//             ).animate().fadeIn().slideX(begin: -0.2, end: 0),
//             const SizedBox(height: 24),
//             const Text(
//               'Pricing Details:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1E293B),
//               ),
//             ),
//             Text('Type of Sharing: $selectedSharing'),
//             InputField(
//               label: 'Advance Amount (₹)',
//               controller: _advanceAmountController,
//               required: true,
//               keyboardType: TextInputType.number,
//               prefix: '₹',
//               maxLines: 1,
//             ),
//             InputField(
//               label: 'Monthly Rent (₹)',
//               controller: _monthlyRentController,
//               required: true,
//               keyboardType: TextInputType.number,
//               prefix: '₹',
//               maxLines: 1,
//             ),
//             const SizedBox(height: 24),
//             const Text('Address And Location:'),
//             InputField(
//               label: 'Address Line 1',
//               controller: _addressLine1Controller,
//               required: true,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'Address Line 2',
//               controller: _addressLine2Controller,
//               maxLines: 3,
//             ),
//             InputField(
//               label: 'Locality',
//               controller: _localityController,
//               required: true,
//               maxLines: 1,
//             ),
//             InputField(
//               label: 'City',
//               controller: _cityController,
//               required: true,
//               maxLines: 1,
//             ),
//             InputField(
//               label: 'State',
//               controller: _stateController,
//               required: true,
//               maxLines: 1,
//             ),
//             GestureDetector(
//               onTap: _handleLocationSearch,
//               child: AbsorbPointer(
//                 child: InputField(
//                   label: 'Location',
//                   controller: _locationController,
//                   maxLines: 1,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState?.validate() ?? false) {
//                     widget.onContinue({
//                       'advanceAmount': _advanceAmountController.text,
//                       'monthlyRent': _monthlyRentController.text,
//                       'addressLine1': _addressLine1Controller.text,
//                       'addressLine2': _addressLine2Controller.text,
//                       'locality': _localityController.text,
//                       'city': _cityController.text,
//                       'state': _stateController.text,
//                       'location': _selectedLocation?.toJson(),
//                     });
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const PropertyManagementScreen(),
//                       ),
//                     );
//                   }
//                 },
//                 child: const Text('Continue'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _advanceAmountController.dispose();
//     _monthlyRentController.dispose();
//     _addressLine1Controller.dispose();
//     _addressLine2Controller.dispose();
//     _localityController.dispose();
//     _cityController.dispose();
//     _stateController.dispose();
//     _locationController.dispose();
//     super.dispose();
//   }
// }

// class LocationSearchDelegate extends SearchDelegate<AutocompletePrediction?> {
//   final GooglePlace googlePlace;
//   List<AutocompletePrediction> predictions = [];

//   LocationSearchDelegate(this.googlePlace);

//   @override
//   Widget buildSuggestions(BuildContext context) {
//     return ListView.builder(
//       itemCount: predictions.length,
//       itemBuilder: (context, index) {
//         final suggestion = predictions[index];
//         return ListTile(
//           title: Text(suggestion.description ?? ''),
//           onTap: () async {
//             final details = await googlePlace.details.get(suggestion.placeId!);
//             final location = details?.result?.geometry?.location;
//             close(context, AutocompletePrediction(
//               description: suggestion.description,
//               placeId: suggestion.placeId,
//               lat: location?.lat,
//               lng: location?.lng,
//             ));
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget buildResults(BuildContext context) => const SizedBox.shrink();

//   @override
//   List<Widget>? buildActions(BuildContext context) => [
//         if (query.isNotEmpty)
//           IconButton(
//             icon: const Icon(Icons.clear),
//             onPressed: () {
//               query = '';
//               showSuggestions(context);
//             },
//           )
//       ];

//   @override
//   Widget? buildLeading(BuildContext context) => IconButton(
//         icon: const Icon(Icons.arrow_back),
//         onPressed: () => close(context, null),
//       );

//   @override
//   void showSuggestions(BuildContext context) {
//     super.showSuggestions(context);
//     googlePlace.autocomplete.get(query).then((result) {
//       if (result?.predictions != null) {
//         predictions = result!.predictions!;
//         query = query; // Refresh UI
//       }
//     });
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:triangle_home/screens/property_management_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';
import 'package:triangle_home/widgets/list_property/input_field.dart';

class PricingInfoScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onContinue;
  final Map<String, dynamic> propertyData;

  const PricingInfoScreen({
    super.key,
    required this.onContinue,
    required this.propertyData,
    required pricingInfo,
  });

  @override
  State<PricingInfoScreen> createState() => _PricingInfoScreenState();
}

class _PricingInfoScreenState extends State<PricingInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _advanceAmountController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _localityController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _locationController = TextEditingController();
  List<String> _placeSuggestions = [];
  final String _googleApiKey = 'AIzaSyBuI60UGpnz2bpGia8JOk8r7zzFoniW1h0';

  String get selectedSharing => widget.propertyData['sharing'] ?? 'Single';

  void _getSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() => _placeSuggestions = []);
      return;
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleApiKey&types=geocode',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _placeSuggestions = List<String>.from(
          data['predictions'].map((p) => p['description']),
        );
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
              'Pricing and Address Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
            const SizedBox(height: 24),
            const Text(
              'Pricing Details:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              'Type of Sharing: $selectedSharing',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            InputField(
              label: 'Advance Amount (₹)',
              controller: _advanceAmountController,
              required: true,
              keyboardType: TextInputType.number,
              prefix: '₹',
              maxLines: 1,
            ),
            InputField(
              label: 'Monthly Rent (₹)',
              controller: _monthlyRentController,
              required: true,
              keyboardType: TextInputType.number,
              prefix: '₹',
              maxLines: 1,
            ),
            const SizedBox(height: 24),
            const Text(
              'Address And Location:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            InputField(
              label: 'Address Line 1',
              controller: _addressLine1Controller,
              required: true,
              maxLines: 3,
            ),
            InputField(
              label: 'Address Line 2',
              controller: _addressLine2Controller,
              maxLines: 3,
            ),
            InputField(
              label: 'Locality',
              controller: _localityController,
              required: true,
              maxLines: 1,
            ),
            InputField(
              label: 'City',
              controller: _cityController,
              required: true,
              maxLines: 1,
            ),
            InputField(
              label: 'State',
              controller: _stateController,
              required: true,
              maxLines: 1,
            ),
            TextFormField(
              controller: _locationController,
              onChanged: _getSuggestions,
              decoration: const InputDecoration(
                labelText: 'Location (Search & Select)',
              ),
            ),
            if (_placeSuggestions.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                itemCount: _placeSuggestions.length,
                itemBuilder:
                    (context, index) => ListTile(
                      title: Text(_placeSuggestions[index]),
                      onTap: () {
                        setState(() {
                          _locationController.text = _placeSuggestions[index];
                          _placeSuggestions.clear();
                        });
                      },
                    ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onContinue({
                      'advanceAmount': _advanceAmountController.text,
                      'monthlyRent': _monthlyRentController.text,
                      'addressLine1': _addressLine1Controller.text,
                      'addressLine2': _addressLine2Controller.text,
                      'locality': _localityController.text,
                      'city': _cityController.text,
                      'state': _stateController.text,
                      'location': _locationController.text,
                    });

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PropertyManagementScreen(),
                      ),
                    );
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    _advanceAmountController.dispose();
    _monthlyRentController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _localityController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class FeatureFlagService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, bool> _flags = {
    'hostel_module_enabled': true,
    'apartment_module_enabled': true,
    'online_payment_enabled': true,
    'audit_logging_enabled': true,
  };

  Future<void> init() async {
    try {
      final doc = await _firestore.collection('config').doc('feature_flags').get();
      if (doc.exists) {
        final data = doc.data()!;
        _flags = data.map((key, value) => MapEntry(key, value as bool));
      }
    } catch (e) {
      // Fallback to defaults
      print('Failed to load feature flags: $e');
    }
  }

  bool isEnabled(String flag) => _flags[flag] ?? false;
}

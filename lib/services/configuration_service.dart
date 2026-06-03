import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigurationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> _settings = {
    'booking_timeout_minutes': 30,
    'platform_commission_percentage': 10,
    'min_image_count': 3,
    'max_image_count': 10,
  };

  Future<void> init() async {
    try {
      final doc = await _firestore.collection('config').doc('settings').get();
      if (doc.exists) {
        _settings = {..._settings, ...doc.data()!};
      }
    } catch (e) {
      debugPrint('Failed to load dynamic settings: $e');
    }
  }

  T getSetting<T>(String key, T defaultValue) {
    return _settings[key] as T? ?? defaultValue;
  }

  int get bookingTimeoutMinutes => getSetting('booking_timeout_minutes', 30);
  double get platformCommission =>
      (getSetting('platform_commission_percentage', 10)).toDouble();
}

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum SystemEvent {
  bookingCreated,
  bookingApproved,
  paymentCompleted,
  tenantCheckedIn,
  tenantCheckedOut,
  propertyModerated,
  occupancyReconciled,
}

class MonitoringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logError(
    String message, {
    String? stackTrace,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await _firestore.collection('error_logs').add({
        'message': message,
        'stackTrace': stackTrace,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
        ...?extra,
      });
    } catch (e) {
      debugPrint('Critical: Failed to log error to Firestore: $e');
    }
  }

  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    try {
      await _firestore.collection('events').add({
        'name': name,
        'params': params,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to log event: $e');
    }
  }

  Future<void> logSystemEvent(
    SystemEvent event, {
    required String targetId,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      await _firestore.collection('system_events').add({
        'type': event.name,
        'targetId': targetId,
        'timestamp': FieldValue.serverTimestamp(),
        'data': extraData,
      });
    } catch (e) {
      debugPrint('Failed to log system event: $e');
    }
  }
}

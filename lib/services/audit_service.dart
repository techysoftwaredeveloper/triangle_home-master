import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logAction({
    required String action,
    required String targetId,
    required String targetType,
    String? reason,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('audit_logs').add({
        'action': action,
        'targetId': targetId,
        'targetType': targetType,
        'performedBy': user?.uid ?? 'system',
        'performedByEmail': user?.email ?? 'system',
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'extraData': extraData,
      });
    } catch (e) {
      // We don't want audit logging failure to crash the app, but we should log it
      print('Audit logging failed: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getLogs({int limit = 100}) {
    return _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }
}

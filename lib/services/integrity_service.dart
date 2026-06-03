import 'package:cloud_firestore/cloud_firestore.dart';

class IntegrityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifies that all confirmed bookings belong to existing users and properties
  Future<List<String>> validateRelationshipIntegrity() async {
    final errors = <String>[];

    try {
      final bookings = await _firestore.collection('bookings').get();

      for (final doc in bookings.docs) {
        final data = doc.data();
        final propertyId = data['propertyId'];
        final studentId = data['studentId'];

        // 1. Check Property Existence
        final propDoc =
            await _firestore.collection('properties').doc(propertyId).get();
        if (!propDoc.exists) {
          errors.add(
            'Booking ${doc.id} references non-existent property $propertyId',
          );
        }

        // 2. Check Student Existence (across student/hoster/guest collections)
        bool studentFound = false;
        for (final col in ['student', 'hoster', 'guest']) {
          final studentDoc =
              await _firestore.collection(col).doc(studentId).get();
          if (studentDoc.exists) {
            studentFound = true;
            break;
          }
        }
        if (!studentFound) {
          errors.add(
            'Booking ${doc.id} references non-existent student $studentId',
          );
        }
      }
    } catch (e) {
      errors.add('Integrity check failed: $e');
    }

    return errors;
  }
}

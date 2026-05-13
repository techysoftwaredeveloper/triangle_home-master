import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/errors/failures.dart';

class PropertyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot<Map<String, dynamic>>> getProperty(String id) async {
    try {
      return await _firestore.collection('properties').doc(id).get();
    } on FirebaseException catch (e) {
      throw PropertyFailure('Failed to fetch property: ${e.message}', code: e.code);
    } catch (e) {
      throw PropertyFailure('Unexpected error fetching property: $e');
    }
  }

  Future<void> updateOccupancy(String id, int delta) async {
    try {
      await _firestore.collection('properties').doc(id).update({
        'currentOccupancy': FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw PropertyFailure('Failed to update occupancy: ${e.message}', code: e.code);
    } catch (e) {
      throw PropertyFailure('Unexpected error updating occupancy: $e');
    }
  }

  Future<void> setOccupancy(String id, int value) async {
    try {
      await _firestore.collection('properties').doc(id).update({
        'currentOccupancy': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw PropertyFailure('Failed to set occupancy: ${e.message}', code: e.code);
    } catch (e) {
      throw PropertyFailure('Unexpected error setting occupancy: $e');
    }
  }

  Query<Map<String, dynamic>> getBaseQuery() {
    return _firestore.collection('properties');
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns data as a List of Maps for CSV/Excel conversion
  Future<List<Map<String, dynamic>>> exportCollection(String collectionName) async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Export failed: $e');
      return [];
    }
  }

  /// Specific helper for occupancy reports
  Future<List<Map<String, dynamic>>> getOccupancyReport() async {
    final properties = await _firestore.collection('properties').get();
    return properties.docs.map((doc) {
      final data = doc.data();
      return {
        'Property': data['title'] ?? 'N/A',
        'Capacity': data['capacity'] ?? 0,
        'Occupancy': data['currentOccupancy'] ?? 0,
        'Vacancy': (data['capacity'] ?? 0) - (data['currentOccupancy'] ?? 0),
      };
    }).toList();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all payments for a property
  Stream<QuerySnapshot<Map<String, dynamic>>> getPropertyPayments(String propertyId) {
    return _firestore
        .collection('payments')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get all expenses for a property
  Stream<QuerySnapshot<Map<String, dynamic>>> getPropertyExpenses(String propertyId) {
    return _firestore
        .collection('expenses')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get monthly settlements for a property
  Stream<QuerySnapshot<Map<String, dynamic>>> getPropertySettlements(String propertyId) {
    return _firestore
        .collection('settlements')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('month', descending: true)
        .snapshots();
  }

  /// Log a new expense
  Future<void> createExpense(Map<String, dynamic> data) async {
    await _firestore.collection('expenses').add({
      ...data,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Get security deposits for a property
  Stream<QuerySnapshot<Map<String, dynamic>>> getPropertyDeposits(String propertyId) {
    return _firestore
        .collection('deposits')
        .where('propertyId', isEqualTo: propertyId)
        .snapshots();
  }
}

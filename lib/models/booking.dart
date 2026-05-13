import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/core/constants/enums.dart';

class Booking {
  final String id;
  final String propertyId;
  final String studentId;
  final String studentName;
  final String propertyName;
  final double price;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String requestId;

  Booking({
    required this.id,
    required this.propertyId,
    required this.studentId,
    required this.studentName,
    required this.propertyName,
    required this.price,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.requestId,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      propertyName: data['propertyName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => BookingStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == (data['paymentStatus'] ?? 'pending'),
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      requestId: data['requestId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'studentId': studentId,
      'studentName': studentName,
      'propertyName': propertyName,
      'price': price,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'requestId': requestId,
    };
  }
}

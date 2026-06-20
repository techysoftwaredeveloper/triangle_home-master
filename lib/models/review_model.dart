import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String propertyId;
  final String userId;
  final String userName;
  final String? userImage;
  final String bookingId;
  final double rating;
  final String comment;
  final String? hosterReply;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.bookingId,
    required this.rating,
    required this.comment,
    this.hosterReply,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      propertyId: data['property_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? 'User',
      userImage: data['user_image'],
      bookingId: data['booking_id'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] ?? '',
      hosterReply: data['hoster_reply'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'property_id': propertyId,
      'user_id': userId,
      'user_name': userName,
      'user_image': userImage,
      'booking_id': bookingId,
      'rating': rating,
      'comment': comment,
      'hoster_reply': hosterReply,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

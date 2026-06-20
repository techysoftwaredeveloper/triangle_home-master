import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triangle_home/models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ReviewModel>> getPropertyReviews(String propertyId) {
    return _firestore
        .collection('reviews')
        .where('property_id', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }

  Future<void> submitReview(ReviewModel review) async {
    final batch = _firestore.batch();

    // 1. Add review
    final reviewRef = _firestore.collection('reviews').doc();
    batch.set(reviewRef, review.toFirestore());

    // 2. Update Property Stats
    final propertyRef = _firestore.collection('properties').doc(review.propertyId);
    final statsRef = _firestore.collection('propertyStats').doc(review.propertyId);

    // Get current rating and count
    final propertyDoc = await propertyRef.get();
    final currentRating = (propertyDoc.data()?['rating'] as num?)?.toDouble() ?? 0.0;
    final currentCount = (propertyDoc.data()?['reviewCount'] as num?)?.toInt() ?? 0;

    final double newCount = currentCount + 1.0;
    final double newRating = ((currentRating * currentCount) + review.rating) / newCount;

    batch.update(propertyRef, {
      'rating': newRating,
      'reviewCount': newCount.toInt(),
    });

    batch.set(statsRef, {
      'rating': newRating,
      'reviewCount': newCount.toInt(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> replyToReview(String reviewId, String reply) async {
    await _firestore.collection('reviews').doc(reviewId).update({
      'hoster_reply': reply,
    });
  }

  Future<void> deleteReview(String reviewId, String propertyId, double rating) async {
    // Note: Decrementing average precisely requires getting all reviews or storing sum
    // For now, let's just delete the review. In production, we'd trigger a cloud function to re-calc.
    await _firestore.collection('reviews').doc(reviewId).delete();
  }
}

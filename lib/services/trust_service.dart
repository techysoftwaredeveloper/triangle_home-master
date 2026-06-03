import 'package:cloud_firestore/cloud_firestore.dart';

class TrustService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Weights for Trust Score calculation (Total: 100)
  static const double emailWeight = 10;
  static const double phoneWeight = 10;
  static const double govIdWeight = 30;
  static const double panWeight = 20;
  static const double profilePhotoWeight = 10;
  static const double bankVerifiedWeight = 20;

  /// Calculates and updates a user's trust score based on their verification status
  Future<int> calculateAndUpdateTrustScore(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return 0;

    final data = userDoc.data()!;
    final verif = data['verification'] as Map? ?? {};
    final info = data['info'] as Map? ?? {};

    double score = 0;

    if (data['emailVerified'] == true) score += emailWeight;
    if (verif['phoneVerified'] == true) score += phoneWeight;
    if (verif['govIdVerified'] == true) score += govIdWeight;
    if (verif['panVerified'] == true) score += panWeight;
    if (info['profileImage'] != null) score += profilePhotoWeight;
    if (data['bank_info'] != null) score += bankVerifiedWeight;

    final int finalScore = score.round();

    await _firestore.collection('users').doc(userId).update({
      'trustScore': finalScore,
      'trustLevel': _getTrustLevel(finalScore),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return finalScore;
  }

  String _getTrustLevel(int score) {
    if (score >= 90) return 'ELITE';
    if (score >= 75) return 'EXCELLENT';
    if (score >= 50) return 'GOOD';
    if (score >= 30) return 'BASIC';
    return 'UNVERIFIED';
  }
}

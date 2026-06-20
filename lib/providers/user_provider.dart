import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the current user's profile data from Firestore.
final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.isAnonymous) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) => snapshot.data());
});

/// Provides just the housing preferences for easier access.
final housingPreferencesProvider = Provider<Map<String, dynamic>>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.when(
    data: (data) => Map<String, dynamic>.from(data?['housing_preferences'] ?? {}),
    loading: () => {},
    error: (_, __) => {},
  );
});

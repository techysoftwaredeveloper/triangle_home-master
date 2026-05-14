import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class PrivacySettings {
  final bool biometricLogin;
  final bool locationSharing;
  final bool profileVisibility;
  final bool showNumberToHosters;

  PrivacySettings({
    this.biometricLogin = false,
    this.locationSharing = true,
    this.profileVisibility = true,
    this.showNumberToHosters = true,
  });

  PrivacySettings copyWith({
    bool? biometricLogin,
    bool? locationSharing,
    bool? profileVisibility,
    bool? showNumberToHosters,
  }) {
    return PrivacySettings(
      biometricLogin: biometricLogin ?? this.biometricLogin,
      locationSharing: locationSharing ?? this.locationSharing,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showNumberToHosters: showNumberToHosters ?? this.showNumberToHosters,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'biometricLogin': biometricLogin,
      'locationSharing': locationSharing,
      'profileVisibility': profileVisibility,
      'showNumberToHosters': showNumberToHosters,
    };
  }

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      biometricLogin: map['biometricLogin'] ?? false,
      locationSharing: map['locationSharing'] ?? true,
      profileVisibility: map['profileVisibility'] ?? true,
      showNumberToHosters: map['showNumberToHosters'] ?? true,
    );
  }
}

class PrivacySecurityNotifier extends StateNotifier<PrivacySettings> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  PrivacySecurityNotifier() : super(PrivacySettings()) {
    _init();
  }

  void _init() {
    if (_uid == null) return;

    _firestore.collection('users').doc(_uid).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()?['privacy_settings'] as Map<String, dynamic>?;
        if (data != null) {
          state = PrivacySettings.fromMap(data);
        }
      }
    });
  }

  Future<void> updateSettings(PrivacySettings newSettings) async {
    if (_uid == null) return;

    state = newSettings;
    await _firestore.collection('users').doc(_uid).set({
      'privacy_settings': newSettings.toMap(),
    }, SetOptions(merge: true));

    // Handle Hardware Actions
    if (!newSettings.locationSharing) {
      // Logic to stop location tracking if active
      // For now we just ensure permission is checked when enabled
    } else {
      await _checkLocationPermission();
    }
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<void> toggleBiometric(bool value) async {
    await updateSettings(state.copyWith(biometricLogin: value));
  }

  Future<void> toggleLocation(bool value) async {
    await updateSettings(state.copyWith(locationSharing: value));
  }

  Future<void> toggleVisibility(bool value) async {
    await updateSettings(state.copyWith(profileVisibility: value));
  }

  Future<void> toggleContactPrivacy(bool value) async {
    await updateSettings(state.copyWith(showNumberToHosters: value));
  }
}

final privacySecurityProvider = StateNotifierProvider<PrivacySecurityNotifier, PrivacySettings>((ref) {
  return PrivacySecurityNotifier();
});

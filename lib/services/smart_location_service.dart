import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SmartLocationService {
  static final SmartLocationService _instance = SmartLocationService._internal();
  factory SmartLocationService() => _instance;
  SmartLocationService._internal();

  static const String _keyLat = 'smart_loc_lat';
  static const String _keyLng = 'smart_loc_lng';
  static const String _keyArrivalTime = 'smart_loc_arrival_time';
  static const String _keyLastUpdate = 'smart_loc_last_update';
  
  static const double _distanceThreshold = 500.0; // 500 meters
  static const int _stayDurationHours = 48; // 48 hours

  Timer? _trackingTimer;

  void initialize() {
    debugPrint('SmartLocationService: Initializing...');
    // Initial check on boot
    checkAndUpdateLocation();
    
    // Periodically check location every hour
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      checkAndUpdateLocation();
    });
  }

  Future<void> checkAndUpdateLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // We don't want to nag users here, just exit
        return;
      }

      // 2. Get current position
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final double? lastLat = prefs.getDouble(_keyLat);
      final double? lastLng = prefs.getDouble(_keyLng);
      final int? arrivalTimestamp = prefs.getInt(_keyArrivalTime);

      final now = DateTime.now();

      if (lastLat == null || lastLng == null || arrivalTimestamp == null) {
        // Initial tracking state
        await _resetTracking(prefs, position, now);
        debugPrint('SmartLocationService: Started tracking new location: ${position.latitude}, ${position.longitude}');
        return;
      }

      // 3. Calculate distance from potential "stay" location
      double distance = Geolocator.distanceBetween(
        lastLat,
        lastLng,
        position.latitude,
        position.longitude,
      );

      if (distance > _distanceThreshold) {
        // User moved too far, reset stay timer for new location
        await _resetTracking(prefs, position, now);
        debugPrint('SmartLocationService: User moved > 500m. Resetting stay timer.');
      } else {
        // User is still within the threshold area
        final arrivalTime = DateTime.fromMillisecondsSinceEpoch(arrivalTimestamp);
        final stayDuration = now.difference(arrivalTime);

        debugPrint('SmartLocationService: User in area for ${stayDuration.inHours} hours.');

        if (stayDuration.inHours >= _stayDurationHours) {
          // 4. STAY CRITERIA MET (48h)
          final lastUpdateStr = prefs.getString(_keyLastUpdate) ?? '';
          final lastUpdate = lastUpdateStr.isNotEmpty ? DateTime.parse(lastUpdateStr) : DateTime(2000);
          
          // Don't update Firestore more than once every 24h if in same area
          if (now.difference(lastUpdate).inHours >= 24) {
            await _updateProfileLocation(position);
            await prefs.setString(_keyLastUpdate, now.toIso8601String());
            debugPrint('SmartLocationService: 48h stay confirmed. Profile updated.');
          }
        }
      }
    } catch (e) {
      debugPrint('SmartLocationService Error: $e');
    }
  }

  Future<void> _resetTracking(SharedPreferences prefs, Position position, DateTime now) async {
    await prefs.setDouble(_keyLat, position.latitude);
    await prefs.setDouble(_keyLng, position.longitude);
    await prefs.setInt(_keyArrivalTime, now.millisecondsSinceEpoch);
  }

  Future<void> _updateProfileLocation(Position position) async {
    try {
      // 1. Reverse geocode
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String city = place.locality ?? place.subAdministrativeArea ?? '';
        final String locality = place.subLocality ?? '';
        final String currentLocation = locality.isNotEmpty ? '$locality, $city' : city;

        if (city.isEmpty) return;

        // 2. Update Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'info': {
              'location': currentLocation,
              'city': city,
            },
            'last_location_sync': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
          debugPrint('SmartLocationService: Firestore updated with $currentLocation');
        }
      }
    } catch (e) {
      debugPrint('SmartLocationService Geocoding/Firestore Error: $e');
    }
  }

  void dispose() {
    _trackingTimer?.cancel();
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentLocation;
  bool _isLoading = false;
  String _error = '';
  bool _isInitialized = false;

  Position? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isInitialized => _isInitialized;

  Future<bool> initializeLocation() async {
    if (_isInitialized) return true;
    
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Check location permission first
      final status = await Permission.location.status;
      if (status.isDenied) {
        final result = await Permission.location.request();
        if (result.isDenied) {
          _error = 'Location permission is required';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (status.isPermanentlyDenied) {
        _error = 'Location permission is permanently denied. Please enable it in settings.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await Geolocator.openLocationSettings();
        if (!serviceEnabled) {
          _error = 'Location services are disabled';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // Get current location
      _currentLocation = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to get location: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      await initializeLocation();
    }
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
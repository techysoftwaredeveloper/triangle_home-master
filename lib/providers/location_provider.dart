import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/services/isar_service.dart';

class LocationState {
  final String selectedCity;
  final String detectedCity;
  final String detectedLocality;
  final bool isDetecting;

  LocationState({
    this.selectedCity = '',
    this.detectedCity = '',
    this.detectedLocality = '',
    this.isDetecting = false,
  });

  LocationState copyWith({
    String? selectedCity,
    String? detectedCity,
    String? detectedLocality,
    bool? isDetecting,
  }) {
    return LocationState(
      selectedCity: selectedCity ?? this.selectedCity,
      detectedCity: detectedCity ?? this.detectedCity,
      detectedLocality: detectedLocality ?? this.detectedLocality,
      isDetecting: isDetecting ?? this.isDetecting,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final IsarService _isarService = IsarService();

  LocationNotifier() : super(LocationState()) {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final prefs = await _isarService.getLocationPreference();
    if (prefs != null) {
      state = state.copyWith(
        selectedCity: prefs.lastSelectedCity ?? '',
        detectedCity: prefs.lastDetectedCity ?? '',
      );
    }
  }

  void updateSelectedCity(String city) {
    state = state.copyWith(selectedCity: city);
    _isarService.saveLocationPreference(
      selected: city,
      detected: state.detectedCity,
    );
  }

  void updateDetectedCity(String city) {
    state = state.copyWith(detectedCity: city);
    _isarService.saveLocationPreference(
      selected: state.selectedCity,
      detected: city,
    );
  }

  void updateDetectedLocality(String locality) {
    state = state.copyWith(detectedLocality: locality);
  }

  void setDetecting(bool value) {
    state = state.copyWith(isDetecting: value);
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});

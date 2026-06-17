import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:triangle_home/core/app_config.dart';

class LocationApiService {
  final String baseUrl = '${AppConfig.apiBaseUrl}/api/locations';

  Future<List<String>> getMajorCities() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/major-cities'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['cities']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Location API Error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllLocations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/all'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['locations']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Location API Error: $e');
      return [];
    }
  }

  Future<bool> addLocation({
    required String city,
    required String locality,
  }) async {
    if (city.trim().isEmpty) return false;
    try {
      // 1. Fetch App Check token if active
      String? appCheckToken;
      try {
        appCheckToken = await FirebaseAppCheck.instance.getToken();
      } catch (_) {}

      // 2. Perform POST to backend API
      final response = await http.post(
        Uri.parse('$baseUrl/add'),
        headers: {
          'Content-Type': 'application/json',
          if (appCheckToken != null) 'X-Firebase-AppCheck': appCheckToken,
        },
        body: json.encode({
          'city': city.trim(),
          'locality': locality.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Location API Error registering locality: $e');
      return false;
    }
  }
}

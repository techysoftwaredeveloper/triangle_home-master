import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
}

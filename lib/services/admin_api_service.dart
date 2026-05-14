import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class AdminApiService {
  /**
   * STRICT NETWORK CONFIGURATION
   *
   * FOR PHYSICAL DEVICES (USB): Use 'localhost' and run:
   * adb reverse tcp:5000 tcp:5000
   *
   * FOR EMULATORS: Use '10.0.2.2'
   */
  static const String _host = 'localhost'; // Change to '10.0.2.2' ONLY if using emulator

  final String baseUrl = Platform.isAndroid ? 'http://$_host:5000/api' : 'http://localhost:5000/api';

  Future<String?> _getToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    final appCheckToken = await FirebaseAppCheck.instance.getToken();

    return {
      'Authorization': 'Bearer $token',
      'X-Firebase-AppCheck': appCheckToken ?? '',
      'Content-Type': 'application/json',
    };
  }

  // Statistics
  Future<Map<String, dynamic>> getStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data;
      }
      throw Exception(data['error'] ?? 'Failed to load stats');
    }
    throw Exception('Error ${response.statusCode}: Failed to connect to server');
  }

  // Users
  Future<Map<String, dynamic>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data;
      }
      throw Exception(data['error'] ?? 'Failed to load users');
    }
    throw Exception('Error ${response.statusCode}: Failed to load users');
  }

  Future<void> toggleUserStatus(String userId, String collection, String status) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/users/toggle-status'),
      headers: await _getHeaders(),
      body: json.encode({
        'userId': userId,
        'collection': collection,
        'status': status,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user status');
    }
  }

  // Properties
  Future<List<Map<String, dynamic>>> getAllProperties() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/properties'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load properties');
  }

  // Bookings
  Future<List<Map<String, dynamic>>> getAllBookings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/bookings'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load bookings');
  }

  Future<void> updatePropertyStatus(String propertyId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/admin/properties/$propertyId/status'),
      headers: await _getHeaders(),
      body: json.encode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update property status');
    }
  }

  // Hoster Approval
  Future<void> approveHoster(String hosterId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/hosters/$hosterId/approve'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to approve hoster');
    }
  }
}

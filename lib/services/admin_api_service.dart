import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';

class AdminApiService {
  /// NETWORK CONFIGURATION
  /// Default: 10.0.2.2 for Android Emulators, localhost for Web/iOS/Desktop.
  /// If using a physical Android device, replace '10.0.2.2' with your Machine's Local IP.
  static const String _customPhysicalIp = '192.168.31.25'; // Set your IP here
  
  static String get _host {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) {
      // Use standard emulator bridge by default. 
      // Change to _customPhysicalIp if debugging on a real phone.
      return '10.0.2.2'; 
    }
    return 'localhost';
  }

  final String baseUrl = 'http://$_host:5000/api';

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

  /// UNIFIED REQUEST WRAPPER WITH DIAGNOSTICS
  Future<dynamic> _performRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    
    debugPrint('📡 [API] REQUEST: $method $url');
    if (body != null) debugPrint('📦 [API] BODY: ${json.encode(body)}');

    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(url, headers: headers, body: json.encode(body));
          break;
        case 'PATCH':
          response = await http.patch(url, headers: headers, body: json.encode(body));
          break;
        case 'GET':
        default:
          response = await http.get(url, headers: headers);
          break;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ [API] SUCCESS: ${response.statusCode} - $endpoint');
        return json.decode(response.body);
      } else {
        final errorMsg = _extractErrorMessage(response);
        debugPrint('❌ [API] ERROR: ${response.statusCode} - $endpoint ($errorMsg)');
        throw Exception('Server Error ${response.statusCode}: $errorMsg');
      }
    } catch (e) {
      if (e is SocketException || e is http.ClientException) {
        debugPrint('⚠️ [API] CONNECTION FAILED: $method $url');
        debugPrint('👉 HINT: Check if server is running on port 5000 and if bridge IP ($_host) is correct.');
      } else {
        debugPrint('🚨 [API] UNEXPECTED ERROR: $e');
      }
      rethrow;
    }
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final data = json.decode(response.body);
      return data['error'] ?? data['message'] ?? 'No detail provided';
    } catch (_) {
      return 'Could not parse error response';
    }
  }

  // Statistics
  Future<Map<String, dynamic>> getStats() async {
    final data = await _performRequest(method: 'GET', endpoint: '/admin/stats');
    if (data['success'] == true) return data;
    throw Exception(data['error'] ?? 'Failed to load stats');
  }

  // Users
  Future<Map<String, dynamic>> getAllUsers() async {
    final data = await _performRequest(method: 'GET', endpoint: '/admin/users');
    if (data['success'] == true) return data;
    throw Exception(data['error'] ?? 'Failed to load users');
  }

  Future<void> toggleUserStatus(
    String userId, {
    String? status,
    bool? isActive,
  }) async {
    await _performRequest(
      method: 'POST',
      endpoint: '/admin/users/toggle-status',
      body: {
        'userId': userId,
        if (status != null) 'status': status,
        if (isActive != null) 'isActive': isActive,
      },
    );
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _performRequest(
      method: 'PATCH',
      endpoint: '/admin/users/$userId/role',
      body: {'role': role},
    );
  }

  // Properties
  Future<List<Map<String, dynamic>>> getAllProperties() async {
    final List data = await _performRequest(method: 'GET', endpoint: '/admin/properties');
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> updatePropertyStatus(String propertyId, String status) async {
    await _performRequest(
      method: 'PATCH',
      endpoint: '/admin/properties/$propertyId/status',
      body: {'status': status},
    );
  }

  // Bookings
  Future<List<Map<String, dynamic>>> getAllBookings() async {
    final List data = await _performRequest(method: 'GET', endpoint: '/admin/bookings');
    return data.cast<Map<String, dynamic>>();
  }

  // Hoster Approval
  Future<void> approveHoster(String hosterId) async {
    await _performRequest(method: 'POST', endpoint: '/admin/hosters/$hosterId/approve');
  }

  // Hoster Re-submission
  Future<void> resubmitHoster() async {
    await _performRequest(method: 'POST', endpoint: '/admin/resubmit-hoster');
  }

  // Suggestions
  Future<void> updateSuggestionStatus(String id, String status) async {
    await _performRequest(
      method: 'PATCH',
      endpoint: '/admin/suggestions/$id/status',
      body: {'status': status},
    );
  }

  Future<void> convertSuggestion(String id) async {
    await _performRequest(method: 'POST', endpoint: '/suggestions/$id/convert');
  }

  // Reports
  Future<void> updateReportStatus(
    String id,
    String status, {
    String? resolution,
  }) async {
    await _performRequest(
      method: 'PATCH',
      endpoint: '/admin/reports/$id/status',
      body: {
        'status': status,
        if (resolution != null) 'resolution': resolution,
      },
    );
  }
}

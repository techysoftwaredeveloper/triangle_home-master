import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:triangle_home/core/app_config.dart';

class AdminApiService {
  /// Base URL is resolved from AppConfig based on the current environment.
  /// - Dev: http://192.168.31.25:5000 (local server)
  /// - Prod: https://api.trianglehomes.com
  String get baseUrl => '${AppConfig.apiBaseUrl}/api';

  Future<String?> _getToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    final appCheckToken = await FirebaseAppCheck.instance.getToken();
    
    if (appCheckToken == null && !kDebugMode) {
      debugPrint('⚠️ [API] Warning: App Check token is null. Request will likely fail on production server.');
    }

    return {
      'Authorization': 'Bearer $token',
      'X-Firebase-AppCheck': appCheckToken ?? '',
      'Content-Type': 'application/json',
    };
  }

  /// UNIFIED REQUEST WRAPPER WITH DIAGNOSTICS
  Future<dynamic> performRequest({
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
        debugPrint('👉 HINT: Check if server is running at $baseUrl');
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
    final data = await performRequest(method: 'GET', endpoint: '/admin/stats');
    if (data['success'] == true) return data;
    throw Exception(data['error'] ?? 'Failed to load stats');
  }

  // Users
  Future<Map<String, dynamic>> getAllUsers() async {
    final data = await performRequest(method: 'GET', endpoint: '/admin/users');
    if (data['success'] == true) return data;
    throw Exception(data['error'] ?? 'Failed to load users');
  }

  Future<void> toggleUserStatus(
    String userId, {
    String? status,
    bool? isActive,
  }) async {
    await performRequest(
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
    await performRequest(
      method: 'PATCH',
      endpoint: '/admin/users/$userId/role',
      body: {'role': role},
    );
  }

  // Properties
  Future<List<Map<String, dynamic>>> getAllProperties() async {
    final List data = await performRequest(method: 'GET', endpoint: '/admin/properties');
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> updatePropertyStatus(String propertyId, String status) async {
    await performRequest(
      method: 'PATCH',
      endpoint: '/admin/properties/$propertyId/status',
      body: {'status': status},
    );
  }

  Future<Map<String, dynamic>> reconcileProperty(String propertyId) async {
    return await performRequest(
      method: 'POST',
      endpoint: '/properties/$propertyId/reconcile',
    );
  }

  // Bookings
  Future<List<Map<String, dynamic>>> getAllBookings() async {
    final List data = await performRequest(method: 'GET', endpoint: '/admin/bookings');
    return data.cast<Map<String, dynamic>>();
  }

  // Hoster Approval
  Future<void> approveHoster(String hosterId) async {
    await performRequest(method: 'POST', endpoint: '/admin/hosters/$hosterId/approve');
  }

  // Hoster Re-submission
  Future<void> resubmitHoster() async {
    await performRequest(method: 'POST', endpoint: '/admin/resubmit-hoster');
  }

  // Suggestions
  Future<void> updateSuggestionStatus(String id, String status) async {
    await performRequest(
      method: 'PATCH',
      endpoint: '/admin/suggestions/$id/status',
      body: {'status': status},
    );
  }

  Future<void> convertSuggestion(String id) async {
    await performRequest(method: 'POST', endpoint: '/suggestions/$id/convert');
  }

  // Reports
  Future<void> updateReportStatus(
    String id,
    String status, {
    String? resolution,
  }) async {
    await performRequest(
      method: 'PATCH',
      endpoint: '/admin/reports/$id/status',
      body: {
        'status': status,
        if (resolution != null) 'resolution': resolution,
      },
    );
  }
}

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all student-related API calls.
/// Separated from AuthService for clean architecture.
class StudentService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8015/api/v1/auth';
    if (Platform.isAndroid) return 'http://10.0.2.2:8015/api/v1/auth';
    if (Platform.isIOS) return 'https://uhezt-2402-d000-8130-9a35-e892-f7e9-99ba-92a2.free.pinggy.net/api/v1/auth'; // Pinggy Public Tunnel
    return 'http://127.0.0.1:8015/api/v1/auth';
  }

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Add a student under the current parent.
  /// Returns null on success, or an error message string on failure.
  Future<String?> addStudent(Map<String, dynamic> studentData) async {
    try {
      final token = await _getAccessToken();
      if (token == null) return 'Not authenticated.';

      final response = await http.post(
        Uri.parse('$_baseUrl/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(studentData),
      );

      if (response.statusCode == 201) {
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        if (data['detail'] is String) {
          return data['detail'];
        } else if (data['detail'] is List) {
          final err = data['detail'][0];
          final field = err['loc']?.last?.toString() ?? 'Field';
          return '$field: ${err['msg']}';
        }
        return 'Failed to add student.';
      }
    } catch (e) {
      return 'Failed to connect to the server.';
    }
  }

  /// Get list of students for the current authenticated parent.
  /// Returns only students belonging to this parent (server-enforced).
  Future<List<dynamic>> getStudents() async {
    try {
      final token = await _getAccessToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$_baseUrl/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Update an existing student's details.
  /// Returns null on success, or an error message string on failure.
  Future<String?> updateStudent(String studentId, Map<String, dynamic> studentData) async {
    try {
      final token = await _getAccessToken();
      if (token == null) return 'Not authenticated.';

      final response = await http.put(
        Uri.parse('$_baseUrl/students/$studentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(studentData),
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        if (data['detail'] is String) {
          return data['detail'];
        } else if (data['detail'] is List) {
          final err = data['detail'][0];
          final field = err['loc']?.last?.toString() ?? 'Field';
          return '$field: ${err['msg']}';
        }
        return 'Failed to update student.';
      }
    } catch (e) {
      return 'Failed to connect to the server.';
    }
  }
}

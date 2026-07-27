import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Handles all student-related API calls.
/// Separated from AuthService for clean architecture.
class StudentService {
  static String get _baseUrl {
    // Local Testing (using your Mac's IP address):
    // return 'http://127.0.0.1:8015/api/v1/auth';
    
    // Cloud Server (Render):
    return 'https://adaptedmind-auth-api.onrender.com/api/v1/auth';
  }

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Add a student under the current parent.
  /// Returns a Map with student data on success (including 'id'), or a Map with 'error' key on failure.
  Future<Map<String, dynamic>> addStudent(Map<String, dynamic> studentData) async {
    try {
      final token = await _getAccessToken();
      if (token == null) return {'error': 'Not authenticated.'};

      final response = await http.post(
        Uri.parse('$_baseUrl/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(studentData),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final data = jsonDecode(response.body);
        if (data['detail'] is String) {
          return {'error': data['detail']};
        } else if (data['detail'] is List) {
          final err = data['detail'][0];
          final field = err['loc']?.last?.toString() ?? 'Field';
          return {'error': '$field: ${err["msg"]}'};
        }
        return {'error': 'Failed to add student.'};
      }
    } catch (e) {
      return {'error': 'Failed to connect to the server.'};
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

  /// Delete a student account.
  /// Returns null on success, or an error message string on failure.
  Future<String?> deleteStudent(String studentId) async {
    try {
      final token = await _getAccessToken();
      if (token == null) return 'Not authenticated.';

      final response = await http.delete(
        Uri.parse('$_baseUrl/students/$studentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        if (data['detail'] is String) {
          return data['detail'];
        }
        return 'Failed to delete student.';
      }
    } catch (e) {
      return 'Failed to connect to the server.';
    }
  }

  /// Submit assessment results for an existing student.
  /// Returns null on success, or an error message string on failure.
  Future<String?> submitAssessment(String studentId, List<bool> assessmentResults) async {
    try {
      final token = await _getAccessToken();
      if (token == null) return 'Not authenticated.';

      final response = await http.patch(
        Uri.parse('$_baseUrl/students/$studentId/assessment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'assessment_results': assessmentResults}),
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        if (data['detail'] is String) {
          return data['detail'];
        }
        return 'Failed to submit assessment.';
      }
    } catch (e) {
      return 'Failed to connect to the server.';
    }
  }

  /// Sync progress data to the backend for an existing student.
  /// Returns null on success, or an error message string on failure.
  Future<String?> syncProgress(String studentId, List<String> completedActivities, Map<String, int> activityScores) async {
    try {
      final token = await _getAccessToken();
      if (token == null) return 'Not authenticated.';

      final response = await http.patch(
        Uri.parse('$_baseUrl/students/$studentId/progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'completed_activities': completedActivities,
          'activity_scores': activityScores,
        }),
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        if (data['detail'] is String) {
          return data['detail'];
        }
        return 'Failed to sync progress.';
      }
    } catch (e) {
      return 'Failed to connect to the server.';
    }
  }

  /// Submit telemetry session data to the backend.
  /// Returns null on success, or an error message string on failure.
  Future<String?> submitTelemetry(Map<String, dynamic> payload) async {
    try {
      final token = await _getAccessToken();
      if (token == null) return 'Not authenticated.';

      final response = await http.post(
        Uri.parse('$_baseUrl/telemetry'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        if (data['detail'] is String) {
          return data['detail'];
        }
        return 'Failed to submit telemetry.';
      }
    } catch (e) {
      return 'Failed to connect to the server.';
    }
  }
}

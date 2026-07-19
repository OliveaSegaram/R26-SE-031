import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8015/api/v1/auth';
    if (Platform.isAndroid) return 'http://10.0.2.2:8015/api/v1/auth';
    if (Platform.isIOS) return 'http://Isaras-MacBook-Air.local:8015/api/v1/auth'; // Mac's hostname
    return 'http://127.0.0.1:8015/api/v1/auth';
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Success. 
        final data = jsonDecode(response.body);
        String accessToken = data['access_token'];
        String refreshToken = data['refresh_token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        
        return null;
      } else {
        // e.g. 401 Unauthorized
        final data = jsonDecode(response.body);
        return data['detail'] ?? 'Incorrect email or password.';
      }
    } catch (e) {
      return 'Failed to connect to the authentication server.';
    }
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'role': 'student',
        }),
      );

      if (response.statusCode == 201) {
        // Success
        return null; 
      } else {
        // e.g. 422 Validation Error or 400 Bad Request
        final data = jsonDecode(response.body);
        
        if (data['detail'] is String) {
          return data['detail'];
        } else if (data['detail'] is List) {
          // Pydantic validation error format
          final err = data['detail'][0];
          final field = err['loc']?.last?.toString() ?? 'Field';
          return '$field: ${err['msg']}';
        }
        return 'Failed to sign up. Please check your inputs.';
      }
    } catch (e) {
      return 'Failed to connect to the authentication server.';
    }
  }

  /// Helper to get the token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Change Password
  Future<String?> changePassword(String oldPassword, String newPassword) async {
    try {
      final token = await getAccessToken();
      if (token == null) return 'Not authenticated.';

      final response = await http.post(
        Uri.parse('$_baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
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
        return 'Failed to change password.';
      }
    } catch (e) {
      return 'Failed to connect to the server.';
    }
  }

  /// Add a student under the current parent
  Future<String?> addStudent(Map<String, dynamic> studentData) async {
    try {
      final token = await getAccessToken();
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

  /// Update an existing student
  Future<String?> updateStudent(String studentId, Map<String, dynamic> studentData) async {
    try {
      final token = await getAccessToken();
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

  /// Get list of students for current parent
  Future<List<dynamic>> getStudents() async {
    try {
      final token = await getAccessToken();
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

  /// Verify parent password
  Future<String?> verifyPassword(String password) async {
    try {
      final token = await getAccessToken();
      if (token == null) return 'Not authenticated.';

      final response = await http.post(
        Uri.parse('$_baseUrl/verify-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        if (data['detail'] is String) {
          return data['detail'];
        }
        return 'Incorrect password.';
      }
    } catch (e) {
      return 'Failed to connect to the server.';
    }
  }
}

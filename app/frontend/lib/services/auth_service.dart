import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Handles authentication-only API calls: login, signup, tokens, passwords.
/// Student management is in StudentService.
class AuthService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8015/api/v1/auth';
    if (Platform.isAndroid) return 'http://10.0.2.2:8015/api/v1/auth';
    if (Platform.isIOS) return 'https://uhezt-2402-d000-8130-9a35-e892-f7e9-99ba-92a2.free.pinggy.net/api/v1/auth'; // Pinggy Public Tunnel
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
        final data = jsonDecode(response.body);
        String accessToken = data['access_token'];
        String refreshToken = data['refresh_token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        
        return null;
      } else {
        final data = jsonDecode(response.body);
        return data['detail'] ?? 'Incorrect email or password.';
      }
    } catch (e) {
      return 'Network Error: $e';
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
          'role': 'parent',
        }),
      );

      if (response.statusCode == 201) {
        // Automatically log the user in to get tokens and override any previous session
        return await login(email, password);
      } else {
        final data = jsonDecode(response.body);
        
        if (data['detail'] is String) {
          return data['detail'];
        } else if (data['detail'] is List) {
          final err = data['detail'][0];
          final field = err['loc']?.last?.toString() ?? 'Field';
          return '$field: ${err['msg']}';
        }
        return 'Failed to sign up. Please check your inputs.';
      }
    } catch (e) {
      print('SIGNUP ERROR: $e');
      return 'Network Error: $e';
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
        return null;
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
        return null;
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

  /// Clear tokens (logout)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
}

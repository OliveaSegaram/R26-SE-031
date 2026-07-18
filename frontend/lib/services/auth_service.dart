import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

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
        // final data = jsonDecode(response.body);
        // String token = data['access_token'];
        // You could save this token to SharedPreferences here.
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
}

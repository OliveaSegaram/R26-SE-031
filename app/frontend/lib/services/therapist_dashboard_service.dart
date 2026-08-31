import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class TherapistDashboardService {
  // Therapist dashboard routes live on the auth service (port 8015), NOT the telemetry service.
  String get _baseUrl => ApiConfig.therapistDashboardBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getOverview(String studentId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$studentId/overview'), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {};
    } catch (_) { return {}; }
  }

  Future<Map<String, dynamic>> getC1Behavioral(String studentId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$studentId/c1-behavioral'), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {};
    } catch (_) { return {}; }
  }

  Future<Map<String, dynamic>> getC2Speech(String studentId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$studentId/c2-speech'), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {};
    } catch (_) { return {}; }
  }

  Future<Map<String, dynamic>> getC3Profile(String studentId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$studentId/c3-profile'), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {};
    } catch (_) { return {}; }
  }

  Future<Map<String, dynamic>> getC4Adaptive(String studentId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$studentId/c4-adaptive'), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {};
    } catch (_) { return {}; }
  }
}

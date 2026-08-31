import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class ParentDashboardService {
  // Parent dashboard routes live on the auth service (port 8015), NOT the telemetry service.
  String get _baseUrl => ApiConfig.parentDashboardBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getOverview(String studentId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$studentId/overview'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<Map<String, dynamic>> getSkills(String studentId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$studentId/skills'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<Map<String, dynamic>> getLearningPattern(String studentId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$studentId/learning-pattern'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  Future<Map<String, dynamic>> getActivityHistory(String studentId, [String filter = "limit=10"]) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$studentId/activity-history?$filter'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }


}

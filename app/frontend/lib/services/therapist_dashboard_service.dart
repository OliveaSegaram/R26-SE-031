import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class TherapistDashboardService {
  String get _baseUrl => ApiConfig.therapistDashboardBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getOverview(String studentId) async {
    final response = await http.get(Uri.parse('$_baseUrl/$studentId/overview'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load overview data');
  }

  Future<Map<String, dynamic>> getC1Behavioral(String studentId) async {
    final response = await http.get(Uri.parse('$_baseUrl/$studentId/c1-behavioral'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load C1 data');
  }

  Future<Map<String, dynamic>> getC2Speech(String studentId) async {
    final response = await http.get(Uri.parse('$_baseUrl/$studentId/c2-speech'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load C2 data');
  }

  Future<Map<String, dynamic>> getC3Profile(String studentId) async {
    final response = await http.get(Uri.parse('$_baseUrl/$studentId/c3-profile'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load C3 data');
  }

  Future<Map<String, dynamic>> getC4Adaptive(String studentId) async {
    final response = await http.get(Uri.parse('$_baseUrl/$studentId/c4-adaptive'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load C4 data');
  }
  
  Future<Uint8List> downloadReport(String studentId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/$studentId/report'),
      headers: {...headers, 'Accept': 'application/pdf'},
    );
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Failed to download report');
  }
}

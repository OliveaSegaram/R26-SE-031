import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class Task02Api {
  Task02Api({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  final String baseUrl;

  Future<Map<String, dynamic>> startSession({String studentId = 'guest'}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/task02/session/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'student_id': studentId}),
    );
    if (res.statusCode != 200) {
      throw Exception('Start failed: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitAnswer({
    required String sessionId,
    required String answer,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/task02/session/answer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'session_id': sessionId, 'answer': answer}),
    );
    if (res.statusCode != 200) {
      throw Exception('Answer failed: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> nextQuestion(String sessionId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v1/task02/session/$sessionId/next'),
    );
    if (res.statusCode != 200) {
      throw Exception('Next failed: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

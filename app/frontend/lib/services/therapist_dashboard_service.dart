import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class TherapistDashboardService {
  final String _baseUrl = ApiConfig.authBaseUrl.replaceFirst('/auth', '/therapist/students');

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
      return _getMockOverview(studentId);
    } catch (_) { return _getMockOverview(studentId); }
  }

  Future<Map<String, dynamic>> getBehavior(String studentId, [String filter = "limit=10"]) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$studentId/behavior?$filter'), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
      return _getMockBehavior(studentId);
    } catch (_) { return _getMockBehavior(studentId); }
  }

  Future<Map<String, dynamic>> getKinematics(String studentId, [String filter = "limit=10"]) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$studentId/kinematics?$filter'), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
      return _getMockKinematics(studentId);
    } catch (_) { return _getMockKinematics(studentId); }
  }

  Future<Map<String, dynamic>> getProfile(String studentId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$studentId/profile'), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
      return _getMockProfile(studentId);
    } catch (_) { return _getMockProfile(studentId); }
  }

  Future<Map<String, dynamic>> getKnowledge(String studentId, [String filter = "limit=10"]) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$studentId/knowledge?$filter'), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
      return _getMockKnowledge(studentId);
    } catch (_) { return _getMockKnowledge(studentId); }
  }

  Future<Map<String, dynamic>> getAdaptiveHistory(String studentId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$studentId/adaptive-history'), headers: await _getHeaders());
      if (response.statusCode == 200) return jsonDecode(response.body);
      return _getMockAdaptiveHistory(studentId);
    } catch (_) { return _getMockAdaptiveHistory(studentId); }
  }

  // Mocks
  Map<String, dynamic> _getMockOverview(String studentId) => {
    "accuracy": 75, "median_latency_ms": 2100, "hesitation_rate": 0.18, "misclick_rate": 0.08, "fatigue_score": 0.32,
    "primary_learning_pattern": "Visual-Orthographic", "overall_mastery": 0.68, "current_kc": "Letter Identity", "current_difficulty": 0.7,
    "model_version": "C3-v1", "feature_version": "F-v1"
  };

  Map<String, dynamic> _getMockBehavior(String studentId) => {
    "accuracy_trend": [{"session": "S1", "accuracy": 50}, {"session": "S2", "accuracy": 60}, {"session": "S3", "accuracy": 75}],
    "latency_trend": [{"session": "S1", "latency_ms": 3000}, {"session": "S2", "latency_ms": 2500}, {"session": "S3", "latency_ms": 2100}],
    "fatigue_trend": [{"session": "S1", "fatigue": 0.4}, {"session": "S2", "fatigue": 0.35}, {"session": "S3", "fatigue": 0.32}],
    "learner_indices": {"visual_processing": 68.0, "phonological_task": 71.0, "motor_interaction": 82.0, "attention_stability": 64.0},
    "error_composition": {"correct": 75, "incorrect": 17, "misclick": 8}
  };

  Map<String, dynamic> _getMockKinematics(String studentId) => {
    "touch_trajectories": [{"target": "අ", "selected": "ආ", "path": [{"x": 10, "y": 20}, {"x": 50, "y": 80}, {"x": 90, "y": 100}]}],
    "oci_trend": [{"session": "S1", "oci": 0.4}, {"session": "S2", "oci": 0.5}, {"session": "S3", "oci": 0.67}],
    "path_efficiency_trend": [{"session": "S1", "efficiency": 0.8}, {"session": "S2", "efficiency": 0.75}, {"session": "S3", "efficiency": 0.63}],
    "top_confusion_pairs": [{"target": "අ", "selected": "ආ", "count": 5}],
    "feature_comparison": {"path_efficiency": 0.63, "oci": 0.67, "dwell_time_s": 0.21, "normalized_jerk": 3.82}
  };

  Map<String, dynamic> _getMockProfile(String studentId) => {
    "selected_pattern": "Visual-Orthographic Pattern",
    "probabilities": {"Typical": 0.08, "Visual-Orthographic": 0.71, "Phonological": 0.12, "Combined": 0.09},
    "shap_values": [{"feature": "OCI", "contribution": 0.31}],
    "top_shap_features": ["OCI", "Response Latency", "Path Efficiency"]
  };

  Map<String, dynamic> _getMockKnowledge(String studentId) => {
    "knowledge_components": {"Letter Identity": 0.72, "Visual Discrimination": 0.84},
    "mastery_trend": [{"attempt": 1, "mastery": 0.3}, {"attempt": 2, "mastery": 0.45}]
  };

  Map<String, dynamic> _getMockAdaptiveHistory(String studentId) => {
    "learner_ability": 0.55, "item_difficulty": 0.45,
    "timeline": [{"attempt": 1, "mastery": 0.30, "difficulty": 0.40, "scaffold_level": 0, "scaffold_desc": "None"}]
  };
}

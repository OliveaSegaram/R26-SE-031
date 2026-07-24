import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client for intervention-service-v1 (C4) rule-based pipeline.
class C4Api {
  C4Api({this.baseUrl = 'http://127.0.0.1:8013'});

  final String baseUrl;

  Future<Map<String, dynamic>> trigger({
    required String childId,
    required String word,
    double phonologicalStrainIndex = 0.6,
    double sessionFatigueIndex = 0.0,
    List<int> errorPatternVector = const [0, 0, 0, 0],
    String? zoneHint,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/intervention/trigger'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'child_id': childId,
        'word': word,
        'phonological_strain_index': phonologicalStrainIndex,
        'session_fatigue_index': sessionFatigueIndex,
        'error_pattern_vector': errorPatternVector,
        if (zoneHint != null) 'zone_hint': zoneHint,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> startCycle({
    required String childId,
    required String tag,
    required dynamic specificInstance,
    String? word,
    String? cycleMode,
    String? localizationZone,
    double? localizationConfidence,
    List<String>? errorPatternFlags,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/intervention/cycle/start'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'child_id': childId,
        'tag': tag,
        'specific_instance': specificInstance,
        if (word != null) 'word': word,
        if (cycleMode != null) 'cycle_mode': cycleMode,
        if (localizationZone != null) 'localization_zone': localizationZone,
        if (localizationConfidence != null)
          'localization_confidence': localizationConfidence,
        if (errorPatternFlags != null) 'error_pattern_flags': errorPatternFlags,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> respond({
    required String cycleId,
    required String stage,
    Map<String, dynamic> response = const {},
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/intervention/cycle/respond'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'cycle_id': cycleId,
        'stage': stage,
        'response': response,
      }),
    );
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 400) {
      throw Exception('C4 ${res.statusCode}: $body');
    }
    return Map<String, dynamic>.from(body as Map);
  }
}

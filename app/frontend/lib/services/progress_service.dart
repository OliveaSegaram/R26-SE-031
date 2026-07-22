import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  SharedPreferences? _prefs;

  // Constants
  static const String _keyCurrentStudentId = 'current_student_id';
  static const String _keyCompletedActivitiesPrefix = 'completed_'; // + studentId
  static const String _keyActivityScoresPrefix = 'scores_'; // + studentId

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Student Management ---
  
  Future<void> setCurrentStudentId(String studentId) async {
    await _prefs?.setString(_keyCurrentStudentId, studentId);
  }

  String get currentStudentId {
    return _prefs?.getString(_keyCurrentStudentId) ?? 'test_student_001';
  }

  // --- Activity Progression ---

  /// Marks an activity as completed for the current student
  Future<void> markActivityCompleted(String skillId, String activityId) async {
    final key = '$_keyCompletedActivitiesPrefix$currentStudentId';
    List<String> completed = _prefs?.getStringList(key) ?? [];
    
    final activityKey = '${skillId}_$activityId';
    if (!completed.contains(activityKey)) {
      completed.add(activityKey);
      await _prefs?.setStringList(key, completed);
    }
  }

  /// Checks if an activity is unlocked. 
  /// In micro-dosing, an activity is unlocked if it's the first activity, 
  /// or if the previous activity in the sequence is completed.
  /// For this MVP, we assume it's unlocked if we just check if it's completed, 
  /// but typically we need the full list of activities to determine the previous one.
  bool isActivityCompleted(String skillId, String activityId) {
    final key = '$_keyCompletedActivitiesPrefix$currentStudentId';
    List<String> completed = _prefs?.getStringList(key) ?? [];
    return completed.contains('${skillId}_$activityId');
  }

  // --- Scoring ---

  Future<void> saveActivityScore(String skillId, String activityId, int score) async {
    final key = '$_keyActivityScoresPrefix$currentStudentId';
    String? scoresJson = _prefs?.getString(key);
    Map<String, dynamic> scores = scoresJson != null ? json.decode(scoresJson) : {};
    
    scores['${skillId}_$activityId'] = score;
    await _prefs?.setString(key, json.encode(scores));
  }

  int getActivityScore(String skillId, String activityId) {
    final key = '$_keyActivityScoresPrefix$currentStudentId';
    String? scoresJson = _prefs?.getString(key);
    if (scoresJson == null) return 0;
    
    Map<String, dynamic> scores = json.decode(scoresJson);
    return scores['${skillId}_$activityId'] ?? 0;
  }
}

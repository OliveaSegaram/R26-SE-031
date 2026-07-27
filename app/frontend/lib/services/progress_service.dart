import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'student_service.dart';

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  SharedPreferences? _prefs;

  // Constants
  static const String _keyCurrentStudentId = 'current_student_id';
  static const String _keyCompletedActivitiesPrefix = 'completed_'; // + studentId
  static const String _keyActivityScoresPrefix = 'scores_'; // + studentId
  static const String _keyLastActiveDate = 'last_active_date';
  static const String _keyStreakCount = 'streak_count';

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

  // --- Cloud Sync ---

  /// Loads progress data from the backend student payload into local storage
  Future<void> loadFromCloud(Map<String, dynamic> studentData) async {
    final String studentId = studentData['id'] ?? currentStudentId;
    
    // Extract cloud data
    List<dynamic> cloudCompleted = studentData['completed_activities'] ?? [];
    Map<String, dynamic> cloudScores = studentData['activity_scores'] ?? {};
    
    // Convert types
    List<String> completedActivities = cloudCompleted.map((e) => e.toString()).toList();
    Map<String, int> scores = cloudScores.map((key, value) => MapEntry(key, value as int));

    // Save to local SharedPreferences
    final completedKey = '$_keyCompletedActivitiesPrefix$studentId';
    final scoresKey = '$_keyActivityScoresPrefix$studentId';
    
    await _prefs?.setStringList(completedKey, completedActivities);
    await _prefs?.setString(scoresKey, json.encode(scores));
  }

  void _triggerCloudSync() {
    final completedKey = '$_keyCompletedActivitiesPrefix$currentStudentId';
    final scoresKey = '$_keyActivityScoresPrefix$currentStudentId';
    
    List<String> completed = _prefs?.getStringList(completedKey) ?? [];
    String? scoresJson = _prefs?.getString(scoresKey);
    Map<String, int> scores = {};
    if (scoresJson != null) {
      final Map<String, dynamic> decoded = json.decode(scoresJson);
      scores = decoded.map((key, value) => MapEntry(key, value as int));
    }
    
    // Fire and forget network call
    StudentService().syncProgress(currentStudentId, completed, scores);
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
      // Streak only counts if an activity was actually completed today
      await updateAndGetStreak();
      _triggerCloudSync();
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

  /// Get the number of completed activities for a given skill
  int getCompletedActivitiesCount(String skillId) {
    final key = '$_keyCompletedActivitiesPrefix$currentStudentId';
    List<String> completed = _prefs?.getStringList(key) ?? [];
    
    int count = 0;
    for (String id in completed) {
      if (id.startsWith('${skillId}_')) {
        count++;
      }
    }
    return count;
  }

  /// Get the normalized progress for a skill (0.0 to 1.0)
  double getSkillProgress(String skillId, int totalActivities) {
    if (totalActivities <= 0) return 0.0;
    int completed = getCompletedActivitiesCount(skillId);
    return (completed / totalActivities).clamp(0.0, 1.0);
  }

  /// Get a list of all completed activity keys for a given skill
  List<String> getCompletedActivitiesForSkill(String skillId) {
    final key = '$_keyCompletedActivitiesPrefix$currentStudentId';
    List<String> completed = _prefs?.getStringList(key) ?? [];
    
    return completed.where((id) => id.startsWith('${skillId}_')).toList();
  }

  // --- Scoring ---

  Future<void> saveActivityScore(String skillId, String activityId, int score) async {
    final key = '$_keyActivityScoresPrefix$currentStudentId';
    String? scoresJson = _prefs?.getString(key);
    Map<String, dynamic> scores = scoresJson != null ? json.decode(scoresJson) : {};
    
    scores['${skillId}_$activityId'] = score;
    await _prefs?.setString(key, json.encode(scores));
    _triggerCloudSync();
  }

  int getActivityScore(String skillId, String activityId) {
    final key = '$_keyActivityScoresPrefix$currentStudentId';
    String? scoresJson = _prefs?.getString(key);
    if (scoresJson == null) return 0;
    
    Map<String, dynamic> scores = json.decode(scoresJson);
    return scores['${skillId}_$activityId'] ?? 0;
  }

  // --- Streak Tracking ---

  /// Returns the current streak count without updating it
  int get currentStreak => _prefs?.getInt(_keyStreakCount) ?? 0;

  /// Checks today's date vs last active date. Increments streak if consecutive day,
  /// resets to 1 if broken, keeps it the same if called on the same day.
  Future<int> updateAndGetStreak() async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final lastActiveStr = _prefs?.getString(_keyLastActiveDate);
    int streak = _prefs?.getInt(_keyStreakCount) ?? 0;

    if (lastActiveStr == null) {
      streak = 1;
    } else {
      final parts = lastActiveStr.split('-');
      final lastActive = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final today0 = DateTime(today.year, today.month, today.day);
      final diff = today0.difference(lastActive).inDays;
      if (diff == 0) {
        // Same day — no change
      } else if (diff == 1) {
        streak += 1;
      } else {
        streak = 1; // Streak broken
      }
    }

    await _prefs?.setString(_keyLastActiveDate, todayStr);
    await _prefs?.setInt(_keyStreakCount, streak);
    return streak;
  }
}

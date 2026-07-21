import 'package:flutter/material.dart';
import '../screens/games/visual_skills/activity1_spot_difference.dart';
import '../screens/games/visual_skills/activity2_pattern.dart';
import '../screens/games/visual_skills/activity3_missing_picture.dart';
import '../screens/games/visual_skills/activity4_visual_memory.dart';
import '../screens/games/visual_skills/activity5_category_sorting.dart';
import '../screens/games/visual_skills/activity6_hidden_shape.dart';
import '../screens/games/visual_skills/activity7_size_ordering.dart';

class SessionActivity {
  final Widget screen;
  final String title;
  final int durationSeconds;

  SessionActivity({
    required this.screen,
    required this.title,
    required this.durationSeconds,
  });
}

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  /// Generates a curated 10-minute playlist of activities based on the student's level.
  /// For now, it returns a static progressive list.
  List<SessionActivity> generateDailySession() {
    return [
      // Phase 1: Warm-up (Visual Skills - ~2 mins)
      SessionActivity(
        screen: const Activity1SpotDifference(),
        title: 'වෙනස් රූපය සොයන්න',
        durationSeconds: 60,
      ),
      SessionActivity(
        screen: const Activity2Pattern(),
        title: 'රටාව සම්පූර්ණ කරන්න',
        durationSeconds: 60,
      ),
      // Phase 2: Core Cognitive/Phonics (Visual/Memory - ~2.5 mins)
      SessionActivity(
        screen: const Activity3MissingPicture(),
        title: 'අඩු රූපය සොයන්න',
        durationSeconds: 60,
      ),
      SessionActivity(
        screen: const Activity4VisualMemory(),
        title: 'මතක තබා ගන්න',
        durationSeconds: 90,
      ),
      // Phase 3: Application (Sorting/Logic - ~2.5 mins)
      SessionActivity(
        screen: const Activity5CategorySorting(),
        title: 'වර්ගීකරණය කරන්න',
        durationSeconds: 90,
      ),
      SessionActivity(
        screen: const Activity6HiddenShape(),
        title: 'සැඟවුණු හැඩය සොයන්න',
        durationSeconds: 60,
      ),
      // Phase 4: Mastery (Size/Position logic - ~3 mins)
      SessionActivity(
        screen: const Activity7SizeOrdering(),
        title: 'ප්‍රමාණය අනුව පෙළගස්වන්න',
        durationSeconds: 90,
      ),
    ];
  }
}

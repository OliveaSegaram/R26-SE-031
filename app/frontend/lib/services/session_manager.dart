import 'package:flutter/material.dart';
import '../models/curriculum_models.dart';
import '../screens/games/game_factory.dart';

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
        screen: GameFactory.buildGame(ActivityNode(
          id: 'act_1',
          title: 'වෙනස් රූපය සොයන්න',
          telemetryTags: ['recognizing'],
          templateType: 'hidden_picture_game',
          rounds: [
            {'target': '🌸', 'distractors': ['🌳'], 'target_count': 1, 'distractor_count': 2, 'correct_index': 0},
            {'target': '🍎', 'distractors': ['🍌'], 'target_count': 1, 'distractor_count': 3, 'correct_index': 1},
          ],
        )),
        title: 'වෙනස් රූපය සොයන්න',
        durationSeconds: 60,
      ),
      SessionActivity(
        screen: GameFactory.buildGame(ActivityNode(
          id: 'act_2',
          title: 'රටාව සම්පූර්ණ කරන්න',
          telemetryTags: ['patterns'],
          templateType: 'pattern_game',
          rounds: [
            {'pattern': ['🔴', '🔵', '🔴', '?'], 'options': ['🔵', '🔴', '🟡'], 'correct_index': 0},
            {'pattern': ['⭐', '🌙', '⭐', '?'], 'options': ['🌙', '⭐', '☀️'], 'correct_index': 0},
          ],
        )),
        title: 'රටාව සම්පූර්ණ කරන්න',
        durationSeconds: 60,
      ),
      // Phase 2: Core Cognitive/Phonics (Visual/Memory - ~2.5 mins)
      SessionActivity(
        screen: GameFactory.buildGame(ActivityNode(
          id: 'act_3',
          title: 'අඩු රූපය සොයන්න',
          telemetryTags: ['observation'],
          templateType: 'missing_picture_game',
          rounds: [
            {'original': ['🐶', '🐱', '🐭'], 'missing': '🐱', 'options': ['🐶', '🐱', '🐰'], 'correct_index': 1},
          ],
        )),
        title: 'අඩු රූපය සොයන්න',
        durationSeconds: 60,
      ),
      SessionActivity(
        screen: GameFactory.buildGame(ActivityNode(
          id: 'act_4',
          title: 'මතක තබා ගන්න',
          telemetryTags: ['memory'],
          templateType: 'memory_game',
          rounds: [
            {'items': ['🍎', '🍐', '🍊'], 'target': '🍎', 'options': ['🍎', '🍉', '🍇'], 'correct_index': 0},
          ],
        )),
        title: 'මතක තබා ගන්න',
        durationSeconds: 90,
      ),
      // Phase 3: Application (Sorting/Logic - ~2.5 mins)
      SessionActivity(
        screen: GameFactory.buildGame(ActivityNode(
          id: 'act_5',
          title: 'වර්ගීකරණය කරන්න',
          telemetryTags: ['sorting'],
          templateType: 'sorting_game',
          rounds: [
            {'category': 'සතුන්', 'item': '🐶', 'options': ['සතුන්', 'කෑම'], 'correct_index': 0},
          ],
        )),
        title: 'වර්ගීකරණය කරන්න',
        durationSeconds: 90,
      ),
      SessionActivity(
        screen: GameFactory.buildGame(ActivityNode(
          id: 'act_6',
          title: 'සැඟවුණු හැඩය සොයන්න',
          telemetryTags: ['shapes'],
          templateType: 'odd_one_out_game',
          rounds: [
            {'target': '🔷', 'distractors': ['🔴'], 'target_count': 1, 'distractor_count': 3, 'correct_index': 0},
          ],
        )),
        title: 'සැඟවුණු හැඩය සොයන්න',
        durationSeconds: 60,
      ),
      // Phase 4: Mastery (Size/Position logic - ~3 mins)
      SessionActivity(
        screen: GameFactory.buildGame(ActivityNode(
          id: 'act_7',
          title: 'ප්‍රමාණය අනුව පෙළගස්වන්න',
          telemetryTags: ['size'],
          templateType: 'generic_mcq_game',
          rounds: [
            {'question': 'ලොකුම රූපය තෝරන්න', 'options': ['🐘', '🐭', '🐱'], 'correct_index': 0},
          ],
        )),
        title: 'ප්‍රමාණය අනුව පෙළගස්වන්න',
        durationSeconds: 90,
      ),
    ];
  }
}

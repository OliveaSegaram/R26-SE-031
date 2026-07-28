import 'package:flutter/material.dart';
import '../../models/curriculum_models.dart';
import '../../widgets/telemetry_wrapper.dart';

// Skill 1 Dedicated Game Screens
import 'visual_skills/skill_1/activity1_odd_shape.dart';
import 'visual_skills/skill_1/activity2_complete_pattern.dart';
import 'visual_skills/skill_1/activity3_remember_pattern.dart';
import 'visual_skills/skill_1/activity4_non_matching_image.dart';
import 'visual_skills/skill_1/activity5_direction_recognition.dart';
import 'visual_skills/skill_1/activity6_color_matching.dart';
import 'visual_skills/skill_1/activity7_shape_coloring.dart';
import 'visual_skills/skill_1/activity8_fill_blank.dart';
import 'visual_skills/skill_1/activity9_audio_image_search.dart';
import 'visual_skills/skill_1/activity10_identical_match.dart';
import 'visual_skills/skill_1/activity11_audio_sequence.dart';

/// Central factory for constructing dynamic game screen instances based on template_type.
class GameFactory {
  static Widget buildGame(ActivityNode node) {
    Widget gameContent;

    switch (node.templateType) {
      // --- Skill 1 Dedicated Templates ---
      case 'odd_one_out_game':
      case 'hidden_picture_game':
        gameContent = Activity1OddShape(activityNode: node);
        break;

      case 'pattern_game':
        gameContent = Activity2CompletePattern(activityNode: node);
        break;

      case 'pattern_memory_game':
      case 'memory_game':
        gameContent = Activity3RememberPattern(activityNode: node);
        break;

      case 'non_matching_image_game':
        gameContent = Activity4NonMatchingImage(activityNode: node);
        break;

      case 'direction_game':
        gameContent = Activity5DirectionRecognition(activityNode: node);
        break;

      case 'color_match_game':
        gameContent = Activity6ColorMatching(activityNode: node);
        break;

      case 'coloring_game':
        gameContent = Activity7ShapeColoring(activityNode: node);
        break;

      case 'fill_blank_game':
      case 'missing_picture_game':
        gameContent = Activity8FillBlank(activityNode: node);
        break;

      case 'audio_image_match_game':
      case 'audio_game':
      case 'generic_mcq_game':
      case 'reading_game':
        gameContent = Activity9AudioImageSearch(activityNode: node);
        break;

      case 'identical_match_game':
      case 'matching_game':
        gameContent = Activity10IdenticalMatch(activityNode: node);
        break;

      case 'audio_sequence_game':
      case 'sorting_game':
      case 'sequence_game':
        gameContent = Activity11AudioSequence(activityNode: node);
        break;

      // Fallback for unhandled template types
      default:
        gameContent = Activity1OddShape(activityNode: node);
    }

    return TelemetryWrapper(
      activityNode: node,
      onRoundComplete: (score) {
        // Handled dynamically via TelemetryWrapperState
      },
      child: gameContent,
    );
  }
}

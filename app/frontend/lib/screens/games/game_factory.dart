import 'package:flutter/material.dart';
import '../../models/curriculum_models.dart';
import '../../widgets/telemetry_wrapper.dart';

// Shared Generic Templates (Used by Skills 2-5)
import 'shared_templates/activity1_odd_shape.dart';
import 'shared_templates/activity2_complete_pattern.dart';
import 'shared_templates/activity3_remember_pattern.dart';
import 'shared_templates/activity4_non_matching_image.dart';
import 'shared_templates/activity5_direction_recognition.dart';
import 'shared_templates/activity6_color_matching.dart';
import 'shared_templates/activity7_shape_coloring.dart';
import 'shared_templates/activity8_fill_blank.dart';
import 'shared_templates/activity9_audio_image_search.dart';
import 'shared_templates/activity10_identical_match.dart';
import 'shared_templates/activity11_audio_sequence.dart';

// Picture Recognition (skill_visual) Games
import 'skill_1/visual_act1_hidden_search.dart';
import 'skill_1/visual_act4_pattern_adventure.dart';
import 'skill_1/visual_act3_sorting_adventure.dart';
import 'skill_1/visual_act2_shadow_matching.dart';
import 'skill_1/visual_act5_memory_hats.dart';

// Skill 2 Dedicated Templates
import 'skill_2/skill2_act3_audio.dart';
import 'skill_2/skill2_act2_identical_match.dart';

import 'skill_2/skill2_act4_mcq.dart';
import 'skill_2/skill2_act1_odd_one_out.dart';
import 'skill_2/skill2_act5_pattern_memory.dart';

/// Central factory for constructing dynamic game screen instances based on template_type.
class GameFactory {
  static Widget buildGame(ActivityNode node, {bool isRemedial = false}) {
    Widget gameContent;

    switch (node.templateType) {
      // --- Picture Recognition (skill_visual) Templates ---
      case 'visual_hidden_search':
        gameContent = VisualAct1HiddenSearch(activityNode: node);
        break;
      case 'visual_pattern_adventure':
        gameContent = VisualAct4PatternAdventure(activityNode: node);
        break;
      case 'visual_sorting_adventure':
        gameContent = VisualAct3SortingAdventure(activityNode: node);
        break;
      case 'visual_odd_one_out':
        gameContent = VisualAct2ShadowMatching(activityNode: node);
        break;
      case 'visual_memory_hats':
        gameContent = VisualAct5MemoryHats(activityNode: node);
        break;

      // --- Skill 2 Dedicated Templates ---
      case 'skill2_audio':
        gameContent = Skill2Act3Audio(activityNode: node, isRemedial: isRemedial);
        break;
      case 'skill2_identical_match':
        gameContent = Skill2Act2IdenticalMatch(activityNode: node, isRemedial: isRemedial);
        break;

      case 'skill2_mcq':
        gameContent = Skill2Act4Mcq(activityNode: node, isRemedial: isRemedial);
        break;
      case 'skill2_odd_one_out':
        gameContent = Skill2Act1OddOneOut(activityNode: node, isRemedial: isRemedial);
        break;
      case 'skill2_pattern_memory':
        gameContent = Skill2Act5PatternMemory(activityNode: node, isRemedial: isRemedial);
        break;

      // --- Skill 1 Dedicated Templates ---
      case 'odd_one_out_game':
      case 'hidden_picture_game':
        gameContent = Activity1OddShape(activityNode: node, isRemedial: isRemedial);
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

      // Fallback for unhandled or removed template types
      default:
        gameContent = const Scaffold(body: Center(child: Text("Unknown Game Type")));
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
import 'package:flutter/material.dart';
import '../../models/curriculum_models.dart';
import '../../widgets/telemetry_wrapper.dart';

// Picture Recognition (skill_visual) Games
import 'visual_skills/skill_1/visual_act1_hidden_search.dart';
import 'visual_skills/skill_1/visual_act2_pattern_adventure.dart';
import 'visual_skills/skill_1/visual_act3_sorting_adventure.dart';
import 'visual_skills/skill_1/visual_act4_shadow_matching.dart';
import 'visual_skills/skill_1/visual_act5_memory_hats.dart';

// Demo Games
import 'demo/demo_shadow_match.dart';
import 'demo/demo_math_substitution.dart';
import 'demo/demo_shape_pattern.dart';
import 'demo/demo_sinhala_letter_builder.dart';
import 'demo/demo_letter_combiner.dart';
import 'demo/demo_icon_spotting.dart';
import 'demo/demo_sentence_object_spotting.dart';

/// Central factory for constructing dynamic game screen instances based on template_type.
class GameFactory {
  static Widget buildGame(ActivityNode node, {bool isRemedial = false}) {
    Widget gameContent;

    switch (node.templateType) {
      // --- Demo Games ---
      case 'shadow_match_demo':
        gameContent = DemoShadowMatch(activityNode: node);
        break;
      case 'math_substitution_demo':
        gameContent = DemoMathSubstitution(activityNode: node);
        break;
      case 'shape_pattern_demo':
        gameContent = DemoShapePattern(activityNode: node);
        break;
      case 'sinhala_letter_builder_demo':
        gameContent = DemoSinhalaLetterBuilder(activityNode: node);
        break;
      case 'letter_combiner_demo':
        gameContent = DemoLetterCombiner(activityNode: node);
        break;
      case 'icon_spotting_demo':
        gameContent = DemoIconSpotting(activityNode: node);
        break;
      case 'sentence_object_spotting_demo':
        gameContent = DemoSentenceObjectSpotting(activityNode: node);
        break;

      // --- Picture Recognition (skill_visual) Templates ---
      case 'visual_hidden_search':
        gameContent = VisualAct1HiddenSearch(activityNode: node);
        break;
      case 'visual_pattern_adventure':
        gameContent = VisualAct2PatternAdventure(activityNode: node);
        break;
      case 'visual_sorting_adventure':
        gameContent = VisualAct3SortingAdventure(activityNode: node);
        break;
      case 'visual_odd_one_out':
        gameContent = VisualAct4ShadowMatching(activityNode: node);
        break;
      case 'visual_memory_hats':
        gameContent = VisualAct5MemoryHats(activityNode: node);
        break;

      // Fallback for unhandled template types
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

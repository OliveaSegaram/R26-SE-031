import 'package:flutter/material.dart';
import '../../models/curriculum_models.dart';
import '../../widgets/telemetry_wrapper.dart';
import 'visual_skills/activity1_spot_difference.dart';
import 'visual_skills/activity2_pattern.dart';
import 'visual_skills/activity3_missing_picture.dart';
import 'visual_skills/activity4_visual_memory.dart';
import 'visual_skills/activity5_category_sorting.dart';
import 'visual_skills/activity6_hidden_shape.dart';
import 'visual_skills/activity7_size_ordering.dart';
import 'visual_skills/activity8_position.dart';
import 'visual_skills/activity9_sequence.dart';
import 'visual_skills/activity10_shadow_match.dart';

class GameFactory {
  static Widget buildGame(ActivityNode node) {
    Widget gameContent;
    switch (node.templateType) {
      case 'hidden_picture_game':
        gameContent = Activity1SpotDifference(activityNode: node);
        break;
      case 'pattern_game':
        gameContent = Activity2Pattern(activityNode: node);
        break;
      case 'missing_picture_game':
        gameContent = Activity3MissingPicture(activityNode: node);
        break;
      case 'memory_game':
        gameContent = Activity4VisualMemory(activityNode: node);
        break;
      case 'sorting_game':
        gameContent = Activity5CategorySorting(activityNode: node);
        break;
      case 'matching_game':
        gameContent = Activity10ShadowMatch(activityNode: node);
        break;
      case 'odd_one_out_game':
        gameContent = Activity6HiddenShape(activityNode: node); // Reusing hidden shape for odd one out
        break;
      case 'maze_game':
        gameContent = Activity8Position(activityNode: node); // Reusing position generic MCQ
        break;
      case 'reading_game':
      case 'audio_game':
      case 'generic_mcq_game':
        // Activity 8 provides a generic question + options layout which is perfect for fallbacks
        gameContent = Activity8Position(activityNode: node);
        break;
      
      // Fallback for unimplemented templates
      default:
        gameContent = Scaffold(
          appBar: AppBar(title: Text(node.title)),
          body: Center(
            child: Text('Template "${node.templateType}" is not yet implemented.'),
          ),
        );
    }

    return TelemetryWrapper(
      activityNode: node,
      onRoundComplete: (score) {
        // Handled dynamically via the wrapper 
      },
      child: gameContent,
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/curriculum_models.dart';
import '../../widgets/telemetry_wrapper.dart';
import '../controllers/adaptive_choice_controller.dart';
import '../models/adaptive_scaffold_models.dart';

/// Reusable adapter for MCQ/audio/fill-blank templates. It keeps task screens
/// responsible for their content while centralizing C4 IDs, capabilities,
/// command application, and treatment-fidelity telemetry.
mixin ChoiceScaffoldAdapter<T extends StatefulWidget> on State<T> {
  final AdaptiveChoiceController<int> adaptiveChoices =
      AdaptiveChoiceController<int>();
  String _adaptiveSignature = '';
  String adaptiveItemId = '';
  int adaptiveCorrectIndex = 0;

  void configureAdaptiveChoices({
    required ActivityNode? activity,
    required int roundIndex,
    required List<String> options,
    required int correctIndex,
    AdaptiveOptionRole distractorRole = AdaptiveOptionRole.semanticDistractor,
  }) {
    final itemId = CanonicalItemResolver.normalizeItemId(
      activity != null && roundIndex >= 0 && roundIndex < activity.rounds.length
          ? activity.rounds[roundIndex]['item_id']?.toString() ??
                CanonicalItemResolver.canonicalItemId(
                  skillId: activity.skillId,
                  activityId: activity.id,
                  roundNumber: roundIndex + 1,
                )
          : 'UNKNOWN_ITEM',
    );
    final signature = '$itemId|$correctIndex|${options.join('\u001f')}';
    if (_adaptiveSignature == signature) return;
    _adaptiveSignature = signature;
    adaptiveItemId = itemId;
    adaptiveCorrectIndex = correctIndex;
    adaptiveChoices.configure(
      List<AdaptiveOption<int>>.generate(
        options.length,
        (index) => AdaptiveOption<int>(
          id: adaptiveOptionId(index),
          value: index,
          role: index == correctIndex
              ? AdaptiveOptionRole.target
              : distractorRole,
          metadata: <String, dynamic>{'label': options[index]},
        ),
      ),
    );
  }

  String adaptiveOptionId(int index) => '${adaptiveItemId}_O${index + 1}';

  List<String> get adaptiveOptionLabels => adaptiveChoices.allOptions
      .map((option) => option.metadata['label']?.toString() ?? '')
      .toList();

  bool isAdaptivelyRemoved(int index) =>
      adaptiveChoices.removedIds.contains(adaptiveOptionId(index));

  bool isAdaptivelyHighlighted(int index) =>
      adaptiveChoices.visualStateFor(adaptiveOptionId(index)) ==
      AdaptiveOptionVisualState.hint;

  Future<ScaffoldApplicationReport?> requestChoiceScaffold({
    required int selectedIndex,
    required List<String> options,
    required int correctIndex,
    required String errorType,
    List<String> additionalCapabilities = const <String>[],
  }) async {
    adaptiveChoices.markIncorrect(adaptiveOptionId(selectedIndex));
    final wrapper = context.findAncestorStateOfType<TelemetryWrapperState>();
    if (wrapper == null) return null;
    final result = await wrapper.registerAdaptiveWrongAttempt(
      itemId: adaptiveItemId,
      extraTelemetry: <String, dynamic>{
        'original_options_count': options.length,
        'visible_option_ids': adaptiveChoices.visibleOptions
            .map((option) => option.id)
            .toList(),
        'incorrect_option_ids': <String>[
          adaptiveOptionId(selectedIndex),
          ...adaptiveChoices.visibleOptions
              .where(
                (option) =>
                    option.value != correctIndex &&
                    option.value != selectedIndex,
              )
              .map((option) => option.id),
        ],
        'correct_option_ids': <String>[adaptiveOptionId(correctIndex)],
        'selected_option_ids': <String>[adaptiveOptionId(selectedIndex)],
        'supported_actions': <String>{
          'REMOVE_OPTION',
          'HIGHLIGHT_OPTION',
          'REPLAY_INSTRUCTION',
          ...additionalCapabilities,
        }.toList(),
        'minimum_visible_options': 2,
        'error_type': errorType,
      },
    );
    return wrapper.applyScaffoldResult<int>(
      controller: adaptiveChoices,
      result: result,
      correctOptionIds: <String>[adaptiveOptionId(correctIndex)],
    );
  }

  void clearAdaptiveWrongFeedback() => adaptiveChoices.clearTransientFeedback();

  void disposeChoiceScaffoldAdapter() => adaptiveChoices.dispose();
}

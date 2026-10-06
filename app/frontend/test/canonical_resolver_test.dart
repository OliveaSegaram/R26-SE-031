import 'package:flutter_test/flutter_test.dart';
import 'package:sipsara_app/models/curriculum_models.dart';

void main() {
  group('CanonicalItemResolver Tests', () {
    test('Resolves MCQ template correctly', () {
      final act = ActivityNode(
        id: 'a1',
        title: 'test',
        telemetryTags: [],
        templateType: 'skill2_mcq',
        rounds: [],
      );

      final roundData = {
        'options': ['A', 'B', 'C'],
        'correctOption': 'B',
        'item_id': 'S2_A1_R01',
        'difficulty_b': 1.0,
        'is_anchor': true,
      };

      final resolved = CanonicalItemResolver.resolve(act, roundData, 0);

      expect(resolved.itemId, 'S2A1R01');
      expect(resolved.difficultyB, 1.0);
      expect(resolved.isAnchor, true);
      expect(resolved.targets.length, 1);
      expect(resolved.targets.first, 'B');
      expect(resolved.distractors.length, 2);
      expect(resolved.distractors.contains('A'), true);
      expect(resolved.distractors.contains('C'), true);
      expect(resolved.distractors.contains('B'), false);
    });

    test('Resolves Hidden Search template correctly', () {
      final act = ActivityNode(
        id: 'a1',
        title: 'test',
        telemetryTags: [],
        templateType: 'visual_hidden_search',
        rounds: [],
      );

      final roundData = {
        'targets': ['Apple', 'Banana'],
        'distractors': ['Carrot', 'Dog'],
      };

      final resolved = CanonicalItemResolver.resolve(act, roundData, 0);

      expect(resolved.itemId, 'S0A1R01'); // canonical fallback
      expect(resolved.targets.length, 2);
      expect(resolved.distractors.length, 2);
    });

    test(
      'reads nested content, research metadata, and variant information',
      () {
        final act = ActivityNode.fromJson({
          'id': 'act_2',
          'title': 'test',
          'template_type': 'skill3_image_mcq',
          'research_metadata': {
            'knowledge_component_id': 'KC_WORD_RECOGNITION',
            'prompt_modality': 'visual',
            'response_modality': 'tap',
            'research_role': 'primary',
          },
          'rounds': const [],
        })..skillId = 'skill_3';

        final resolved = CanonicalItemResolver.resolve(act, {
          'item_id': 'S3_A2_R4V1',
          'difficulty_b': -0.5,
          'equivalent_group_id': 'S3A2R04',
          'allowed_scaffolds': ['REMOVE_OPTION', 'HIGHLIGHT_OPTION'],
          'content': {
            'options': ['අ', 'ආ', 'ඇ'],
            'correct_option': 'ආ',
          },
        }, 3);

        expect(
          act.researchMetadata?.knowledgeComponentId,
          'KC_WORD_RECOGNITION',
        );
        expect(resolved.itemId, 'S3A2R04V1');
        expect(resolved.targets, ['ආ']);
        expect(resolved.distractors, ['අ', 'ඇ']);
        expect(resolved.equivalentGroupId, 'S3A2R04');
        expect(resolved.allowedScaffolds, contains('REMOVE_OPTION'));
      },
    );
  });
}

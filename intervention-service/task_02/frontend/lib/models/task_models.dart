class TaskQuestion {
  TaskQuestion({
    required this.taskType,
    required this.level,
    required this.prompt,
    required this.options,
    required this.correctId,
    this.displayWord,
    this.targetWord,
    this.visual = 'letter',
    this.cardColor,
    this.tiles = const [],
    this.correctSequence = const [],
    this.pairs = const [],
    this.hint,
    this.meaningHint,
    this.lessonRef,
  });

  factory TaskQuestion.fromJson(Map<String, dynamic> q) {
    final opts = (q['options'] as List? ?? [])
        .map((o) => TaskOption.fromJson(o as Map<String, dynamic>))
        .toList();
    final pairList = (q['pairs'] as List? ?? [])
        .map((p) => MatchPair.fromJson(p as Map<String, dynamic>))
        .toList();
    return TaskQuestion(
      taskType: q['task_type'] as String? ?? '',
      level: q['level'] as int? ?? 2,
      prompt: q['prompt'] as String? ?? '',
      options: opts,
      correctId: q['correct_id'] as String? ?? '',
      displayWord: q['display_word'] as String?,
      targetWord: q['target_word'] as String?,
      visual: switch (q['visual']) {
        final String s when s.isNotEmpty => s,
        _ => 'letter',
      },
      cardColor: q['card_color'] as String?,
      tiles: List<String>.from(q['tiles'] as List? ?? []),
      correctSequence:
          List<String>.from(q['correct_sequence'] as List? ?? []),
      pairs: pairList,
      hint: q['hint'] as String?,
      meaningHint: q['meaning_hint'] as String?,
      lessonRef: q['lesson_ref'] as String?,
    );
  }

  final String taskType;
  final int level;
  final String prompt;
  final List<TaskOption> options;
  final String correctId;
  final String? displayWord;
  final String? targetWord;
  final String visual;
  final String? cardColor;
  final List<String> tiles;
  final List<String> correctSequence;
  final List<MatchPair> pairs;
  final String? hint;
  final String? meaningHint;
  final String? lessonRef;
}

class MatchPair {
  MatchPair({
    required this.id,
    required this.word,
    required this.visual,
    this.meaning,
  });

  factory MatchPair.fromJson(Map<String, dynamic> j) => MatchPair(
        id: j['id'] as String? ?? '',
        word: j['word'] as String? ?? '',
        visual: j['visual'] as String? ?? 'letter',
        meaning: j['meaning'] as String?,
      );

  final String id;
  final String word;
  final String visual;
  final String? meaning;
}

class TaskOption {
  TaskOption({
    required this.id,
    required this.label,
    this.visual = 'letter',
    this.cardColor,
  });

  factory TaskOption.fromJson(Map<String, dynamic> j) => TaskOption(
        id: j['id'] as String? ?? '',
        label: j['label'] as String? ?? '',
        visual: j['visual'] as String? ?? 'letter',
        cardColor: j['card_color'] as String?,
      );

  final String id;
  final String label;
  final String visual;
  final String? cardColor;
}

class SessionSummary {
  SessionSummary({
    required this.accuracy,
    required this.riskLevel,
    required this.labelSi,
    required this.byLevel,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> j) => SessionSummary(
        accuracy: (j['accuracy'] as num?)?.toDouble() ?? 0,
        riskLevel: j['risk_level'] as String? ?? 'moderate',
        labelSi: j['label_si'] as String? ?? '',
        byLevel: Map<String, int>.from(
          (j['by_level'] as Map?)?.map((k, v) => MapEntry('$k', v as int)) ??
              {},
        ),
      );

  final double accuracy;
  final String riskLevel;
  final String labelSi;
  final Map<String, int> byLevel;
}

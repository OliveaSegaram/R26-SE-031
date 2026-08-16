class PatternRound {
  final List<String?> sequence;
  final int missingIndex;
  final String correctAnswer;
  final List<String> options;
  final int difficulty;

  const PatternRound({
    required this.sequence,
    required this.missingIndex,
    required this.correctAnswer,
    required this.options,
    required this.difficulty,
  });
}

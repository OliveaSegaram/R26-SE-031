/// Data model for a single sorting round.
class SortingRound {
  /// Map of category key → list of asset paths belonging to that category.
  /// Example: {'animals': ['animals/fish.png', 'animals/rabbit.png']}
  final Map<String, List<String>> categories;

  /// Map of category key → a representative icon asset path.
  /// Example: {'animals': 'animals/elephant.png'}
  final Map<String, String> categoryIcons;

  /// Map of category key → Sinhala display label.
  /// Example: {'animals': 'සතුන්'}
  final Map<String, String> categoryLabels;

  /// The flat list of all objects to sort in this round (shuffled).
  final List<String> objects;

  /// Map of each object path → which category key it belongs to.
  final Map<String, String> objectToCategory;

  /// Difficulty level 1-5.
  final int difficulty;

  SortingRound({
    required this.categories,
    required this.categoryIcons,
    required this.categoryLabels,
    required this.objects,
    required this.objectToCategory,
    required this.difficulty,
  });
}

import 'dart:math';

class HiddenSearchGenerator {
  // All possible assets for distractors
  static const List<String> allAssets = [
    'fruits_food/mango.png',
    'fruits_food/watermelon.png',
    'fruits_food/orange.png',
    'fruits_food/grapes.png',
    'fruits_food/apple.png',
    'fruits_food/ice_cream.png',
    'fruits_food/banana.png',
    'everyday_objects/spoon.png',
    'everyday_objects/flag.png',
    'everyday_objects/bell.png',
    'everyday_objects/hat.png',
    'everyday_objects/book.png',
    'everyday_objects/key.png',
    'everyday_objects/candle.png',
    'everyday_objects/umbrella.png',
    'everyday_objects/shoe.png',
    'everyday_objects/comb.png',
    'everyday_objects/balloon.png',
    'everyday_objects/chair.png',
    'everyday_objects/clock.png',
    'everyday_objects/pencil.png',
    'everyday_objects/cylinder.png',
    'everyday_objects/necklace.png',
    'everyday_objects/teacup.png',
    'everyday_objects/bucket.png',
    'everyday_objects/kite.png',
    'everyday_objects/oil_lamp.png',
    'nature/flower.png',
    'nature/sun.png',
    'nature/leaf.png',
    'animals/dog.png',
    'animals/rabbit.png',
    'animals/turtle.png',
    'animals/elephant.png',
    'animals/bird.png',
    'animals/cow.png',
    'animals/butterfly.png',
    'animals/cat.png',
    'animals/frog.png',
    'animals/fish.png',
    'animals/snail.png',
    'vehicles/boat.png',
    'vehicles/train.png',
    'vehicles/van.png',
    'vehicles/airplane.png',
    'vehicles/bicycle.png',
  ];

  // A strict list of asymmetrical targets that work well with the FLIPPED trick
  static const Map<String, Map<String, String>> targetDict = {
    'animals/fish.png': {'singular': 'මාළුවා', 'plural': 'මාළුන්'},
    'animals/rabbit.png': {'singular': 'හාවා', 'plural': 'හාවුන්'},
    'animals/dog.png': {'singular': 'බල්ලා', 'plural': 'බල්ලන්'},
    'animals/bird.png': {'singular': 'කුරුල්ලා', 'plural': 'කුරුල්ලන්'},
    'animals/cat.png': {'singular': 'පූසා', 'plural': 'පූසන්'},
    'vehicles/boat.png': {'singular': 'බෝට්ටුව', 'plural': 'බෝට්ටු'},
    'vehicles/airplane.png': {'singular': 'ගුවන්යානය', 'plural': 'ගුවන්යානා'},
    'vehicles/van.png': {'singular': 'වෑන් රථය', 'plural': 'වෑන් රථ'},
    'everyday_objects/shoe.png': {'singular': 'සපත්තුව', 'plural': 'සපත්තු'},
    'everyday_objects/key.png': {'singular': 'යතුර', 'plural': 'යතුරු'},
    'everyday_objects/teacup.png': {'singular': 'තේ කෝප්පය', 'plural': 'තේ කෝප්ප'},
  };

  static const List<String> colorTricks = [
    '0xFFFFCDD2', // Light Red / Pink
    '0xFFC8E6C9', // Light Green
    '0xFFBBDEFB', // Light Blue
    '0xFFE1BEE7', // Purple
    '0xFFFFF9C4', // Yellow
  ];

  static List<Map<String, dynamic>> generateRounds() {
    final rng = Random();
    
    // Pick 5 unique targets from our dictionary so the child never searches for the same thing twice in a session
    final targetKeys = targetDict.keys.toList()..shuffle(rng);
    
    return [
      _generateRound(rng, targetKeys[0], 1, 3, useFlipped: false, useColors: false), // Round 1
      _generateRound(rng, targetKeys[1], 1, 4, useFlipped: false, useColors: false), // Round 2
      _generateRound(rng, targetKeys[2], 2, 6, useFlipped: true, useColors: false),  // Round 3
      _generateRound(rng, targetKeys[3], 2, 9, useFlipped: true, useColors: true),   // Round 4
      _generateRound(rng, targetKeys[4], 3, 14, useFlipped: true, useColors: true),  // Round 5
    ];
  }

  static Map<String, dynamic> _generateRound(
    Random rng, 
    String targetPath, 
    int targetCount, 
    int distractorCount, 
    {required bool useFlipped, required bool useColors}
  ) {
    
    final tInfo = targetDict[targetPath]!;
    final instruction = targetCount == 1 
        ? '${tInfo['singular']} සොයන්න!' 
        : '${tInfo['plural']} $targetCountක් සොයන්න!';
        
    final targetName = targetCount == 1 ? tInfo['singular']! : tInfo['plural']!;

    // Select random base distractors
    final List<String> baseDistractors = List<String>.from(allAssets)
      ..remove(targetPath)
      ..shuffle(rng);

    List<String> finalDistractors = [];

    // Add standard distractors
    for (int i = 0; i < distractorCount; i++) {
      String distractor = baseDistractors[i % baseDistractors.length];
      
      // Inject tricky distractors for advanced rounds
      if (useFlipped && i == 0) {
        distractor = 'FLIPPED:$targetPath';
      } else if (useColors && i == 1) {
        final color = colorTricks[rng.nextInt(colorTricks.length)];
        distractor = 'COLOR:$color:$targetPath';
      } else if (useFlipped && useColors && i == 2) {
        final color = colorTricks[rng.nextInt(colorTricks.length)];
        distractor = 'COLOR:$color:FLIPPED:$targetPath';
      } else if (useFlipped && i == 3) {
        distractor = 'FLIPPED:$targetPath'; 
      }
      
      finalDistractors.add(distractor);
    }
    
    finalDistractors.shuffle(rng);

    return {
      "instruction": instruction,
      "target_name": targetName,
      "targets": [targetPath],
      "target_count": targetCount,
      "distractors": finalDistractors,
      "distractor_count": finalDistractors.length
    };
  }
}
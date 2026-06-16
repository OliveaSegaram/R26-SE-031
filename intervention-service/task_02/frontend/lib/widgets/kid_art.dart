import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Grade 1 picture cards — bundled PNG scaled to fill the card.
class KidArt extends StatelessWidget {
  const KidArt({super.key, required this.visual, this.letter});

  final String visual;
  final String? letter;

  static const _assetVisuals = {
    'house', 'tree', 'bird', 'water', 'river', 'sun', 'moon', 'stars',
    'flower', 'cat', 'dog', 'book', 'school', 'food', 'milk', 'apple',
    'mother', 'father', 'girl', 'teacher', 'road', 'honey', 'nut', 'mosquito',
    'leaf', 'rabbit', 'fish', 'bee', 'animal', 'boy', 'child', 'friend',
    'village', 'market', 'fruit', 'classroom', 'morning', 'night',
    'celebration', 'farming', 'colors', 'beautiful', 'good', 'happy',
    'come', 'go', 'clothes', 'song', 'dance',
  };

  static const _emoji = <String, String>{
    'house': '🏠',
    'tree': '🌳',
    'bird': '🐦',
    'water': '💧',
    'river': '🌊',
    'sun': '☀️',
    'moon': '🌙',
    'stars': '⭐',
    'flower': '🌸',
    'cat': '🐱',
    'dog': '🐕',
    'book': '📖',
    'school': '🏫',
    'food': '🍛',
    'milk': '🥛',
    'apple': '🍎',
    'fruit': '🍎',
    'mother': '👩',
    'father': '👨',
    'girl': '👧',
    'boy': '👦',
    'child': '👶',
    'friend': '👫',
    'teacher': '👩‍🏫',
    'road': '🛣️',
    'honey': '🍯',
    'bee': '🐝',
    'nut': '🌰',
    'mosquito': '🦟',
    'leaf': '🍃',
    'rabbit': '🐰',
    'fish': '🐟',
    'animal': '🐾',
    'village': '🏘️',
    'market': '🏪',
    'classroom': '🏫',
    'morning': '🌅',
    'night': '🌃',
    'celebration': '🎉',
    'farming': '🌾',
    'colors': '🌈',
    'beautiful': '✨',
    'good': '👍',
    'happy': '😊',
    'come': '👉',
    'go': '🚶',
    'clothes': '👕',
    'song': '🎵',
    'dance': '💃',
  };

  static String? assetPath(String visual) {
    if (_assetVisuals.contains(visual)) {
      return 'assets/pictures/$visual.png';
    }
    return null;
  }

  static Color bgColor(String visual) {
    return switch (visual) {
      'moon' || 'stars' || 'night' => const Color(0xFF1A237E),
      'water' || 'river' => const Color(0xFF4FC3F7),
      'morning' || 'sun' => const Color(0xFFFFF9C4),
      'house' || 'school' || 'village' || 'classroom' => const Color(0xFFFFF9C4),
      'tree' || 'flower' || 'leaf' || 'farming' => const Color(0xFFE8F5E9),
      'mother' || 'father' || 'girl' || 'boy' || 'child' || 'friend' || 'teacher' =>
        const Color(0xFFFFF3E0),
      'cat' || 'dog' || 'bird' || 'rabbit' || 'fish' || 'bee' || 'animal' || 'mosquito' =>
        const Color(0xFFE3F2FD),
      'food' || 'milk' || 'apple' || 'fruit' || 'honey' || 'nut' => const Color(0xFFFFF8E1),
      'happy' || 'celebration' || 'dance' || 'song' || 'colors' || 'beautiful' || 'good' =>
        const Color(0xFFFCE4EC),
      _ => const Color(0xFFFFFDE7),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bg = bgColor(visual);

    if (visual == 'letter' && letter != null && letter!.isNotEmpty) {
      return Container(
        color: const Color(0xFF7E57C2),
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(constraints.maxWidth, constraints.maxHeight) * 0.75;
            return Text(
              letter!,
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            );
          },
        ),
      );
    }

    final path = assetPath(visual);
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = math.min(constraints.maxWidth, constraints.maxHeight) * 0.06;
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: bg,
            gradient: RadialGradient(
              colors: [Colors.white.withValues(alpha: .35), bg],
              radius: 0.95,
            ),
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.all(pad.clamp(6, 18)),
            child: path != null
                ? Image.asset(
                    path,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => _emojiFallback(visual, constraints),
                  )
                : _emojiFallback(visual, constraints),
          ),
        );
      },
    );
  }

  Widget _emojiFallback(String visual, BoxConstraints constraints) {
    final size = math.min(constraints.maxWidth, constraints.maxHeight) * 0.72;
    return Text(
      _emoji[visual] ?? '❓',
      style: TextStyle(fontSize: size, height: 1),
      textAlign: TextAlign.center,
    );
  }
}

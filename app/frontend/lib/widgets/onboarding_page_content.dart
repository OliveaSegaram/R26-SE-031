import 'package:flutter/material.dart';
import 'monster_character.dart';
import 'speech_bubble.dart';

class OnboardingPageContent extends StatelessWidget {
  final String imagePath;
  final String text;

  const OnboardingPageContent({
    super.key,
    required this.imagePath,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Speech bubble
        SpeechBubble(
          text: text,
          delay: const Duration(milliseconds: 200),
        ),
        
        const SizedBox(height: 32),
        
        // Character
        MonsterCharacter(
          size: 250,
          animation: MonsterAnimation.none,
          showBody: true,
          imagePath: imagePath,
        ),
      ],
    );
  }
}

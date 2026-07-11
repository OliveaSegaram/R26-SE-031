import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';

class Activity8Position extends StatefulWidget {
  const Activity8Position({super.key});

  @override
  State<Activity8Position> createState() => _Activity8PositionState();
}

class _Activity8PositionState extends State<Activity8Position> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Scene has Bird (top), Tree (middle), Cat (bottom)
  
  int _currentQuestionIndex = 0;
  bool _isComplete = false;
  
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'ගසට ඉහලින් ඇත්තේ කුමක්ද?', // Above the tree?
      'options': ['🐦', '🐈', '🌸'],
      'correct': '🐦',
    },
    {
      'question': 'ගසට පහලින් ඇත්තේ කුමක්ද?', // Below the tree?
      'options': ['🐦', '🐈', '🌸'],
      'correct': '🐈',
    },
    {
      'question': 'කුරුල්ලා සහ පූසා අතර ඇත්තේ කුමක්ද?', // Between bird and cat?
      'options': ['🌳', '🚗', '🏠'],
      'correct': '🌳',
    },
  ];

  void _checkAnswer(String option) async {
    final correct = _questions[_currentQuestionIndex]['correct'] as String;
    
    if (option == correct) {
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      setState(() {
        if (_currentQuestionIndex < _questions.length - 1) {
          _currentQuestionIndex++;
        } else {
          _isComplete = true;
        }
      });
      
      if (_isComplete) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } else {
      await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 48),
                const SizedBox(width: 16),
                Text(
                  'විශිෂ්ටයි!',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQ = _questions[_currentQuestionIndex];
    final options = currentQ['options'] as List<String>;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'පිහිටීම හඳුනාගැනීම',
          style: GoogleFonts.notoSansSinhala(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Visual Scene
              Container(
                width: 200,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.lightBlue, width: 3),
                ),
                child: Column(
                  children: [
                    const Text('🐦', style: TextStyle(fontSize: 50)),
                    const SizedBox(height: 10),
                    const Text('🌳', style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 10),
                    const Text('🐈', style: TextStyle(fontSize: 60)),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              Text(
                currentQ['question'] as String,
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: options.map((opt) {
                  return GestureDetector(
                    onTap: () => _checkAnswer(opt),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(opt, style: const TextStyle(fontSize: 40)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

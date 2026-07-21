import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/telemetry_wrapper.dart';
import '../../../models/curriculum_models.dart';

class Activity8Position extends StatefulWidget {
  final ActivityNode activityNode;
  const Activity8Position({super.key, required this.activityNode});

  @override
  State<Activity8Position> createState() => _Activity8PositionState();
}

class PositionRound {
  final List<String> sceneItems;
  final String question;
  final List<String> options;
  final String correctOption;
  PositionRound({required this.sceneItems, required this.question, required this.options, required this.correctOption});
}

class _Activity8PositionState extends State<Activity8Position> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int _currentRoundIndex = 0;
  late List<PositionRound> _rounds;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
  }

  void _initRounds() {
    _rounds = widget.activityNode.rounds.map((roundData) {
      List<String> sceneItems = List<String>.from(roundData['sceneItems'] ?? []);
      String question = roundData['question'] ?? roundData['raw_text'] ?? 'කොහෙද තියෙන්නේ?';
      List<String> options = List<String>.from(roundData['options'] ?? []);
      String correctOption = roundData['correctOption'] ?? '';
      
      if (sceneItems.isEmpty) {
        sceneItems = ['🐦', '🌳', '🐈'];
      }
      if (options.isEmpty) {
        options = ['🐦', '🐈', '🌸'];
        correctOption = '🐦';
      }
      if (correctOption.isEmpty && options.isNotEmpty) {
        correctOption = options[0];
      }
      
      options.shuffle();
      
      return PositionRound(sceneItems: sceneItems, question: question, options: options, correctOption: correctOption);
    }).toList();
  }

  void _checkAnswer(String option) async {
    if (_isComplete) return;

    final currentRound = _rounds[_currentRoundIndex];
    bool isCorrect = option == currentRound.correctOption;

    int score = isCorrect ? 100 : 0;
    context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(score);
    
    if (isCorrect) {
      setState(() {
        _isComplete = true;
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        if (_currentRoundIndex < _rounds.length - 1) {
          setState(() {
            _currentRoundIndex++;
            _isComplete = false;
          });
        } else {
          Navigator.pop(context, true);
        }
      });
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
    final currentRound = _rounds[_currentRoundIndex];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          'පිහිටීම හඳුනාගැනීම',
          style: AppTypography.sinhala(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Progression Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'වටය ${_currentRoundIndex + 1} / ${_rounds.length}',
                    style: AppTypography.sinhala(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentRoundIndex + 1) / _rounds.length,
                backgroundColor: AppColors.borderLight,
                color: AppColors.gentleGreen,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),

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
                    Text(currentRound.sceneItems[0], style: const TextStyle(fontSize: 60)),
                    const SizedBox(height: 10),
                    Text(currentRound.sceneItems[1], style: const TextStyle(fontSize: 60)),
                    const SizedBox(height: 10),
                    Text(currentRound.sceneItems[2], style: const TextStyle(fontSize: 60)),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              Text(
                currentRound.question,
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
                children: currentRound.options.map((opt) {
                  final isCorrectSelection = _isComplete && opt == currentRound.correctOption;

                  return GestureDetector(
                    onTap: () => _checkAnswer(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isCorrectSelection ? AppColors.gentleGreen.withValues(alpha: 0.3) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCorrectSelection ? AppColors.gentleGreen : Colors.transparent,
                          width: 4,
                        ),
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

              if (_isComplete)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gentleGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        'විශිෂ්ටයි!',
                        style: AppTypography.sinhala(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import 'widgets/shared_game_layout.dart';

/// Activity 5: දිශාව හඳුනා ගනිමු (Direction Recognition)
/// Template: direction_game
class Activity5DirectionRecognition extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Activity5DirectionRecognition({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Activity5DirectionRecognition> createState() => _Activity5DirectionRecognitionState();
}

class _Activity5DirectionRecognitionState extends State<Activity5DirectionRecognition> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedIndex;
  bool _isCorrect = false;
  bool _activityComplete = false;
  int _currentRoundIndex = 0;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _checkAnswer(int index, int correctIndex, int totalRounds) async {
    if (_isCorrect) return;

    setState(() {
      _selectedIndex = index;
    });

    final bool isRight = (index == correctIndex);
    int score = isRight ? 100 : 0;
    context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(score);

    if (isRight) {
      setState(() {
        _isCorrect = true;
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        if (_currentRoundIndex < totalRounds - 1) {
          setState(() {
            _currentRoundIndex++;
            _selectedIndex = null;
            _isCorrect = false;
          });
        } else {
          setState(() {
            _activityComplete = true;
          });
        }
      });
    } else {
      await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
    }
  }

  @override
  Widget build(BuildContext context) {
    var rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('දිශාව හඳුනා ගනිමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }
    
    if (rounds.length > 5) {
      rounds = rounds.sublist(0, 5);
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'දිශාව හඳුනා ගනිමු';
    final directionName = currentRound['direction_name']?.toString() ?? 'වම (Left)';
    var options = (currentRound['options'] as List?)?.map((e) => e.toString()).toList() ?? ['⬅️', '➡️', '⬆️', '⬇️'];
    var correctIndex = (currentRound['correct_index'] as int?) ?? 0;
    
    if (widget.isRemedial && options.length > 2) {
      // Reduce distractors to max 1 + 1 correct = 2 options total
      final correctItem = options[correctIndex];
      var distractors = options.where((item) => item != correctItem).toList();
      if (distractors.isNotEmpty) distractors = distractors.sublist(0, 1);
      options = [correctItem, ...distractors];
      options.shuffle();
      correctIndex = options.indexOf(correctItem);
    }

    double itemSize;
    double spacing;
    double fontSize;
    final total = options.length;
    final bool hasLongText = options.any((opt) => opt.toString().length > 4 || opt.toString().contains(' '));

    if (total <= 2) {
      itemSize = 128.0;
      spacing = 32.0;
      fontSize = 64.0;
    } else if (total <= 4) {
      itemSize = 96.0;
      spacing = 20.0;
      fontSize = 48.0;
    } else if (total <= 6) {
      itemSize = 80.0; 
      spacing = 16.0;
      fontSize = 40.0;
    } else if (total <= 9) {
      itemSize = 64.0; 
      spacing = 12.0;
      fontSize = 32.0;
    } else {
      itemSize = 56.0; 
      spacing = 8.0;
      fontSize = 28.0;
    }

    return SharedGameLayout(
      title: titleText,
      currentRoundIndex: _currentRoundIndex,
      totalRounds: rounds.length,
      isRoundComplete: _isCorrect,
      isActivityComplete: _activityComplete,
      onNext: () {
        final wrapper = context.findAncestorStateOfType<TelemetryWrapperState>();
        if (wrapper != null) {
          wrapper.completeActivity(context);
        } else {
          Navigator.pop(context, 100);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Direction Name Prompt Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.calmBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.calmBlue, width: 2),
                      ),
                      child: Text(
                        directionName,
                        style: AppTypography.sinhala(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.calmBlue),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'දක්වා ඇති දිශාවට අදාළ ඊතලය තෝරන්න:',
                      style: AppTypography.sinhala(fontSize: 18, color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: 64),

              // Direction Arrow Buttons (Cross / Grid layout)
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                alignment: WrapAlignment.center,
                children: List.generate(options.length, (index) {
                  final arrowSymbol = options[index];
                  final isSelected = (_selectedIndex == index);
                  final isRight = isSelected && (index == correctIndex);
                  final isWrong = isSelected && (index != correctIndex);

                  return GestureDetector(
                    onTap: () => _checkAnswer(index, correctIndex, rounds.length),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: hasLongText ? null : itemSize,
                          height: hasLongText ? null : itemSize,
                          padding: hasLongText ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16) : null,
                      decoration: BoxDecoration(
                        color: isRight
                            ? AppColors.gentleGreen.withValues(alpha: 0.3)
                            : isWrong
                                ? AppColors.softCoral.withValues(alpha: 0.3)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isRight
                              ? AppColors.gentleGreen
                              : isWrong
                                  ? AppColors.softCoral
                                  : AppColors.borderLight,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Center(
                        child: Text(arrowSymbol, style: TextStyle(fontSize: hasLongText ? 24.0 : fontSize), textAlign: TextAlign.center),
                      ),
                    ),
                  );
                }),
              ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
    );
  }
}

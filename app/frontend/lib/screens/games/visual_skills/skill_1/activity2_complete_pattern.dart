import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';

/// Activity 2: රටාව සම්පූර්ණ කරමු (Complete the Pattern)
/// Template: pattern_game
class Activity2CompletePattern extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Activity2CompletePattern({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Activity2CompletePattern> createState() => _Activity2CompletePatternState();
}

class _Activity2CompletePatternState extends State<Activity2CompletePattern> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedOptionIndex;
  bool _isCorrect = false;
  int _currentRoundIndex = 0;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _checkAnswer(int index, String selectedOption, String correctOption, int totalRounds) async {
    if (_isCorrect) return;

    setState(() {
      _selectedOptionIndex = index;
    });

    final bool isRight = (selectedOption == correctOption);
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
            _selectedOptionIndex = null;
            _isCorrect = false;
          });
        } else {
          final wrapper = context.findAncestorStateOfType<TelemetryWrapperState>();
          if (wrapper != null) {
            wrapper.completeActivity(context);
          } else {
            Navigator.pop(context, 100);
          }
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
        appBar: AppBar(title: const Text('රටාව සම්පූර්ණ කරමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }
    
    // Anti-fatigue: limit to 5 rounds maximum
    if (rounds.length > 5) {
      rounds = rounds.sublist(0, 5);
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'රටාව සම්පූර්ණ කරමු';
    final instructionText = widget.activityNode?.description ?? 'ඊළඟට පැමිණෙන හැඩය තෝරා රටාව සම්පූර්ණ කරන්න.';

    final sequence = (currentRound['sequence'] as List?)?.map((e) => e?.toString()).toList() ?? ['🔴', '🔵', '🔴', null];
    var options = (currentRound['options'] as List?)?.map((e) => e.toString()).toList() ?? ['🔴', '🔵'];
    
    // Dynamic Remedial Adjustment: Cap distractors
    if (widget.isRemedial && options.length > 2) {
      // Keep only 2 options. Ensure the correct option is one of them.
      final correctAnswer = currentRound['correctOption']?.toString() ??
        currentRound['correct_option']?.toString() ??
        (currentRound['correct_index'] != null && (currentRound['correct_index'] as int) < options.length
            ? options[currentRound['correct_index'] as int]
            : options.first);
            
      options = options.where((opt) => opt == correctAnswer).toList();
      final distractors = (currentRound['options'] as List?)?.map((e) => e.toString()).where((opt) => opt != correctAnswer).toList() ?? [];
      
      while (options.length < 2 && distractors.isNotEmpty) {
        options.add(distractors.removeAt(0));
      }
      options.shuffle();
    }
    final correctOption = currentRound['correctOption']?.toString() ??
        currentRound['correct_option']?.toString() ??
        (currentRound['correct_index'] != null && (currentRound['correct_index'] as int) < options.length
            ? options[currentRound['correct_index'] as int]
            : options.first);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(titleText, style: AppTypography.sinhala(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'වටය ${_currentRoundIndex + 1} / ${rounds.length}',
                    style: AppTypography.sinhala(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (_currentRoundIndex + 1) / rounds.length,
                backgroundColor: AppColors.borderLight,
                color: AppColors.gentleGreen,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),
              Text(
                instructionText,
                style: AppTypography.sinhala(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Pattern Sequence Display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: sequence.map((item) {
                    final isBlank = (item == null);
                    return Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isBlank ? AppColors.warmAmber.withValues(alpha: 0.15) : AppColors.cream,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isBlank ? AppColors.warmAmber : AppColors.borderLight,
                          width: isBlank ? 3 : 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isBlank ? '?' : item,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: isBlank ? FontWeight.w900 : FontWeight.normal,
                            color: isBlank ? AppColors.warmAmber : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Spacer(),

              // Candidate Options
              Text(
                'නිවැරදි පිළිතුර තෝරන්න:',
                style: AppTypography.sinhala(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: List.generate(options.length, (index) {
                  final optionText = options[index];
                  final isSelected = (_selectedOptionIndex == index);
                  final isRight = isSelected && (optionText == correctOption);
                  final isWrong = isSelected && (optionText != correctOption);

                  return GestureDetector(
                    onTap: () => _checkAnswer(index, optionText, correctOption, rounds.length),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isRight
                            ? AppColors.gentleGreen.withValues(alpha: 0.3)
                            : isWrong
                                ? AppColors.softCoral.withValues(alpha: 0.3)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRight
                              ? AppColors.gentleGreen
                              : isWrong
                                  ? AppColors.softCoral
                                  : AppColors.borderLight,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))
                        ],
                      ),
                      child: Center(
                        child: Text(optionText, style: const TextStyle(fontSize: 40)),
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
    );
  }
}

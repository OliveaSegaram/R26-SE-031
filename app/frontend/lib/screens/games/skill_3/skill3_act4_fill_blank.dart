import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import '../shared_templates/widgets/shared_game_layout.dart';

/// Skill 3 Activity 4 (Fill Blank Slot Matching Image)
/// Template: fill_blank_game
class Skill3Act4FillBlank extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Skill3Act4FillBlank({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Skill3Act4FillBlank> createState() => _Skill3Act4FillBlankState();
}

class _Skill3Act4FillBlankState extends State<Skill3Act4FillBlank> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedOptionIndex;
  bool _isCorrect = false;
  bool _activityComplete = false;
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
        appBar: AppBar(title: const Text('හිස්තැන පුරවමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }
    
    if (rounds.length > 5) {
      rounds = rounds.sublist(0, 5);
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'රූපයට ගැලපෙන හිස්තැන පුරවමු';
    final instructionText = widget.activityNode?.description ?? 'රූප පෙළෙහි හිස්තැනට ගැලපෙන නිවැරදි රූපය තෝරන්න.';

    final sequence = (currentRound['sequence'] as List?)?.map((e) => e?.toString()).toList() ?? ['🔴', '🔵', null, '🟢'];
    var options = (currentRound['options'] as List?)?.map((e) => e.toString()).toList() ?? ['🟡', '🟣', '🔴', '⭐'];
    final correctOption = currentRound['correctOption']?.toString() ?? options.first;
    
    if (widget.isRemedial && options.length > 2) {
      // Reduce distractors to max 1 + 1 correct = 2 options total
      var distractors = options.where((item) => item != correctOption).toList();
      if (distractors.isNotEmpty) distractors = distractors.sublist(0, 1);
      options = [correctOption, ...distractors];
      options.shuffle();
    }

    double itemSize;
    double spacing;
    double fontSize;
    final total = options.length;
    final bool hasLongText = options.any((opt) => opt.toString().length > 4 || opt.toString().contains(' '));

    if (total <= 2) {
      itemSize = 120.0;
      spacing = 24.0;
      fontSize = 56.0;
    } else if (total <= 4) {
      itemSize = 90.0;
      spacing = 20.0;
      fontSize = 48.0;
    } else if (total <= 6) {
      itemSize = 76.0; 
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
                    Text(
                      instructionText,
                      style: AppTypography.sinhala(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

              // Sequence Container with Fill-in Slot
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: sequence.map((item) {
                    final isBlank = (item == null);
                    final filledText = _isCorrect ? correctOption : '?';

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isBlank
                            ? (_isCorrect ? AppColors.gentleGreen.withValues(alpha: 0.2) : AppColors.warmAmber.withValues(alpha: 0.15))
                            : AppColors.cream,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isBlank ? (_isCorrect ? AppColors.gentleGreen : AppColors.warmAmber) : AppColors.borderLight,
                          width: isBlank ? 3 : 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isBlank ? filledText : item,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: isBlank ? FontWeight.w900 : FontWeight.normal,
                            color: isBlank ? (_isCorrect ? AppColors.gentleGreen : AppColors.warmAmber) : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

                    const SizedBox(height: 64),

                    // Candidate Option Buttons
                    Text('හිස්තැන සඳහා රූපය තෝරන්න:', style: AppTypography.sinhala(fontSize: 16, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
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
                            width: hasLongText ? null : itemSize,
                          height: hasLongText ? null : itemSize,
                          padding: hasLongText ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16) : null,
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
                            child: Center(child: Text(optionText, style: TextStyle(fontSize: hasLongText ? 24.0 : fontSize), textAlign: TextAlign.center)),
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

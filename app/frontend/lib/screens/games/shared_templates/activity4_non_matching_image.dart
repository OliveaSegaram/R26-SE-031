import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import 'widgets/shared_game_layout.dart';

/// Activity 4: නොගැලපෙන රූපය සොයාමු (Find the Non-Matching Image)
/// Template: non_matching_image_game
class Activity4NonMatchingImage extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Activity4NonMatchingImage({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Activity4NonMatchingImage> createState() => _Activity4NonMatchingImageState();
}

class _Activity4NonMatchingImageState extends State<Activity4NonMatchingImage> {
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
        appBar: AppBar(title: const Text('නොගැලපෙන රූපය සොයාමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }
    
    if (rounds.length > 5) {
      rounds = rounds.sublist(0, 5);
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'නොගැලපෙන රූපය සොයාමු';
    final instructionText = widget.activityNode?.description ?? 'අනෙක් රූප කාණ්ඩයට නොගැලපෙන රූපය තෝරන්න.';
    var items = (currentRound['items'] as List?)?.map((e) => e.toString()).toList() ?? ['🍎', '🍌', '🍇', '🚗'];
    var correctIndex = (currentRound['correct_index'] as int?) ?? 3;
    
    if (widget.isRemedial && items.length > 3) {
      // Reduce distractors to max 2 + 1 correct = 3 items total
      final correctItem = items[correctIndex];
      var distractors = items.where((item) => item != correctItem).toList();
      distractors = distractors.sublist(0, 2);
      items = [correctItem, ...distractors];
      items.shuffle();
      correctIndex = items.indexOf(correctItem);
    }

    double itemSize;
    double spacing;
    double fontSize;
    final total = items.length;
    final bool hasLongText = items.any((opt) => opt.toString().length > 4 || opt.toString().contains(' '));

    if (total <= 2) {
      itemSize = 160.0;
      spacing = 32.0;
      fontSize = 72.0;
    } else if (total <= 4) {
      itemSize = 130.0;
      spacing = 16.0;
      fontSize = 56.0;
    } else if (total <= 6) {
      itemSize = 100.0; 
      spacing = 12.0;
      fontSize = 48.0;
    } else if (total <= 9) {
      itemSize = 80.0; 
      spacing = 10.0;
      fontSize = 40.0;
    } else {
      itemSize = 64.0; 
      spacing = 8.0;
      fontSize = 32.0;
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
              Text(
                instructionText,
                style: AppTypography.sinhala(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),

              // 2x2 Grid of Category Cards
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      alignment: WrapAlignment.center,
                        children: List.generate(items.length, (index) {
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
                            child: Text(items[index], style: TextStyle(fontSize: hasLongText ? 24.0 : fontSize), textAlign: TextAlign.center),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';

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

              // 2x2 Grid of Category Cards
              Expanded(
                child: Center(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final isSelected = (_selectedIndex == index);
                      final isRight = isSelected && (index == correctIndex);
                      final isWrong = isSelected && (index != correctIndex);

                      return GestureDetector(
                        onTap: () => _checkAnswer(index, correctIndex, rounds.length),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
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
                            child: Text(items[index], style: const TextStyle(fontSize: 56)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              if (_isCorrect)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.gentleGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.white, size: 32),
                      const SizedBox(width: 8),
                      Text('විශිෂ්ටයි!', style: AppTypography.sinhala(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                )
              else
                const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }
}

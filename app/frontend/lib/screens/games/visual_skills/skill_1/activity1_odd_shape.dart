import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';

/// Activity 1: වෙනස් හැඩය සොයමු (Find the Different Shape)
/// Template: odd_one_out_game
class Activity1OddShape extends StatefulWidget {
  final ActivityNode? activityNode;
  const Activity1OddShape({super.key, this.activityNode});

  @override
  State<Activity1OddShape> createState() => _Activity1OddShapeState();
}

class _Activity1OddShapeState extends State<Activity1OddShape> {
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

    int score = (index == correctIndex) ? 100 : 0;
    context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(score);

    if (index == correctIndex) {
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
    final rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('වෙනස් හැඩය සොයමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'වෙනස් හැඩය සොයමු';
    final instructionText = widget.activityNode?.description ?? 'අනෙක් හැඩවලට වඩා වෙනස් හැඩය සොයා තෝරන්න.';

    final target = currentRound['target']?.toString() ?? '🔵';
    final distractor = (currentRound['distractors'] as List?)?.first?.toString() ?? '🟥';
    final totalCount = ((currentRound['target_count'] as int?) ?? 1) + ((currentRound['distractor_count'] as int?) ?? 3);
    final correctIndex = (currentRound['correct_index'] as int?) ?? 0;

    List<String> items = List.filled(totalCount, distractor);
    if (correctIndex < items.length) {
      items[correctIndex] = target;
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
                style: AppTypography.sinhala(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Grid Items
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: List.generate(items.length, (index) {
                      final isSelected = _selectedIndex == index;
                      final isCorrectSelection = isSelected && index == correctIndex;
                      final isWrongSelection = isSelected && index != correctIndex;

                      return GestureDetector(
                        onTap: () => _checkAnswer(index, correctIndex, rounds.length),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: isCorrectSelection
                                ? AppColors.gentleGreen.withValues(alpha: 0.3)
                                : isWrongSelection
                                    ? AppColors.softCoral.withValues(alpha: 0.3)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCorrectSelection
                                  ? AppColors.gentleGreen
                                  : isWrongSelection
                                      ? AppColors.softCoral
                                      : AppColors.borderLight,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(
                              items[index],
                              style: const TextStyle(fontSize: 48),
                            ),
                          ),
                        ),
                      );
                    }),
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

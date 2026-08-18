import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import 'widgets/shared_game_layout.dart';

/// Activity 1: වෙනස් හැඩය සොයමු (Find the Different Shape)
/// Template: odd_one_out_game
class Activity1OddShape extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Activity1OddShape({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Activity1OddShape> createState() => _Activity1OddShapeState();
}

class _Activity1OddShapeState extends State<Activity1OddShape> {
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
        appBar: AppBar(title: const Text('වෙනස් හැඩය සොයමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }
    
    // Anti-fatigue: limit to 5 rounds maximum
    if (rounds.length > 5) {
      rounds = rounds.sublist(0, 5);
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'වෙනස් හැඩය සොයමු';
    final instructionText = widget.activityNode?.description ?? 'අනෙක් හැඩවලට වඩා වෙනස් හැඩය සොයා තෝරන්න.';

    final target = currentRound['target']?.toString() ?? '🔵';
    final distractor = (currentRound['distractors'] as List?)?.first?.toString() ?? '🟥';
    
    int distractorCount = (currentRound['distractor_count'] as int?) ?? 3;
    if (widget.isRemedial && distractorCount > 2) {
      distractorCount = 2; // Cap distractors for remedial students
    }
    final totalCount = ((currentRound['target_count'] as int?) ?? 1) + distractorCount;
    
    // Ensure correct index is within bounds if we shrunk the grid
    final correctIndex = ((currentRound['correct_index'] as int?) ?? 0) % totalCount;

    List<String> items = List.filled(totalCount, distractor);
    if (correctIndex < items.length) {
      items[correctIndex] = target;
    }

    double itemSize;
    double spacing;
    double fontSize;
    final total = items.length;
    final bool hasLongText = items.any((opt) => opt.toString().length > 4 || opt.toString().contains(' '));
    
    if (total <= 2) {
      itemSize = 160.0;
      spacing = 32.0;
      fontSize = 80.0;
    } else if (total <= 4) {
      itemSize = 120.0;
      spacing = 20.0;
      fontSize = 64.0;
    } else if (total <= 6) {
      itemSize = 96.0; 
      spacing = 16.0;
      fontSize = 52.0;
    } else if (total <= 9) {
      itemSize = 80.0; 
      spacing = 12.0;
      fontSize = 42.0;
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      instructionText,
                      style: AppTypography.sinhala(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.volume_up_rounded, color: AppColors.calmBlue, size: 28),
                    onPressed: () async {
                      context.findAncestorStateOfType<TelemetryWrapperState>()?.logAudioReplay();
                      if (widget.activityNode?.audioUrl != null && widget.activityNode!.audioUrl.isNotEmpty) {
                        await _audioPlayer.play(UrlSource(widget.activityNode!.audioUrl));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 64),

              // Grid Items
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      alignment: WrapAlignment.center,
                      children: List.generate(items.length, (index) {
                      final isSelected = _selectedIndex == index;
                      final isCorrectSelection = isSelected && index == correctIndex;
                      final isWrongSelection = isSelected && index != correctIndex;

                      return GestureDetector(
                        onTap: () => _checkAnswer(index, correctIndex, rounds.length),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: hasLongText ? null : itemSize,
                          height: hasLongText ? null : itemSize,
                          padding: hasLongText ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16) : null,
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
                              style: TextStyle(fontSize: hasLongText ? 24.0 : fontSize), textAlign: TextAlign.center,
                            ),
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

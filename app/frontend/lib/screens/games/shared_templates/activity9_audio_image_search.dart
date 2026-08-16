import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import '../../../../services/tts_service.dart';

/// Activity 9: වචනයට සවන් දී රූපය සොයමු (Listen to Word & Find Image)
/// Template: audio_image_match_game
class Activity9AudioImageSearch extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Activity9AudioImageSearch({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Activity9AudioImageSearch> createState() => _Activity9AudioImageSearchState();
}

class _Activity9AudioImageSearchState extends State<Activity9AudioImageSearch> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedIndex;
  bool _isCorrect = false;
  int _currentRoundIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playAudioPrompt();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playAudioPrompt() {
    final rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty) return;

    final currentRound = rounds[_currentRoundIndex];
    final audioText = currentRound['audio_text']?.toString() ?? currentRound['prompt']?.toString() ?? 'වෘත්තය';
    TtsService().speak(audioText);
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
          _playAudioPrompt();
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
        appBar: AppBar(title: const Text('වචනයට සවන් දී රූපය සොයමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }
    
    if (rounds.length > 5) {
      rounds = rounds.sublist(0, 5);
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'වචනයට සවන් දී රූපය සොයමු';
    final promptText = currentRound['prompt']?.toString() ?? 'අසා සිටින රූපය තෝරන්න';
    var options = (currentRound['options'] as List?)?.map((e) => e.toString()).toList() ?? ['🔵', '🟥', '🔺', '⭐'];
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

              // Spoken Audio Prompt Button
              GestureDetector(
                onTap: () {
                  context.findAncestorStateOfType<TelemetryWrapperState>()?.logAudioReplay();
                  _playAudioPrompt();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.warmAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.warmAmber, width: 3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.volume_up_rounded, color: AppColors.warmAmber, size: 40),
                      const SizedBox(width: 12),
                      Text(
                        promptText,
                        style: AppTypography.sinhala(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '(නැවත ඇසීමට බොත්තම තට්ටු කරන්න)',
                style: AppTypography.sinhala(fontSize: 14, color: AppColors.textSecondary),
              ),

              const Spacer(),

              // Image Option Cards Grid
              Expanded(
                flex: 3,
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
                    itemCount: options.length,
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
                            child: Text(options[index], style: const TextStyle(fontSize: 56)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

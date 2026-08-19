import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import '../../../../services/tts_service.dart';
import '../shared_templates/widgets/shared_game_layout.dart';

/// Activity 9: වචනයට සවන් දී රූපය සොයමු (Listen to Word & Find Image)
/// Template: audio_image_match_game
class Skill2Act4Mcq extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Skill2Act4Mcq({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Skill2Act4Mcq> createState() => _Skill2Act4McqState();
}

class _Skill2Act4McqState extends State<Skill2Act4Mcq> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<int> _selectedIndices = {};
  bool _isCorrect = false;
  bool _activityComplete = false;
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

  void _checkAnswer(int index, List<int> correctIndices, int totalRounds) async {
    if (_isCorrect) return;

    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });

    if (_selectedIndices.length == correctIndices.length) {
      bool isRight = _selectedIndices.containsAll(correctIndices);
      
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
              _selectedIndices.clear();
              _isCorrect = false;
            });
            _playAudioPrompt();
          } else {
            setState(() {
              _activityComplete = true;
            });
          }
        });
      } else {
        await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _selectedIndices.clear();
            });
          }
        });
      }
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
    
    List<int> correctIndices = [];
    if (currentRound['correct_indices'] != null) {
      correctIndices = List<int>.from(currentRound['correct_indices']);
    } else if (currentRound['correct_index'] != null) {
      correctIndices = [currentRound['correct_index'] as int];
    } else {
      correctIndices = [0];
    }
    
    if (widget.isRemedial && options.length > correctIndices.length) {
      // Reduce distractors to max 1 + correct items
      List<String> correctItems = correctIndices.map((idx) => options[idx]).toList();
      var distractors = options.where((item) => !correctItems.contains(item)).toList();
      if (distractors.isNotEmpty) distractors = distractors.sublist(0, 1);
      options = [...correctItems, ...distractors];
      options.shuffle();
      correctIndices = correctItems.map((item) => options.indexOf(item)).toList();
    }

    double itemSize;
    double spacing;
    double fontSize;
    final total = options.length;
    final bool hasLongText = options.any((opt) => opt.toString().length > 4 || opt.toString().contains(' '));

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
                      Flexible(
                        child: Text(
                          promptText,
                          style: AppTypography.sinhala(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
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
              Builder(
                builder: (context) {
                  final RegExp quoteRegex = RegExp(r"'(.*?)'");
                  final match = quoteRegex.firstMatch(promptText);
                  final displayWord = currentRound['target_word']?.toString() ?? match?.group(1);
                  
                  if (displayWord != null && displayWord.isNotEmpty) {
                    return Column(
                      children: [
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4A90E2).withOpacity(0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Text(
                            displayWord,
                            style: AppTypography.sinhala(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF4A90E2),
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              if (correctIndices.length > 1) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'අකුරු ${correctIndices.length} ක් තෝරන්න (${_selectedIndices.length}/${correctIndices.length})', 
                    style: AppTypography.sinhala(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFE65100)),
                  ),
                ),
                const SizedBox(height: 36),
              ] else ...[
                const SizedBox(height: 48),
              ],

              // Image Option Cards Grid
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      alignment: WrapAlignment.center,
                      children: List.generate(options.length, (index) {
                      final isSelected = _selectedIndices.contains(index);
                      final isRight = isSelected && correctIndices.contains(index);
                      final isWrong = isSelected && !correctIndices.contains(index);

                      return GestureDetector(
                        onTap: () => _checkAnswer(index, correctIndices, rounds.length),
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
                            child: Text(options[index], style: TextStyle(fontSize: hasLongText ? 24.0 : fontSize), textAlign: TextAlign.center),
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

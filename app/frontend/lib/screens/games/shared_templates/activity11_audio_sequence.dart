import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import '../../../../services/tts_service.dart';
import 'widgets/shared_game_layout.dart';

/// Activity 11: වචන අනුපිළිවෙලට සවන් දී රූප පිලිවෙලින් පෙළගස්වමු (Listen to Audio Sequence & Order Images)
/// Template: audio_sequence_game
class Activity11AudioSequence extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Activity11AudioSequence({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Activity11AudioSequence> createState() => _Activity11AudioSequenceState();
}

class _Activity11AudioSequenceState extends State<Activity11AudioSequence> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<String> _userSequence = [];
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

  List<dynamic> get _rounds {
    var r = widget.activityNode?.rounds ?? [];
    return r.length > 5 ? r.sublist(0, 5) : r;
  }

  void _playAudioPrompt() {
    final rounds = _rounds;
    if (rounds.isEmpty) return;

    final currentRound = rounds[_currentRoundIndex];
    final prompt = currentRound['audio_prompt']?.toString() ?? 'රතු, නිල්, කහ';
    TtsService().speak(prompt);
  }

  void _onTileTapped(String tile, List<String> targetSequence, int totalRounds) async {
    if (_isCorrect) return;

    setState(() {
      _userSequence.add(tile);
    });

    final index = _userSequence.length - 1;
    if (_userSequence[index] != targetSequence[index]) {
      // Wrong tile placed
      await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _userSequence.clear();
          });
        }
      });
      return;
    }

    // Check if full sequence matched
    if (_userSequence.length == targetSequence.length) {
      context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(100);
      setState(() {
        _isCorrect = true;
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        if (_currentRoundIndex < totalRounds - 1) {
          setState(() {
            _currentRoundIndex++;
            _userSequence.clear();
            _isCorrect = false;
          });
          _playAudioPrompt();
        } else {
          setState(() {
            _activityComplete = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rounds = _rounds;
    if (rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('වචන අනුපිළිවෙලින් පෙළගස්වමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'වචන අනුපිළිවෙලින් පෙළගස්වමු';
    final targetSequence = (currentRound['target_sequence'] as List?)?.map((e) => e.toString()).toList() ?? (currentRound['sequence'] as List?)?.map((e) => e.toString()).toList() ?? ['🔴', '🔵', '🟡'];
    var options = (currentRound['options'] as List?)?.map((e) => e.toString()).toList() ?? ['🔴', '🔵', '🟡', '🟢', '🟣'];

    if (widget.isRemedial && options.length > targetSequence.length) {
      // Keep only required items + 1 distractor
      final requiredItems = targetSequence.toSet();
      final distractors = options.where((o) => !requiredItems.contains(o)).toList();
      options = requiredItems.toList();
      if (distractors.isNotEmpty) {
        options.add(distractors.first);
      }
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
      spacing = 16.0;
      fontSize = 48.0;
    } else if (total <= 6) {
      itemSize = 76.0; 
      spacing = 12.0;
      fontSize = 40.0;
    } else {
      itemSize = 64.0; 
      spacing = 8.0;
      fontSize = 32.0;
    }
    final audioPrompt = currentRound['audio_prompt']?.toString() ?? 'අනුපිළිවෙලට සවන් දෙන්න';

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
            // Audio Sequence Button
              GestureDetector(
                onTap: () {
                  context.findAncestorStateOfType<TelemetryWrapperState>()?.logAudioReplay();
                  _playAudioPrompt();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.warmAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.warmAmber, width: 3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.volume_up_rounded, color: AppColors.warmAmber, size: 36),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          audioPrompt,
                          style: AppTypography.sinhala(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Sequence Ordering Slots (1st, 2nd, 3rd)
                    Text('අනුපිළිවෙලින් සකසන්න:', style: AppTypography.sinhala(fontSize: 16, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(targetSequence.length, (i) {
                        final filled = i < _userSequence.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: filled ? AppColors.gentleGreen.withValues(alpha: 0.2) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: filled ? AppColors.gentleGreen : AppColors.borderLight,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              filled ? _userSequence[i] : '${i + 1}',
                              style: TextStyle(
                                fontSize: filled ? 36 : 20,
                                fontWeight: filled ? FontWeight.normal : FontWeight.bold,
                                color: filled ? Colors.black : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 64),

                    // Selectable Options Palette
                    Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      alignment: WrapAlignment.center,
                      children: options.map((tile) {
                        return GestureDetector(
                          onTap: () => _onTileTapped(tile, targetSequence, rounds.length),
                          child: Container(
                            width: hasLongText ? null : itemSize,
                          height: hasLongText ? null : itemSize,
                          padding: hasLongText ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16) : null,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.borderLight, width: 3),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))
                              ],
                            ),
                            child: Center(child: Text(tile, style: TextStyle(fontSize: hasLongText ? 24.0 : fontSize), textAlign: TextAlign.center)),
                          ),
                        );
                      }).toList(),
                    ),
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

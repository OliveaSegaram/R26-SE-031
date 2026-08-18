import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import 'widgets/shared_game_layout.dart';

/// Activity 3: රටාව මතක තබා ගනිමු (Remember the Pattern)
/// Template: pattern_memory_game
class Activity3RememberPattern extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Activity3RememberPattern({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Activity3RememberPattern> createState() => _Activity3RememberPatternState();
}

class _Activity3RememberPatternState extends State<Activity3RememberPattern> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMemorizing = true;
  int _countdown = 3;
  Timer? _timer;

  final List<String> _userSequence = [];
  bool _isCorrect = false;
  bool _activityComplete = false;
  int _currentRoundIndex = 0;

  @override
  void initState() {
    super.initState();
    _startMemorizeTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  List<dynamic> get _rounds {
    var r = widget.activityNode?.rounds ?? [];
    return r.length > 5 ? r.sublist(0, 5) : r;
  }

  void _startMemorizeTimer() {
    final rounds = _rounds;
    if (rounds.isEmpty) return;

    final currentRound = rounds[_currentRoundIndex];
    final showSeconds = (currentRound['show_seconds'] as int?) ?? 4;

    setState(() {
      _isMemorizing = true;
      _countdown = showSeconds;
      _userSequence.clear();
      _isCorrect = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isMemorizing = false;
        });
      }
    });
  }

  void _addItemToUserSequence(String item, List<String> targetPattern, int totalRounds) async {
    if (_isCorrect || _isMemorizing) return;

    setState(() {
      _userSequence.add(item);
    });

    // Check if user sequence matches target pattern so far
    final currentIndex = _userSequence.length - 1;
    if (_userSequence[currentIndex] != targetPattern[currentIndex]) {
      // Wrong item picked
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

    // Check if pattern completed
    if (_userSequence.length == targetPattern.length) {
      context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(100);
      setState(() {
        _isCorrect = true;
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        if (_currentRoundIndex < totalRounds - 1) {
          _currentRoundIndex++;
          _startMemorizeTimer();
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
        appBar: AppBar(title: const Text('රටාව මතක තබා ගනිමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'රටාව මතක තබා ගනිමු';
    final targetPattern = (currentRound['pattern'] as List?)?.map((e) => e.toString()).toList() ?? ['🔴', '🔵'];
    var options = (currentRound['options'] as List?)?.map((e) => e.toString()).toList() ?? ['🔴', '🔵', '🟢'];

    if (widget.isRemedial && options.length > 2) {
      // Reduce distractors: Keep only items in the target pattern + 1 distractor (if any)
      final requiredItems = targetPattern.toSet();
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
                    // Instruction Banner
                    Text(
                      _isMemorizing ? 'රටාව දෙස බලන්න! (${_countdown}s)' : 'මතකයෙන් රටාව නැවත සකසන්න:',
                      style: AppTypography.sinhala(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _isMemorizing ? AppColors.softCoral : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Target Pattern View / Recall Slots
                    Container(
                      padding: const EdgeInsets.all(20),
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
                        children: List.generate(targetPattern.length, (i) {
                          final itemToShow = _isMemorizing
                              ? targetPattern[i]
                              : (i < _userSequence.length ? _userSequence[i] : '?');
                          final isFilled = !_isMemorizing && i < _userSequence.length;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: isFilled ? AppColors.gentleGreen.withValues(alpha: 0.2) : AppColors.cream,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isFilled ? AppColors.gentleGreen : AppColors.borderLight,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                itemToShow,
                                style: TextStyle(
                                  fontSize: 32,
                                  color: itemToShow == '?' ? AppColors.textSecondary : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 64),

                    // Recall Candidate Palette (Disabled while memorizing)
                    if (!_isMemorizing) ...[
                      Text('පහත හැඩතල තට්ටු කරන්න:', style: AppTypography.sinhala(fontSize: 16, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        alignment: WrapAlignment.center,
                        children: options.map((opt) {
                          return GestureDetector(
                            onTap: () => _addItemToUserSequence(opt, targetPattern, rounds.length),
                            child: Container(
                              width: hasLongText ? null : itemSize,
                          height: hasLongText ? null : itemSize,
                          padding: hasLongText ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16) : null,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.borderLight, width: 3),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 3))
                                ],
                              ),
                              child: Center(child: Text(opt, style: TextStyle(fontSize: hasLongText ? 24.0 : fontSize), textAlign: TextAlign.center)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
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

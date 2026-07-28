import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';

/// Activity 3: රටාව මතක තබා ගනිමු (Remember the Pattern)
/// Template: pattern_memory_game
class Activity3RememberPattern extends StatefulWidget {
  final ActivityNode? activityNode;
  const Activity3RememberPattern({super.key, this.activityNode});

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

  void _startMemorizeTimer() {
    final rounds = widget.activityNode?.rounds ?? [];
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
          final wrapper = context.findAncestorStateOfType<TelemetryWrapperState>();
          if (wrapper != null) {
            wrapper.completeActivity(context);
          } else {
            Navigator.pop(context, 100);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('රටාව මතක තබා ගනිමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'රටාව මතක තබා ගනිමු';
    final targetPattern = (currentRound['pattern'] as List?)?.map((e) => e.toString()).toList() ?? ['🔴', '🔵'];
    final options = (currentRound['options'] as List?)?.map((e) => e.toString()).toList() ?? ['🔴', '🔵', '🟢'];

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
              const SizedBox(height: 20),

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

              const Spacer(),

              // Recall Candidate Palette (Disabled while memorizing)
              if (!_isMemorizing) ...[
                Text('පහත හැඩතල තට්ටු කරන්න:', style: AppTypography.sinhala(fontSize: 16, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: options.map((opt) {
                    return GestureDetector(
                      onTap: () => _addItemToUserSequence(opt, targetPattern, rounds.length),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderLight, width: 3),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 3))
                          ],
                        ),
                        child: Center(child: Text(opt, style: const TextStyle(fontSize: 36))),
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
    );
  }
}

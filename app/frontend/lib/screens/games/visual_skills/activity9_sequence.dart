import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/telemetry_wrapper.dart';
import '../../../models/curriculum_models.dart';

class Activity9Sequence extends StatefulWidget {
  final ActivityNode activityNode;
  const Activity9Sequence({super.key, required this.activityNode});

  @override
  State<Activity9Sequence> createState() => _Activity9SequenceState();
}

class SequenceRound {
  final List<String?> sequence;
  final List<String> options;
  final int correctOptionIndex;
  SequenceRound({required this.sequence, required this.options, required this.correctOptionIndex});
}

class _Activity9SequenceState extends State<Activity9Sequence> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int _currentRoundIndex = 0;
  late List<SequenceRound> _rounds;

  bool _isComplete = false;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _initRounds();
  }

  void _initRounds() {
    _rounds = widget.activityNode.rounds.map((roundData) {
      final rawSeq = roundData['sequence'] as List? ?? [];
      List<String?> sequence = rawSeq.map((e) => e?.toString()).toList();
      List<String> options = (roundData['options'] as List? ?? [])
          .map((e) => e.toString())
          .toList();
      int correctOptionIndex = roundData['correct_option_index'] ?? 0;
      
      if (sequence.isEmpty) {
        sequence = ['🥚', '🐣', '🐥', null];
      }
      if (options.isEmpty) {
        options = ['🍎', '🐔', '🐟'];
        correctOptionIndex = 1;
      }
      
      if (options.isNotEmpty && correctOptionIndex < options.length) {
        final correctOption = options[correctOptionIndex];
        options.shuffle();
        correctOptionIndex = options.indexOf(correctOption);
      }

      return SequenceRound(
        sequence: sequence,
        options: options,
        correctOptionIndex: correctOptionIndex,
      );
    }).toList();
  }

  void _checkAnswer(int index) async {
    if (_isComplete) return;

    setState(() {
      _selectedIndex = index;
    });

    final currentRound = _rounds[_currentRoundIndex];
    bool isCorrect = index == currentRound.correctOptionIndex;

    int score = isCorrect ? 100 : 0;
    context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(score);

    if (isCorrect) {
      setState(() {
        _isComplete = true;
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        if (_currentRoundIndex < _rounds.length - 1) {
          setState(() {
            _currentRoundIndex++;
            _selectedIndex = null;
            _isComplete = false;
          });
        } else {
          if (context.findAncestorStateOfType<TelemetryWrapperState>() != null) { context.findAncestorStateOfType<TelemetryWrapperState>()!.completeActivity(context); } else { Navigator.pop(context, 0); }
        }
      });
    } else {
      await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRound = _rounds[_currentRoundIndex];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          'රටාව සම්පූර්ණ කරන්න',
          style: AppTypography.sinhala(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Progression Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'වටය ${_currentRoundIndex + 1} / ${_rounds.length}',
                    style: AppTypography.sinhala(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentRoundIndex + 1) / _rounds.length,
                backgroundColor: AppColors.borderLight,
                color: AppColors.gentleGreen,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const Spacer(),

              Text(
                'මීළඟට එන්නේ කුමක්ද?',
                style: AppTypography.sinhala(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              
              // Sequence
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: currentRound.sequence.map((item) {
                  if (item == null) {
                    return Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 2, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: _isComplete 
                          ? Text(currentRound.options[currentRound.correctOptionIndex], style: const TextStyle(fontSize: 50)) 
                          : Text('?', style: GoogleFonts.fredoka(fontSize: 40, color: Colors.grey)),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(item, style: const TextStyle(fontSize: 60)),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 80),
              
              // Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(currentRound.options.length, (index) {
                  final isSelected = _selectedIndex == index;
                  final isCorrectSelection = isSelected && index == currentRound.correctOptionIndex;
                  final isWrongSelection = isSelected && index != currentRound.correctOptionIndex;

                  return GestureDetector(
                    onTap: () => _checkAnswer(index),
                    child: Container(
                      padding: const EdgeInsets.all(20),
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
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        currentRound.options[index],
                        style: const TextStyle(fontSize: 50),
                      ),
                    ),
                  );
                }),
              ),
              
              const Spacer(),
              if (_isComplete)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gentleGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        'විශිෂ්ටයි!',
                        style: AppTypography.sinhala(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

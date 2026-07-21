import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/telemetry_wrapper.dart';
import '../../../models/curriculum_models.dart';
import 'dart:math';

class Activity1SpotDifference extends StatefulWidget {
  final ActivityNode activityNode;
  const Activity1SpotDifference({super.key, required this.activityNode});

  @override
  State<Activity1SpotDifference> createState() => _Activity1SpotDifferenceState();
}

class SpotDifferenceRound {
  final List<String> items;
  final int correctIndex;
  SpotDifferenceRound({required this.items, required this.correctIndex});
}

class _Activity1SpotDifferenceState extends State<Activity1SpotDifference> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedIndex;
  bool _isCorrect = false;

  int _currentRoundIndex = 0;
  late List<SpotDifferenceRound> _rounds;

  @override
  void initState() {
    super.initState();
    _rounds = widget.activityNode.rounds.map((roundData) {
      final target = roundData['target'] as String;
      // Taking the first distractor for MVP, though the array can have multiple
      final distractor = (roundData['distractors'] as List).first as String;
      final totalCount = (roundData['target_count'] as int) + (roundData['distractor_count'] as int);
      final correctIndex = roundData['correct_index'] as int;

      List<String> items = List.filled(totalCount, distractor);
      items[correctIndex] = target;

      return SpotDifferenceRound(items: items, correctIndex: correctIndex);
    }).toList();
  }

  void _checkAnswer(int index) async {
    if (_isCorrect) return; // Prevent multiple clicks after success

    setState(() {
      _selectedIndex = index;
    });
    
    final currentRound = _rounds[_currentRoundIndex];
    
    // Use the TelemetryWrapper to record score and round completion
    int score = (index == currentRound.correctIndex) ? 100 : 0;
    context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(score);


    if (index == currentRound.correctIndex) {
      setState(() {
        _isCorrect = true;
      });
      // Play success sound
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        
        if (_currentRoundIndex < _rounds.length - 1) {
          setState(() {
            _currentRoundIndex++;
            _selectedIndex = null;
            _isCorrect = false;
          });
        } else {
          // Finished all rounds
          Navigator.pop(context, true);
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
          'වෙනස් රූපය සොයන්න',
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
                'වෙනස් රූපය තෝරන්න',
                style: AppTypography.sinhala(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: List.generate(currentRound.items.length, (index) {
                  final isSelected = _selectedIndex == index;
                  final isCorrectSelection = isSelected && index == currentRound.correctIndex;
                  final isWrongSelection = isSelected && index != currentRound.correctIndex;

                  return GestureDetector(
                    onTap: () => _checkAnswer(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
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
                        currentRound.items[index],
                        style: const TextStyle(fontSize: 60),
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(),
              if (_isCorrect)
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
                )
              else 
                const SizedBox(height: 64), // Placeholder to prevent jump
            ],
          ),
        ),
      ),
    );
  }
}

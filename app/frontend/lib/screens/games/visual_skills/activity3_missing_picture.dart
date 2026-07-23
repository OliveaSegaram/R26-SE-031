import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/telemetry_wrapper.dart';
import '../../../models/curriculum_models.dart';
import 'dart:math';

class Activity3MissingPicture extends StatefulWidget {
  final ActivityNode activityNode;
  const Activity3MissingPicture({super.key, required this.activityNode});

  @override
  State<Activity3MissingPicture> createState() => _Activity3MissingPictureState();
}

class MissingPictureRound {
  final List<String?> sequence;
  final List<String> options;
  final int correctOptionIndex;
  MissingPictureRound({required this.sequence, required this.options, required this.correctOptionIndex});
}

class _Activity3MissingPictureState extends State<Activity3MissingPicture> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedIndex;
  bool _isCorrect = false;

  int _currentRoundIndex = 0;
  late List<MissingPictureRound> _rounds;

  @override
  void initState() {
    super.initState();
    _rounds = widget.activityNode.rounds.map((roundData) {
      final sequence = List<String?>.from(roundData['sequence'] ?? []);
      List<String> options = List<String>.from(roundData['options'] ?? []);
      int correctOptionIndex = roundData['correct_option_index'] ?? 0;
      
      // Ensure the correct option is indeed at the correct index
      final correctOption = options[correctOptionIndex];
      options.shuffle();
      correctOptionIndex = options.indexOf(correctOption);

      return MissingPictureRound(
        sequence: sequence,
        options: options,
        correctOptionIndex: correctOptionIndex,
      );
    }).toList();
  }

  void _checkAnswer(int index) async {
    if (_isCorrect) return;

    setState(() {
      _selectedIndex = index;
    });
    final currentRound = _rounds[_currentRoundIndex];
    
    int score = (index == currentRound.correctOptionIndex) ? 100 : 0;
    context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(score);

    if (index == currentRound.correctOptionIndex) {
      setState(() {
        _isCorrect = true;
      });
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
          'අඩු රූපය සොයන්න',
          style: AppTypography.sinhala(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final isSmallScreen = availableHeight < 680;
            final double padding = isSmallScreen ? 14.0 : 20.0;
            final double sequenceFontSize = isSmallScreen ? 34.0 : 44.0;
            final double optionFontSize = isSmallScreen ? 38.0 : 48.0;
            final double optionPadding = isSmallScreen ? 12.0 : 16.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: availableHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Progression Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'වටය ${_currentRoundIndex + 1} / ${_rounds.length}',
                              style: AppTypography.sinhala(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: (_currentRoundIndex + 1) / _rounds.length,
                          backgroundColor: AppColors.borderLight,
                          color: AppColors.gentleGreen,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),

                        Text(
                          'හිස්තැනට සුදුසු රූපය තෝරන්න',
                          style: AppTypography.sinhala(fontSize: isSmallScreen ? 20 : 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 24 : 40),
                        
                        // Sequence
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Wrap(
                            spacing: isSmallScreen ? 8 : 14,
                            runSpacing: isSmallScreen ? 8 : 14,
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: currentRound.sequence.map((item) {
                              if (item == null) {
                                return Container(
                                  width: isSmallScreen ? 44 : 56,
                                  height: isSmallScreen ? 44 : 56,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.calmBlue, width: 2.5),
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.calmBlue.withValues(alpha: 0.08),
                                  ),
                                  child: Center(
                                    child: _isCorrect 
                                      ? Text(currentRound.options[currentRound.correctOptionIndex], style: TextStyle(fontSize: sequenceFontSize)) 
                                      : Text('?', style: GoogleFonts.fredoka(fontSize: isSmallScreen ? 26 : 32, color: AppColors.calmBlue)),
                                  ),
                                );
                              }
                              return Text(item, style: TextStyle(fontSize: sequenceFontSize));
                            }).toList(),
                          ),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 24 : 44),
                        
                        // Options
                        Wrap(
                          spacing: isSmallScreen ? 10 : 16,
                          runSpacing: isSmallScreen ? 10 : 16,
                          alignment: WrapAlignment.center,
                          children: List.generate(currentRound.options.length, (index) {
                            final isSelected = _selectedIndex == index;
                            final isCorrectSelection = isSelected && index == currentRound.correctOptionIndex;
                            final isWrongSelection = isSelected && index != currentRound.correctOptionIndex;

                            return GestureDetector(
                              onTap: () => _checkAnswer(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: EdgeInsets.all(optionPadding),
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
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    currentRound.options[index],
                                    style: TextStyle(fontSize: optionFontSize),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const Spacer(),
                        SizedBox(height: isSmallScreen ? 12 : 20),
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
                                Text(
                                  'විශිෂ්ටයි!',
                                  style: AppTypography.sinhala(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ],
                            ),
                          )
                        else 
                          SizedBox(height: isSmallScreen ? 36 : 48),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

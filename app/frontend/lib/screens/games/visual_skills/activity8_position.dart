import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/telemetry_wrapper.dart';
import '../../../models/curriculum_models.dart';
import 'dart:math' as math;

class Activity8Position extends StatefulWidget {
  final ActivityNode activityNode;
  const Activity8Position({super.key, required this.activityNode});

  @override
  State<Activity8Position> createState() => _Activity8PositionState();
}

class PositionRound {
  final List<String> sceneItems;
  final String question;
  final List<String> options;
  final String correctOption;
  PositionRound({required this.sceneItems, required this.question, required this.options, required this.correctOption});
}

class _Activity8PositionState extends State<Activity8Position> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int _currentRoundIndex = 0;
  late List<PositionRound> _rounds;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
  }

  void _initRounds() {
    _rounds = widget.activityNode.rounds.map((roundData) {
      List<String> sceneItems = List<String>.from(roundData['sceneItems'] ?? []);
      String question = roundData['question'] ?? roundData['raw_text'] ?? 'කොහෙද තියෙන්නේ?';
      List<String> options = List<String>.from(roundData['options'] ?? []);
      String correctOption = roundData['correctOption'] ?? '';
      
      if (sceneItems.isEmpty) {
        sceneItems = ['🐦', '🌳', '🐈'];
      }
      if (options.isEmpty) {
        options = ['🐦', '🐈', '🌸'];
        correctOption = '🐦';
      }
      if (correctOption.isEmpty && options.isNotEmpty) {
        correctOption = options[0];
      }
      
      options.shuffle();
      
      return PositionRound(sceneItems: sceneItems, question: question, options: options, correctOption: correctOption);
    }).toList();
  }

  void _checkAnswer(String option) async {
    if (_isComplete) return;

    final currentRound = _rounds[_currentRoundIndex];
    bool isCorrect = option == currentRound.correctOption;

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
            _isComplete = false;
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
          widget.activityNode.title.isNotEmpty ? widget.activityNode.title : 'පිහිටීම හඳුනාගැනීම',
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
            final double cardPadding = isSmallScreen ? 14.0 : 20.0;
            final double sceneFontSize = isSmallScreen ? 42.0 : 54.0;
            final double optionBoxSize = isSmallScreen ? 68.0 : 84.0;
            final double optionFontSize = isSmallScreen ? 28.0 : 36.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: availableHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
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

                        // Visual Scene Card
                        if (currentRound.sceneItems.isNotEmpty)
                          Container(
                            width: math.min(constraints.maxWidth * 0.8, 240),
                            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 18, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.lightBlue.shade50,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.lightBlue, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.lightBlue.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: currentRound.sceneItems.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(item, style: TextStyle(fontSize: sceneFontSize)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        
                        SizedBox(height: isSmallScreen ? 16 : 28),

                        // Question Prompt Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Text(
                            currentRound.question,
                            style: GoogleFonts.notoSansSinhala(
                              fontSize: isSmallScreen ? 18 : 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const Spacer(),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        
                        // Options Grid/Row
                        Wrap(
                          spacing: isSmallScreen ? 12 : 20,
                          runSpacing: isSmallScreen ? 12 : 20,
                          alignment: WrapAlignment.center,
                          children: currentRound.options.map((opt) {
                            final isCorrectSelection = _isComplete && opt == currentRound.correctOption;

                            return GestureDetector(
                              onTap: () => _checkAnswer(opt),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: optionBoxSize,
                                height: optionBoxSize,
                                decoration: BoxDecoration(
                                  color: isCorrectSelection ? AppColors.gentleGreen.withValues(alpha: 0.3) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isCorrectSelection ? AppColors.gentleGreen : AppColors.borderLight,
                                    width: isCorrectSelection ? 4 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(opt, style: TextStyle(fontSize: optionFontSize, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        
                        const Spacer(),
                        SizedBox(height: isSmallScreen ? 12 : 20),

                        if (_isComplete)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.gentleGreen,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gentleGreen.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
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
                          ),
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

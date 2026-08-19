import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import '../shared_templates/widgets/shared_game_layout.dart';

/// Skill 3 Activity 4 (Fill Blank Slot Matching Image)
/// Template: fill_blank_game
class Skill3Act4FillBlank extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Skill3Act4FillBlank({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Skill3Act4FillBlank> createState() => _Skill3Act4FillBlankState();
}

class _Skill3Act4FillBlankState extends State<Skill3Act4FillBlank>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedOptionIndex;
  bool _isCorrect = false;
  bool _activityComplete = false;
  int _currentRoundIndex = 0;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Pulsing glow for the blank slot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Bounce for correct answer
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _checkAnswer(int index, String selectedOption, String correctOption, int totalRounds) async {
    if (_isCorrect) return;

    setState(() {
      _selectedOptionIndex = index;
    });

    final bool isRight = (selectedOption == correctOption);
    int score = isRight ? 100 : 0;
    context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(score);

    if (isRight) {
      setState(() {
        _isCorrect = true;
      });
      _pulseController.stop();
      _bounceController.forward(from: 0.0);
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        if (_currentRoundIndex < totalRounds - 1) {
          setState(() {
            _currentRoundIndex++;
            _selectedOptionIndex = null;
            _isCorrect = false;
          });
          _pulseController.repeat(reverse: true);
          _bounceController.reset();
        } else {
          setState(() {
            _activityComplete = true;
          });
        }
      });
    } else {
      await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _selectedOptionIndex = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('හිස්තැන පුරවමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }
    
    if (rounds.length > 5) {
      rounds = rounds.sublist(0, 5);
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'රූපයට ගැලපෙන හිස්තැන පුරවමු';
    final instructionText = widget.activityNode?.description ?? 'රූප පෙළෙහි හිස්තැනට ගැලපෙන නිවැරදි රූපය තෝරන්න.';

    final sequence = (currentRound['sequence'] as List?)?.map((e) => e?.toString()).toList() ?? ['🔴', '🔵', null, '🟢'];
    var options = (currentRound['options'] as List?)?.map((e) => e.toString()).toList() ?? ['🟡', '🟣', '🔴', '⭐'];
    final correctOption = currentRound['correctOption']?.toString() ?? options.first;
    
    if (widget.isRemedial && options.length > 2) {
      var distractors = options.where((item) => item != correctOption).toList();
      if (distractors.isNotEmpty) distractors = distractors.sublist(0, 1);
      options = [correctOption, ...distractors];
      options.shuffle();
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildInstructionCard(instructionText),
                  const Spacer(flex: 1),

                  // ── Premium Sequence Card ──
                  _buildSequenceCard(sequence, correctOption),

                  const Spacer(flex: 2),

                  // ── Premium Answer Pool ──
                  _buildAnswerPool(options, correctOption, rounds.length),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Premium floating sequence card with animated blank slot
  Widget _buildSequenceCard(List<String?> sequence, String correctOption) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFDF5), Color(0xFFFFF8E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFE082).withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: sequence.map((item) {
          final isBlank = (item == null);
          final currentText = isBlank ? (_isCorrect ? correctOption : '') : item;
          final isWide = currentText.length > 1;

          if (isBlank) {
            return _buildBlankSlot(correctOption, isWide);
          } else {
            return _buildFilledSlot(item, isWide);
          }
        }).toList(),
      ),
    );
  }

  /// Animated pulsing blank slot with glowing border
  Widget _buildBlankSlot(String correctOption, bool isWide) {
    return AnimatedBuilder(
      animation: _isCorrect ? _bounceAnimation : _pulseAnimation,
      builder: (context, child) {
        final scale = _isCorrect ? _bounceAnimation.value : 1.0;
        final glowOpacity = _isCorrect ? 0.0 : _pulseAnimation.value;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: _isCorrect && correctOption.length > 1 ? 104.0 : 80.0,
            height: 80.0,
            decoration: BoxDecoration(
              color: _isCorrect
                  ? AppColors.gentleGreen.withValues(alpha: 0.15)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isCorrect
                    ? AppColors.gentleGreen
                    : Color.lerp(
                        const Color(0xFF64B5F6),
                        const Color(0xFF2196F3),
                        glowOpacity,
                      )!,
                width: 3,
              ),
              boxShadow: _isCorrect
                  ? [
                      BoxShadow(
                        color: AppColors.gentleGreen.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF64B5F6).withValues(alpha: glowOpacity * 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: _isCorrect
                  ? Text(
                      correctOption,
                      style: AppTypography.sinhala(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gentleGreen,
                      ),
                    )
                  : Icon(
                      Icons.help_outline_rounded,
                      size: 36,
                      color: Color.lerp(
                        const Color(0xFF90CAF9),
                        const Color(0xFF42A5F5),
                        glowOpacity,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  /// Filled (non-blank) letter slot with premium styling
  Widget _buildFilledSlot(String text, bool isWide) {
    return Container(
      width: isWide ? 104.0 : 80.0,
      height: 80.0,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9C4), Color(0xFFFFF176)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE082), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFE082).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: AppTypography.sinhala(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF5D4037),
          ),
        ),
      ),
    );
  }

  /// Premium answer pool with bouncy interactive tiles
  Widget _buildAnswerPool(List<String> options, String correctOption, int totalRounds) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 40, bottom: 24, left: 20, right: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.85),
                Colors.white.withValues(alpha: 0.5),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: List.generate(options.length, (index) {
              return _buildOptionTile(index, options[index], correctOption, totalRounds);
            }),
          ),
        ),
        // Touch indicator badge
        Positioned(
          top: 14,
          left: 22,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, size: 18, color: Color(0xFF4A90E2)),
                SizedBox(width: 4),
                Text(
                  'තෝරන්න',
                  style: TextStyle(fontSize: 11, color: Color(0xFF4A90E2), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Individual interactive option tile with bouncy feedback
  Widget _buildOptionTile(int index, String optionText, String correctOption, int totalRounds) {
    final isSelected = (_selectedOptionIndex == index);
    final isRight = isSelected && (optionText == correctOption);
    final isWrong = isSelected && (optionText != correctOption);
    final isHidden = _isCorrect && (optionText == correctOption);
    final isWide = optionText.length > 1;

    // Color scheme for the tile
    List<Color> gradientColors;
    Color shadowColor;
    Color borderColor;

    if (isRight) {
      gradientColors = const [Color(0xFFA5D6A7), Color(0xFF66BB6A)];
      shadowColor = const Color(0xFF66BB6A);
      borderColor = Colors.white;
    } else if (isWrong) {
      gradientColors = const [Color(0xFFFFCDD2), Color(0xFFEF9A9A)];
      shadowColor = Colors.red;
      borderColor = Colors.white;
    } else {
      gradientColors = const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)];
      shadowColor = const Color(0xFF90CAF9);
      borderColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => _checkAnswer(index, optionText, correctOption, totalRounds),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isHidden ? 0.0 : 1.0,
        child: AnimatedScale(
          scale: isWrong ? 0.9 : (isRight ? 1.1 : 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: Container(
            width: isWide ? 104.0 : 90.0,
            height: 90.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: borderColor, width: 4),
            ),
            child: Center(
              child: isRight
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 42)
                  : isWrong
                      ? const Icon(Icons.close_rounded, color: Colors.white, size: 42)
                      : Text(
                          optionText,
                          style: AppTypography.sinhala(
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }

  /// Premium instruction card with speaker icon
  Widget _buildInstructionCard(String instruction) {
    return GestureDetector(
      onTap: () {
        // TTS placeholder
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
                instruction,
                style: AppTypography.sinhala(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

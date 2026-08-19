import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import '../../../../services/tts_service.dart';
import '../shared_templates/widgets/shared_game_layout.dart';

/// Skill 3 Activity 2 (Word Formation MCQ)
/// Premium redesign: separates instruction from visual equation.
class Skill3Act2WordFormation extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Skill3Act2WordFormation({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Skill3Act2WordFormation> createState() => _Skill3Act2WordFormationState();
}

class _Skill3Act2WordFormationState extends State<Skill3Act2WordFormation>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedIndex;
  bool _isCorrect = false;
  bool _activityComplete = false;
  int _currentRoundIndex = 0;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _speakerBounceController;
  late Animation<double> _speakerBounceAnimation;

  @override
  void initState() {
    super.initState();

    // Pulsing glow for the speaker button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Speaker bounce when tapped
    _speakerBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _speakerBounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _speakerBounceController, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playAudioPrompt();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speakerBounceController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playAudioPrompt() {
    final rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty) return;

    final currentRound = rounds[_currentRoundIndex];
    // TTS should read the full prompt from JSON (e.g. "'ම' + 'ල' එකතු වූ විට...")
    final audioText = currentRound['audio_text']?.toString() ?? currentRound['prompt']?.toString() ?? 'වෘත්තය';
    TtsService().speak(audioText);

    // Bounce the speaker icon
    _speakerBounceController.forward().then((_) {
      _speakerBounceController.reverse();
    });
  }

  void _checkAnswer(int index, int correctIndex, int totalRounds) async {
    if (_isCorrect) return;
    if (_selectedIndex != null) return;

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
          _selectedIndex = null;
        });
      });
    }
  }

  /// Extracts the letters inside single quotes from the prompt string.
  /// Example: "'ම' + 'ල' එකතු වූ විට හැදෙන වචනය කුමක්ද?" -> ["ම", "ල"]
  List<String> _extractEquationParts(String promptText) {
    final regex = RegExp(r"'([^']+)'");
    final matches = regex.allMatches(promptText);
    return matches.map((m) => m.group(1) ?? '').where((s) => s.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    var rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('වචනය සකසන්න')),
        body: const Center(child: Text('No rounds available.')),
      );
    }

    if (rounds.length > 5) {
      rounds = rounds.sublist(0, 5);
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'වචනය සකසන්න';
    final promptText = currentRound['prompt']?.toString() ?? '';
    
    var options = (currentRound['options'] as List?)?.map((e) => e.toString()).toList() ?? ['🔵', '🟥', '🔺', '⭐'];
    var correctIndex = (currentRound['correct_index'] as int?) ?? 0;

    if (widget.isRemedial && options.length > 2) {
      final correctItem = options[correctIndex];
      var distractors = options.where((item) => item != correctItem).toList();
      if (distractors.isNotEmpty) distractors = distractors.sublist(0, 1);
      options = [correctItem, ...distractors];
      options.shuffle();
      correctIndex = options.indexOf(correctItem);
    }

    final equationParts = _extractEquationParts(promptText);

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
            const SizedBox(height: 8),

            // ── Premium Speaker Card (Common Instruction) ──
            _buildSpeakerCard(),

            const Spacer(flex: 1),

            // ── Visual Equation Component (e.g. ම + ල) ──
            if (equationParts.isNotEmpty) _buildEquationDisplay(equationParts),

            const Spacer(flex: 1),

            // ── Premium Answer Pool ──
            _buildAnswerPool(options, correctIndex, rounds.length),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  /// Premium animated speaker card with the generic instruction
  Widget _buildSpeakerCard() {
    return GestureDetector(
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
            ScaleTransition(
              scale: _speakerBounceAnimation,
              child: const Icon(Icons.volume_up_rounded, color: AppColors.warmAmber, size: 40),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'අකුරු එකතු කර හැදෙන වචනය තෝරන්න',
                style: AppTypography.sinhala(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Visually stunning equation component rendering [ම] + [ල]
  Widget _buildEquationDisplay(List<String> parts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFFFE082), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFE082).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          for (int i = 0; i < parts.length; i++) ...[
            // Letter Box
            Container(
              width: parts[i].length > 1 ? 104.0 : 80.0,
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
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  parts[i],
                  style: AppTypography.sinhala(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5D4037),
                  ),
                ),
              ),
            ),

            // Plus Sign
            if (i < parts.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFB300), // Amber darker
                  ),
                ),
              ),
          ],
        ],
      ),
      ),
    );
  }

  /// Premium answer pool container with frosted glass effect
  Widget _buildAnswerPool(List<String> options, int correctIndex, int totalRounds) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 44, bottom: 28, left: 24, right: 24),
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
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(options.length, (index) {
              return _buildOptionTile(index, options[index], correctIndex, totalRounds, options.length);
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
  Widget _buildOptionTile(int index, String optionText, int correctIndex, int totalRounds, int totalOptions) {
    final isSelected = (_selectedIndex == index);
    final isRight = isSelected && (index == correctIndex);
    final isWrong = isSelected && (index != correctIndex);
    final isHidden = _isCorrect && (index != correctIndex);

    final isWide = optionText.length > 2;

    double tileWidth;
    double tileHeight;
    double fontSize;

    if (totalOptions <= 2) {
      tileWidth = isWide ? 180.0 : 140.0;
      tileHeight = 100.0;
      fontSize = 52.0;
    } else if (totalOptions <= 3) {
      tileWidth = isWide ? 160.0 : 130.0;
      tileHeight = 90.0;
      fontSize = 46.0;
    } else if (totalOptions <= 4) {
      tileWidth = isWide ? 150.0 : 120.0;
      tileHeight = 85.0;
      fontSize = 42.0;
    } else {
      tileWidth = isWide ? 140.0 : 110.0;
      tileHeight = 80.0;
      fontSize = 38.0;
    }

    List<Color> gradientColors;
    Color shadowColor;
    Color borderColor;
    Color textColor;

    if (isRight) {
      gradientColors = const [Color(0xFFA5D6A7), Color(0xFF66BB6A)];
      shadowColor = const Color(0xFF66BB6A);
      borderColor = Colors.white;
      textColor = Colors.white;
    } else if (isWrong) {
      gradientColors = const [Color(0xFFFFCDD2), Color(0xFFEF9A9A)];
      shadowColor = Colors.red;
      borderColor = Colors.white;
      textColor = Colors.white;
    } else {
      gradientColors = const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)];
      shadowColor = const Color(0xFF90CAF9);
      borderColor = Colors.white;
      textColor = const Color(0xFF1565C0);
    }

    return GestureDetector(
      onTap: () => _checkAnswer(index, correctIndex, totalRounds),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isHidden ? 0.0 : 1.0,
        child: AnimatedScale(
          scale: isWrong ? 0.9 : (isRight ? 1.1 : 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: Container(
            width: tileWidth,
            height: tileHeight,
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
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              optionText,
                              style: AppTypography.sinhala(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

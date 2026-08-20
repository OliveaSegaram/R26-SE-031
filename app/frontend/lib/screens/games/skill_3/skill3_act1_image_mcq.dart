import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import '../../../../services/tts_service.dart';
import '../shared_templates/widgets/shared_game_layout.dart';

/// Skill 3 Activity 1 (Image MCQ)
/// Premium redesign: Displays a central Image and the child must select the matching word.
class Skill3Act1ImageMcq extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Skill3Act1ImageMcq({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Skill3Act1ImageMcq> createState() => _Skill3Act1ImageMcqState();
}

class _Skill3Act1ImageMcqState extends State<Skill3Act1ImageMcq>
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
  late AnimationController _imageBounceController;

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

    // Image pop-in animation
    _imageBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _imageBounceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playAudioPrompt();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speakerBounceController.dispose();
    _imageBounceController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playAudioPrompt() {
    final rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty) return;

    final currentRound = rounds[_currentRoundIndex];
    final audioText = currentRound['audio_text']?.toString() ?? currentRound['prompt']?.toString() ?? 'වෘත්තය';
    TtsService().speak(audioText);

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

      // Happy image bounce on success
      _imageBounceController.reset();
      _imageBounceController.forward();

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        if (_currentRoundIndex < totalRounds - 1) {
          setState(() {
            _currentRoundIndex++;
            _selectedIndex = null;
            _isCorrect = false;
          });
          _imageBounceController.reset();
          _imageBounceController.forward();
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

  @override
  Widget build(BuildContext context) {
    var rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('රූපයට ගැලපෙන වචනය තෝරන්න')),
        body: const Center(child: Text('No rounds available.')),
      );
    }

    if (rounds.length > 5) {
      rounds = rounds.sublist(0, 5);
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'රූපයට ගැලපෙන වචනය තෝරන්න';
    final promptText = currentRound['prompt']?.toString() ?? 'රූපයට ගැලපෙන වචනය තෝරන්න';
    final imageUrl = currentRound['image_url']?.toString() ?? '';
    
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

            // ── Premium Speaker Card (Instruction) ──
            _buildSpeakerCard(promptText),

            const Spacer(flex: 1),

            // ── Flashcard Container (Matches Act 5) ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: AppColors.borderLight, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Visual Image Card ──
                  _buildImageCard(imageUrl),

                  const SizedBox(height: 32),

                  // ── Premium Answer Pool ──
                  _buildAnswerPool(options, correctIndex, rounds.length),
                ],
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerCard(String promptText) {
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
                promptText,
                style: AppTypography.sinhala(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Visually stunning central card that displays the real PNG image
  Widget _buildImageCard(String imageUrl) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _imageBounceController, curve: Curves.elasticOut),
      ),
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.warmAmber.withValues(alpha: 0.2),
              blurRadius: 16,
              spreadRadius: 4,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Image.asset(
                imageUrl,
                key: ValueKey<String>(imageUrl), // Forces animation on change
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if the image doesn't exist yet
                  return const Icon(
                    Icons.image_not_supported_rounded,
                    color: Colors.grey,
                    size: 64,
                  );
                },
              ),
            ),
          ),
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
          padding: const EdgeInsets.only(top: 40, bottom: 24, left: 16, right: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF0F4F8).withValues(alpha: 0.85),
                Colors.white.withValues(alpha: 0.5),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(options.length, (index) {
              return _buildOptionTile(index, options[index], correctIndex, totalRounds, options.length);
            }),
          ),
        ),
        // Touch indicator badge
        Positioned(
          top: 12,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF4A90E2)),
                SizedBox(width: 6),
                Text(
                  'තෝරන්න',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4A90E2), fontWeight: FontWeight.w700),
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

    final isWide = optionText.length > 3;

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

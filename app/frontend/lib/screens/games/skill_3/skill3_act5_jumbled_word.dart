import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import '../../../../services/tts_service.dart';
import '../shared_templates/widgets/shared_game_layout.dart';

class PlacedLetter {
  final String letter;
  final int poolIndex;
  PlacedLetter(this.letter, this.poolIndex);
}

class Skill3Act5JumbledWord extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Skill3Act5JumbledWord({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Skill3Act5JumbledWord> createState() => _Skill3Act5JumbledWordState();
}

class _Skill3Act5JumbledWordState extends State<Skill3Act5JumbledWord> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isCorrect = false;
  bool _activityComplete = false;
  int _currentRoundIndex = 0;

  List<PlacedLetter?> _filledSlots = [];
  List<String?> _poolLetters = [];
  bool _isChecking = false;
  bool _showError = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnimation = Tween<double>(begin: 0, end: 24)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _initRound();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _initRound() {
    final rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty) return;

    final currentRound = rounds[_currentRoundIndex];
    final scrambledList = (currentRound['scrambled_letters'] as List?)?.map((e) => e.toString()).toList() ?? [];
    
    setState(() {
      _poolLetters = List.from(scrambledList);
      _filledSlots = List.filled(scrambledList.length, null);
      _isCorrect = false;
      _isChecking = false;
      _showError = false;
    });
  }

  void _onPoolLetterTapped(int poolIndex) async {
    if (_isChecking || _poolLetters[poolIndex] == null) return;

    // Find first empty slot
    int emptySlotIndex = _filledSlots.indexWhere((s) => s == null);
    if (emptySlotIndex != -1) {
      final letter = _poolLetters[poolIndex]!;
      setState(() {
        _filledSlots[emptySlotIndex] = PlacedLetter(letter, poolIndex);
        _poolLetters[poolIndex] = null;
        _showError = false;
      });
      
      // Speak the letter
      TtsService().speak(letter);
      
      // Check if all slots are filled
      if (!_filledSlots.contains(null)) {
        _validateAnswer();
      }
    }
  }

  void _onSlotTapped(int slotIndex) {
    if (_isChecking || _filledSlots[slotIndex] == null) return;

    setState(() {
      final placed = _filledSlots[slotIndex]!;
      _poolLetters[placed.poolIndex] = placed.letter;
      _filledSlots[slotIndex] = null;
      _showError = false;
    });
  }

  void _validateAnswer() async {
    setState(() {
      _isChecking = true;
    });

    final rounds = widget.activityNode?.rounds ?? [];
    final currentRound = rounds[_currentRoundIndex];
    final correctWord = currentRound['correct_word']?.toString() ?? "";
    
    final formedWord = _filledSlots.map((e) => e!.letter).join("");

    if (formedWord == correctWord) {
      // Correct
      setState(() {
        _isCorrect = true;
      });
      context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(100);
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        if (_currentRoundIndex < rounds.length - 1) {
          _currentRoundIndex++;
          _initRound();
        } else {
          setState(() {
            _activityComplete = true;
          });
        }
      });
    } else {
      // Incorrect
      context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(0);
      await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
      
      setState(() {
        _showError = true;
      });
      
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        // Return all letters to pool
        setState(() {
          for (int i = 0; i < _filledSlots.length; i++) {
            if (_filledSlots[i] != null) {
              _poolLetters[_filledSlots[i]!.poolIndex] = _filledSlots[i]!.letter;
              _filledSlots[i] = null;
            }
          }
          _showError = false;
          _isChecking = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('අකුරු පිළිවෙලට සකසමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }
    
    if (rounds.length > 5) {
      rounds = rounds.sublist(0, 5);
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'අකුරු පිළිවෙලට සකසමු';
    final promptText = currentRound['prompt']?.toString() ?? 'රූපයට අදාළ වචනය සාදන්න';
    final emoji = currentRound['emoji']?.toString();
    final imageUrl = currentRound['image_url']?.toString();

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
                  _buildInstructionCard(promptText),
                  const Spacer(flex: 1),

                  // Flashcard Container with Image & Answer Slots
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
                        // Top: Image
                        Container(
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
                            child: imageUrl != null
                                ? Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Image.asset(imageUrl, fit: BoxFit.contain),
                                  )
                                : Text(emoji ?? '🧩', style: const TextStyle(fontSize: 60)),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Bottom: Answer Slots
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(sin(_shakeAnimation.value * pi) * 10, 0),
                              child: child,
                            );
                          },
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: List.generate(_filledSlots.length, (index) {
                              final slot = _filledSlots[index];
                              final isFilled = slot != null;
                              return GestureDetector(
                                onTap: () => _onSlotTapped(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 76,
                                  height: 76,
                                    decoration: BoxDecoration(
                                      color: _isCorrect 
                                        ? AppColors.gentleGreen.withValues(alpha: 0.2)
                                        : _showError
                                          ? AppColors.softCoral.withValues(alpha: 0.2)
                                          : isFilled ? Colors.white : AppColors.cream,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _isCorrect
                                          ? AppColors.gentleGreen
                                          : _showError
                                            ? AppColors.softCoral
                                            : isFilled ? AppColors.calmBlue : AppColors.borderLight,
                                        width: isFilled ? 3 : 2,
                                      ),
                                      boxShadow: isFilled ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ] : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        isFilled ? slot.letter : '',
                                        style: AppTypography.sinhala(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w700,
                                          color: _isCorrect ? AppColors.gentleGreen : _showError ? AppColors.softCoral : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Scrambled Letter Pool (Bigger)
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 36, bottom: 20, left: 16, right: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          alignment: WrapAlignment.center,
                          children: List.generate(_poolLetters.length, (index) {
                            final letter = _poolLetters[index];
                            final isAvailable = letter != null;
                            return GestureDetector(
                              onTap: () => _onPoolLetterTapped(index),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isAvailable ? 1.0 : 0.0,
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFEEAA), Color(0xFFFFD54F)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      )
                                    ],
                                    border: Border.all(color: Colors.white, width: 4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      letter ?? '',
                                      style: AppTypography.sinhala(
                                        fontSize: 46,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const Positioned(
                        top: 16,
                        left: 20,
                        child: Icon(Icons.touch_app_rounded, size: 24, color: Color(0xFF4A90E2)),
                      ),
                    ],
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard(String instruction) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            context.findAncestorStateOfType<TelemetryWrapperState>()?.logAudioReplay();
            TtsService().speak(instruction);
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
        ),
      ],
    );
  }
}

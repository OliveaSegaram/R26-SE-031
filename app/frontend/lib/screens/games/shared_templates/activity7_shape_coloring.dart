import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import 'widgets/shared_game_layout.dart';

/// Activity 7: හැඩතලවලට පාට කරමු (Color the Shapes)
/// Template: coloring_game
class Activity7ShapeColoring extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Activity7ShapeColoring({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Activity7ShapeColoring> createState() => _Activity7ShapeColoringState();
}

class _Activity7ShapeColoringState extends State<Activity7ShapeColoring> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedPaletteIndex;
  Color? _shapeFillColor;
  bool _isCorrect = false;
  bool _activityComplete = false;
  int _currentRoundIndex = 0;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  void _onShapeTapped(int correctColorIndex, int totalRounds) async {
    if (_selectedPaletteIndex == null || _isCorrect) return;

    final isRight = (_selectedPaletteIndex == correctColorIndex);
    int score = isRight ? 100 : 0;

    context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(score);

    if (isRight) {
      final rounds = widget.activityNode?.rounds ?? [];
      final currentRound = rounds[_currentRoundIndex];
      final targetHex = currentRound['target_color']?.toString() ?? '#FF3B30';

      setState(() {
        _shapeFillColor = _parseHexColor(targetHex);
        _isCorrect = true;
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        if (_currentRoundIndex < totalRounds - 1) {
          setState(() {
            _currentRoundIndex++;
            _selectedPaletteIndex = null;
            _shapeFillColor = null;
            _isCorrect = false;
          });
        } else {
          setState(() {
            _activityComplete = true;
          });
        }
      });
    } else {
      await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
    }
  }

  @override
  Widget build(BuildContext context) {
    var rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('හැඩතලවලට පාට කරමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }
    
    if (rounds.length > 5) {
      rounds = rounds.sublist(0, 5);
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'හැඩතලවලට පාට කරමු';
    final shapeSymbol = currentRound['shape']?.toString() ?? '🔵';
    final shapeName = currentRound['shape_name']?.toString() ?? 'වෘත්තය (Circle)';
    final colorName = currentRound['color_name']?.toString() ?? 'රතු පාට (Red)';
    var paletteHex = (currentRound['palette'] as List?)?.map((e) => e.toString()).toList() ?? ['#FF3B30', '#007AFF', '#FFCC00', '#34C759'];
    var correctColorIndex = (currentRound['correct_color_index'] as int?) ?? 0;
    
    if (widget.isRemedial && paletteHex.length > 2) {
      // Reduce distractors to max 1 + 1 correct = 2 options total
      final correctItem = paletteHex[correctColorIndex];
      var distractors = paletteHex.where((item) => item != correctItem).toList();
      if (distractors.isNotEmpty) distractors = distractors.sublist(0, 1);
      paletteHex = [correctItem, ...distractors];
      paletteHex.shuffle();
      correctColorIndex = paletteHex.indexOf(correctItem);
    }

    double itemSize;
    double spacing;
    double targetSize;
    final total = paletteHex.length;

    if (total <= 2) {
      itemSize = 96.0;
      spacing = 24.0;
      targetSize = 180.0;
    } else if (total <= 4) {
      itemSize = 72.0;
      spacing = 16.0;
      targetSize = 180.0;
    } else if (total <= 6) {
      itemSize = 64.0; 
      spacing = 12.0;
      targetSize = 140.0;
    } else if (total <= 9) {
      itemSize = 56.0; 
      spacing = 10.0;
      targetSize = 120.0;
    } else {
      itemSize = 48.0; 
      spacing = 8.0;
      targetSize = 100.0;
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
                    const SizedBox(height: 16),
                    // Instruction Prompt
                    Text(
                      '$shapeName $colorName න් පාට කරන්න!',
                      style: AppTypography.sinhala(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Interactive Shape Canvas Target
                    GestureDetector(
                      onTap: () => _onShapeTapped(correctColorIndex, rounds.length),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: targetSize,
                        height: targetSize,
                        decoration: BoxDecoration(
                          color: _shapeFillColor ?? Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _shapeFillColor != null ? _shapeFillColor! : AppColors.primary,
                            width: 6,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6))
                          ],
                        ),
                        child: Center(
                          child: Text(
                            shapeSymbol,
                            style: TextStyle(
                              fontSize: targetSize * 0.44,
                              color: _shapeFillColor != null ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 64),

              // Color Palette Selector
              Text('පහතින් නිවැරදි වර්ණය තෝරන්න:', style: AppTypography.sinhala(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                alignment: WrapAlignment.center,
                children: List.generate(paletteHex.length, (index) {
                  final color = _parseHexColor(paletteHex[index]);
                  final isSelected = (_selectedPaletteIndex == index);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPaletteIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: itemSize,
                      height: itemSize,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.white,
                          width: isSelected ? 4 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))
                        ],
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 32) : null,
                    ),
                  );
                }),
              ),
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

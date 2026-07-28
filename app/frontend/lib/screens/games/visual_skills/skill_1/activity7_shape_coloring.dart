import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';

/// Activity 7: හැඩතලවලට පාට කරමු (Color the Shapes)
/// Template: coloring_game
class Activity7ShapeColoring extends StatefulWidget {
  final ActivityNode? activityNode;
  const Activity7ShapeColoring({super.key, this.activityNode});

  @override
  State<Activity7ShapeColoring> createState() => _Activity7ShapeColoringState();
}

class _Activity7ShapeColoringState extends State<Activity7ShapeColoring> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedPaletteIndex;
  Color? _shapeFillColor;
  bool _isCorrect = false;
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
          final wrapper = context.findAncestorStateOfType<TelemetryWrapperState>();
          if (wrapper != null) {
            wrapper.completeActivity(context);
          } else {
            Navigator.pop(context, 100);
          }
        }
      });
    } else {
      await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('හැඩතලවලට පාට කරමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'හැඩතලවලට පාට කරමු';
    final shapeSymbol = currentRound['shape']?.toString() ?? '🔵';
    final shapeName = currentRound['shape_name']?.toString() ?? 'වෘත්තය (Circle)';
    final colorName = currentRound['color_name']?.toString() ?? 'රතු පාට (Red)';
    final paletteHex = (currentRound['palette'] as List?)?.map((e) => e.toString()).toList() ?? ['#FF3B30', '#007AFF', '#FFCC00', '#34C759'];
    final correctColorIndex = (currentRound['correct_color_index'] as int?) ?? 0;

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
                  width: 180,
                  height: 180,
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
                        fontSize: 80,
                        color: _shapeFillColor != null ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Color Palette Selector
              Text('පහතින් නිවැරදි වර්ණය තෝරන්න:', style: AppTypography.sinhala(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 16,
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
                      width: 64,
                      height: 64,
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
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_models.dart';
import '../theme/app_theme.dart';
import '../widgets/adapted_mind_ui.dart';
import '../widgets/gradient_button.dart';
import '../widgets/kid_art.dart';

/// Word build — picture center, letters orbiting, navy/mint child-friendly UI.
class GuidedWordBuildView extends StatefulWidget {
  const GuidedWordBuildView({
    super.key,
    required this.question,
    required this.slots,
    required this.tileBag,
    required this.onTile,
    required this.onSlotTap,
    required this.onSubmit,
    required this.onSpeak,
    required this.onClear,
    this.feedback,
  });

  final TaskQuestion question;
  final List<String> slots;
  final List<String> tileBag;
  final String? feedback;
  final void Function(String) onTile;
  final void Function(int) onSlotTap;
  final VoidCallback onSubmit;
  final Future<void> Function(String) onSpeak;
  final VoidCallback onClear;

  @override
  State<GuidedWordBuildView> createState() => _GuidedWordBuildViewState();
}

class _GuidedWordBuildViewState extends State<GuidedWordBuildView> {
  static const _tileColors = [
    Color(0xFFFF6B9D),
    Color(0xFFFFD166),
    Color(0xFF2DD4A8),
    Color(0xFFFF7B3A),
    Color(0xFF6EEECF),
    Color(0xFFFF9F6C),
  ];

  bool get _allFilled => !widget.slots.any((s) => s.isEmpty);

  String? get _nextCorrectLetter {
    final seq = widget.question.correctSequence;
    for (var i = 0; i < widget.slots.length; i++) {
      if (widget.slots[i].isEmpty && i < seq.length) return seq[i];
    }
    return null;
  }

  String get _ghostHint {
    final buf = StringBuffer();
    for (var i = 0; i < widget.slots.length; i++) {
      if (widget.slots[i].isNotEmpty) {
        buf.write(widget.slots[i]);
      } else {
        buf.write('·');
      }
      if (i < widget.slots.length - 1) buf.write(' ');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final orbitSize = math.min(constraints.maxWidth - 16, constraints.maxHeight * 0.52)
            .clamp(200.0, 320.0);
        final pictureSize = orbitSize * 0.46;
        final orbitRadius = pictureSize * 0.62 + 42;
        final tileSize = widget.tileBag.length > 6 ? 48.0 : 54.0;
        final center = orbitSize / 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Text(
                      widget.question.prompt,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: SizedBox(
                        width: orbitSize,
                        height: orbitSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Picture + ghost word in center
                            Align(
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => widget.onSpeak(widget.question.targetWord ?? ''),
                                    child: Container(
                                      width: pictureSize,
                                      height: pictureSize,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.mint.withValues(alpha: 0.45),
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.mint.withValues(alpha: 0.15),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: KidArt(visual: widget.question.visual),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _ghostHint,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textLight.withValues(
                                        alpha: _allFilled ? 0.9 : 0.2,
                                      ),
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Letter tiles around the picture
                            ..._orbitTiles(
                              center: center,
                              radius: orbitRadius,
                              tileSize: tileSize,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.slots.length, (i) {
                        final s = widget.slots[i];
                        final box = widget.slots.length > 5 ? 44.0 : 52.0;
                        return GestureDetector(
                          onTap: () => widget.onSlotTap(i),
                          child: Container(
                            width: box,
                            height: box + 4,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.darkSlateLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: s.isEmpty
                                    ? AppColors.textLight.withValues(alpha: 0.12)
                                    : AppColors.mint,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              s.isEmpty ? '?' : s,
                              style: GoogleFonts.fredoka(
                                fontSize: widget.slots.length > 5 ? 20 : 24,
                                fontWeight: FontWeight.w700,
                                color: s.isEmpty ? AppColors.textMuted : AppColors.textLight,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: widget.onClear,
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppColors.textMuted, size: 18),
                          label: Text(
                            'නැවත',
                            style: GoogleFonts.nunito(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        AmSpeakerBtn(
                          onTap: () => widget.onSpeak(widget.question.targetWord ?? ''),
                          size: 40,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Opacity(
                opacity: _allFilled ? 1.0 : 0.45,
                child: GradientButton(
                  text: 'හරි! ඊළඟ එක',
                  height: 50,
                  gradient: AppColors.mintGradient,
                  onPressed: _allFilled ? widget.onSubmit : () {},
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _orbitTiles({
    required double center,
    required double radius,
    required double tileSize,
  }) {
    final tiles = widget.tileBag;
    if (tiles.isEmpty) return const [];

    return List.generate(tiles.length, (i) {
      final angle = (2 * math.pi * i / tiles.length) - math.pi / 2;
      final x = center + radius * math.cos(angle) - tileSize / 2;
      final y = center + radius * math.sin(angle) - tileSize / 2;
      final color = _tileColors[i % _tileColors.length];
      final letter = tiles[i];
      final isNext = letter == _nextCorrectLetter;

      return Positioned(
        left: x,
        top: y,
        child: _LetterOrb(
          letter: letter,
          color: color,
          size: tileSize,
          highlight: isNext,
          onTap: () => widget.onTile(letter),
        ),
      );
    });
  }
}

class _LetterOrb extends StatefulWidget {
  const _LetterOrb({
    required this.letter,
    required this.color,
    required this.size,
    required this.onTap,
    this.highlight = false,
  });

  final String letter;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final bool highlight;

  @override
  State<_LetterOrb> createState() => _LetterOrbState();
}

class _LetterOrbState extends State<_LetterOrb> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.highlight) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _LetterOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlight && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.highlight) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.highlight ? 1.0 + _pulse.value * 0.08 : 1.0;

    return Transform.scale(
      scale: scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.darkSlateLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.highlight ? widget.color : widget.color.withValues(alpha: 0.5),
                width: widget.highlight ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: widget.highlight ? 0.35 : 0.15),
                  blurRadius: widget.highlight ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  widget.letter,
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
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

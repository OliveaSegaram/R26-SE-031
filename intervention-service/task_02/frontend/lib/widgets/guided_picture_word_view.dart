import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_models.dart';
import '../theme/app_theme.dart';
import '../theme/teacher_assets.dart';
import 'kid_art.dart';
import 'monster_character.dart';

const _kTileHeight = 54.0;
const _kTileGap = 10.0;

/// Picture → word task — navy card, mascot hint, glowing picture, colorful tiles.
class GuidedPictureWordView extends StatefulWidget {
  const GuidedPictureWordView({
    super.key,
    required this.question,
    required this.onPick,
    required this.onSpeak,
    this.selectedId,
  });

  final TaskQuestion question;
  final void Function(String) onPick;
  final Future<void> Function(String) onSpeak;
  final String? selectedId;

  @override
  State<GuidedPictureWordView> createState() => _GuidedPictureWordViewState();
}

class _GuidedPictureWordViewState extends State<GuidedPictureWordView>
    with SingleTickerProviderStateMixin {
  static const _tileColors = [
    Color(0xFFFF6B9D),
    Color(0xFFFFD166),
    Color(0xFF2DD4A8),
    Color(0xFFFF7B3A),
  ];

  late AnimationController _glowController;
  late Animation<double> _glowTween;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _glowTween = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  String get _ghostText {
    final len = widget.question.options
        .map((o) => o.label.length)
        .fold<int>(0, (a, b) => b > a ? b : a);
    if (len <= 1) return '·';
    return List.filled(len.clamp(2, 8), '·').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.question.options;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;
        final pictureSize = math
            .min(
              constraints.maxWidth * (narrow ? 0.42 : 0.34),
              constraints.maxHeight * (narrow ? 0.28 : 0.24),
            )
            .clamp(100.0, narrow ? 140.0 : 150.0);

        return Container(
          width: double.infinity,
          height: constraints.maxHeight,
          margin: EdgeInsets.symmetric(horizontal: narrow ? 0 : 2),
          decoration: BoxDecoration(
            gradient: AppColors.splashGradient,
            borderRadius: BorderRadius.circular(narrow ? 18 : 24),
            border: Border.all(color: AppColors.mint.withValues(alpha: 0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(narrow ? 18 : 24),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        narrow ? 12 : 16,
                        narrow ? 10 : 14,
                        narrow ? 12 : 16,
                        0,
                      ),
                      child: Text(
                        widget.question.prompt,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                      ),
                    ),
                    SizedBox(height: narrow ? 6 : 10),
                    Center(
                      child: AnimatedBuilder(
                        animation: _glowTween,
                        builder: (context, child) {
                          final glow = 0.35 + _glowTween.value * 0.35;
                          return Transform.scale(
                            scale: 1.0 + _glowTween.value * 0.02,
                            child: Container(
                              width: pictureSize,
                              height: pictureSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.mint.withValues(alpha: glow),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.mint.withValues(alpha: glow * 0.4),
                                    blurRadius: 14 + _glowTween.value * 8,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: child,
                            ),
                          );
                        },
                        child: KidArt(visual: widget.question.visual),
                      ),
                    ),
                    if (!narrow) const SizedBox(height: 8),
                    if (!narrow)
                      Center(
                        child: Text(
                          _ghostText,
                          style: GoogleFonts.fredoka(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight.withValues(alpha: 0.18),
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    SizedBox(height: narrow ? 4 : 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          children: List.generate(options.length, (index) {
                            final o = options[index];
                            final color = _tileColors[index % _tileColors.length];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < options.length - 1 ? _kTileGap : 0,
                              ),
                              child: _WordTile(
                                label: o.label,
                                color: color,
                                index: index,
                                selected: widget.selectedId == o.id,
                                onTap: () => widget.onPick(o.id),
                                onSpeak: () => widget.onSpeak(o.label),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!narrow)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _MascotHint(message: widget.question.prompt),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Friendly mascot + speech bubble instead of a pointing hand.
class _MascotHint extends StatelessWidget {
  const _MascotHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        MonsterCharacter(
          size: 48,
          imagePath: TeacherAssets.guruthumiya,
        ),
        const SizedBox(width: 4),
        Container(
          constraints: const BoxConstraints(maxWidth: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.mint.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _WordTile extends StatefulWidget {
  const _WordTile({
    required this.label,
    required this.color,
    required this.index,
    required this.onTap,
    required this.onSpeak,
    this.selected = false,
  });

  final String label;
  final Color color;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onSpeak;
  final bool selected;

  @override
  State<_WordTile> createState() => _WordTileState();
}

class _WordTileState extends State<_WordTile> with SingleTickerProviderStateMixin {
  late AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    Future<void>.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _enter.forward();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutBack));

    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: _enter,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: _kTileHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: widget.selected
                    ? widget.color.withValues(alpha: 0.22)
                    : AppColors.darkSlateLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.selected
                      ? widget.color
                      : widget.color.withValues(alpha: 0.4),
                  width: widget.selected ? 2.5 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onSpeak,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.volume_up_rounded,
                        color: widget.color,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

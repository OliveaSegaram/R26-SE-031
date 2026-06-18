import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_models.dart';
import '../theme/app_theme.dart';
import '../theme/teacher_assets.dart';
import 'kid_art.dart';
import 'monster_character.dart';

/// Word → picture match — big word on top, tap the right picture below.
class GuidedWordMatchView extends StatefulWidget {
  const GuidedWordMatchView({
    super.key,
    required this.question,
    required this.onPick,
    required this.onSpeakWord,
    this.selectedId,
    this.showResult,
  });

  final TaskQuestion question;
  final void Function(String) onPick;
  final Future<void> Function() onSpeakWord;
  final String? selectedId;
  final bool? showResult;

  @override
  State<GuidedWordMatchView> createState() => _GuidedWordMatchViewState();
}

class _GuidedWordMatchViewState extends State<GuidedWordMatchView> {
  static const _borderColors = [
    Color(0xFFFF6B9D),
    Color(0xFF2DD4A8),
    Color(0xFFFF7B3A),
    Color(0xFF6B9FFF),
  ];

  @override
  Widget build(BuildContext context) {
    final word = widget.question.displayWord ?? widget.question.targetWord ?? '';
    final options = widget.question.options.take(4).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;
        final padH = narrow ? 10.0 : 16.0;
        final gap = narrow ? 8.0 : 12.0;
        final gridW = constraints.maxWidth - padH * 2;
        final gridH = constraints.maxHeight * (narrow ? 0.52 : 0.48);
        final pictureSide = math
            .min((gridW - gap) / 2, (gridH - gap) / 2)
            .clamp(narrow ? 76.0 : 88.0, narrow ? 112.0 : 138.0);

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
                Padding(
                  padding: EdgeInsets.fromLTRB(padH, narrow ? 10 : 14, padH, 8),
                  child: Column(
                    children: [
                      _WordHeroCard(
                        word: word,
                        hint: widget.question.prompt,
                        compact: narrow,
                        onSpeak: widget.onSpeakWord,
                      ),
                      SizedBox(height: narrow ? 8 : 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var row = 0; row < 2; row++) ...[
                                if (row > 0) SizedBox(height: gap),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var col = 0; col < 2; col++) ...[
                                      if (col > 0) SizedBox(width: gap),
                                      if (row * 2 + col < options.length)
                                        _buildPictureTile(
                                          options[row * 2 + col],
                                          row * 2 + col,
                                          pictureSide,
                                        ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!narrow)
                  const Positioned(
                    right: 6,
                    bottom: 6,
                    child: MonsterCharacter(
                      size: 48,
                      imagePath: TeacherAssets.guruthumiya,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPictureTile(TaskOption option, int index, double size) {
    final selected = widget.selectedId == option.id;
    final result = selected ? widget.showResult : null;
    final idle = widget.selectedId == null;

    return _PictureChoiceCard(
      visual: option.visual,
      size: size,
      borderColor: _borderColors[index % _borderColors.length],
      selected: selected,
      showResult: result,
      pulse: idle,
      onTap: () => widget.onPick(option.id),
    );
  }
}

class _WordHeroCard extends StatelessWidget {
  const _WordHeroCard({
    required this.word,
    required this.hint,
    required this.onSpeak,
    this.compact = false,
  });

  final String word;
  final String hint;
  final Future<void> Function() onSpeak;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final speakSize = compact ? 40.0 : 48.0;
    final wordSize = compact ? 36.0 : 48.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkSlateLight,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.mint.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                color: AppColors.orange,
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  onTap: onSpeak,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: speakSize,
                    height: speakSize,
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: Colors.white,
                      size: compact ? 22 : 26,
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 10 : 14),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    word,
                    style: GoogleFonts.fredoka(
                      fontSize: wordSize,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 4 : 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _PictureChoiceCard extends StatefulWidget {
  const _PictureChoiceCard({
    required this.visual,
    required this.size,
    required this.borderColor,
    required this.onTap,
    this.selected = false,
    this.showResult,
    this.pulse = false,
  });

  final String visual;
  final double size;
  final Color borderColor;
  final VoidCallback onTap;
  final bool selected;
  final bool? showResult;
  final bool pulse;

  @override
  State<_PictureChoiceCard> createState() => _PictureChoiceCardState();
}

class _PictureChoiceCardState extends State<_PictureChoiceCard>
    with TickerProviderStateMixin {
  late AnimationController _bounce;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0.96,
      upperBound: 1.04,
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.pulse && widget.showResult == null) {
      _bounce.repeat(reverse: true);
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PictureChoiceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final animating = widget.pulse && widget.showResult == null;
    if (animating && !_bounce.isAnimating) {
      _bounce.repeat(reverse: true);
      _pulse.repeat(reverse: true);
    } else if (!animating) {
      _bounce.stop();
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color border = widget.borderColor.withValues(alpha: 0.45);
    if (widget.showResult == true) border = AppColors.mint;
    if (widget.showResult == false && widget.selected) border = AppColors.orange;
    if (widget.selected && widget.showResult == null) border = AppColors.gold;

    return GestureDetector(
      onTap: widget.showResult == null ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bounce, _pulse]),
        builder: (_, __) {
          final scale = widget.pulse && widget.showResult == null
              ? 1.0 + _pulse.value * 0.04
              : _bounce.value;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: widget.pulse ? 3 : 2.5),
                boxShadow: [
                  BoxShadow(
                    color: border.withValues(alpha: widget.pulse ? 0.35 : 0.15),
                    blurRadius: widget.pulse ? 14 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  KidArt(visual: widget.visual),
                  if (widget.showResult == true)
                    Container(
                      color: AppColors.mint.withValues(alpha: 0.15),
                      child: const Center(
                        child: Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 36),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

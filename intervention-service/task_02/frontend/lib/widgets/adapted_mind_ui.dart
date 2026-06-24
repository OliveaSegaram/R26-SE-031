import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'kid_art.dart';

/// Navy splash background — matches sign-in / assessment flow.
class AmBackground extends StatelessWidget {
  const AmBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.splashGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _blob(200, AppColors.mint.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: _blob(240, AppColors.orange.withValues(alpha: 0.06)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class AmBookCard extends StatefulWidget {
  const AmBookCard({
    super.key,
    required this.visual,
    required this.onTap,
    this.label,
    this.showLabel = true,
    this.selected = false,
    this.showResult,
    this.letter,
    this.height = 200,
    this.bounce = true,
  });

  final String visual;
  final String? label;
  final String? letter;
  final VoidCallback onTap;
  final bool showLabel;
  final bool selected;
  final bool? showResult;
  final double height;
  final bool bounce;

  @override
  State<AmBookCard> createState() => _AmBookCardState();
}

class _AmBookCardState extends State<AmBookCard> with SingleTickerProviderStateMixin {
  late AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: .96,
      upperBound: 1.04,
    );
    if (widget.bounce) _bounce.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color border = AppColors.mint.withValues(alpha: 0.25);
    if (widget.showResult == true) border = AppColors.mint;
    if (widget.showResult == false && widget.selected) border = AppColors.orange;
    if (widget.selected && widget.showResult == null) border = AppColors.gold;

    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) => Transform.scale(
        scale: widget.bounce && widget.showResult == null ? _bounce.value : 1,
        child: child,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.showResult == null ? widget.onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: widget.height.isFinite ? widget.height : null,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.darkSlateLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.showLabel && widget.label != null
                  ? Column(
                      children: [
                        Expanded(child: KidArt(visual: widget.visual, letter: widget.letter)),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: AppColors.primary,
                          child: Text(
                            widget.label!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      ],
                    )
                  : KidArt(visual: widget.visual, letter: widget.letter),
            ),
          ),
        ),
      ),
    );
  }
}

class AmPicturePanel extends StatelessWidget {
  const AmPicturePanel({
    super.key,
    required this.visual,
    this.onTap,
    this.size = 260,
  });

  final String visual;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: AmBookCard(
          visual: visual,
          showLabel: false,
          height: size,
          bounce: false,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }
}

class AmSpeakerBtn extends StatelessWidget {
  const AmSpeakerBtn({super.key, required this.onTap, this.size = 52});
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.orange,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: AppColors.orange.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class AmWordHero extends StatelessWidget {
  const AmWordHero({
    super.key,
    required this.word,
    required this.hint,
    required this.onSpeak,
  });

  final String word;
  final String hint;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkSlateLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AmSpeakerBtn(onTap: onSpeak, size: 52),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  word,
                  style: GoogleFonts.fredoka(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class AmProgressBar extends StatelessWidget {
  const AmProgressBar({
    super.key,
    required this.answered,
    required this.total,
    required this.coins,
    this.level = 2,
    this.onBack,
  });

  final int answered;
  final int total;
  final int coins;
  final int level;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (answered / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          if (onBack != null) _backBtn(onBack!),
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _levelColor(level),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'මට්ටම $level',
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.textLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 12,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.mint.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.darkSlateLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backBtn(VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.textLight.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.textLight.withValues(alpha: 0.08)),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: AppColors.textLight, size: 22),
        ),
      ),
    );
  }

  Color _levelColor(int level) {
    return switch (level) {
      1 => AppColors.mintDark,
      3 => AppColors.orange,
      _ => AppColors.primaryLight,
    };
  }
}

class AmWordChoice extends StatelessWidget {
  const AmWordChoice({
    super.key,
    required this.label,
    required this.onTap,
    required this.onSpeak,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onSpeak;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? AppColors.mint.withValues(alpha: 0.15) : AppColors.darkSlateLight,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.mint : AppColors.textLight.withValues(alpha: 0.1),
                width: 2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.mint.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AmSpeakerBtn(onTap: onSpeak, size: 44),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.fredoka(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.mint : AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

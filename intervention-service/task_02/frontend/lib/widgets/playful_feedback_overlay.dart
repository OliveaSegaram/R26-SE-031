import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'monster_character.dart';

/// How long the overlay stays visible (keep in sync with [task_flow_screen]).
const kFeedbackDisplayMs = 2400;

/// Center-screen playful feedback — mascot jump + stars + confetti (success),
/// or gentle mascot + hearts (try again).
class PlayfulFeedbackOverlay extends StatefulWidget {
  const PlayfulFeedbackOverlay({
    super.key,
    required this.correct,
    this.message,
  });

  final bool correct;
  final String? message;

  @override
  State<PlayfulFeedbackOverlay> createState() => _PlayfulFeedbackOverlayState();
}

class _PlayfulFeedbackOverlayState extends State<PlayfulFeedbackOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pop;
  late AnimationController _burst;
  late AnimationController _bounce;
  late Animation<double> _popScale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );

    _popScale = CurvedAnimation(parent: _pop, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _pop, curve: Curves.easeOut);

    _pop.forward();
    _burst.forward();
    _bounce.repeat(reverse: true);
    Future<void>.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) _bounce.stop();
    });
  }

  @override
  void dispose() {
    _pop.dispose();
    _burst.dispose();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.correct ? AppColors.mint : AppColors.orange;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_pop, _burst, _bounce]),
        builder: (context, _) {
          return Container(
            color: AppColors.darkSlate.withValues(alpha: 0.42 * _fade.value),
            child: Center(
              child: Transform.scale(
                scale: _popScale.value,
                child: Opacity(
                  opacity: _fade.value,
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (widget.correct)
                          _ConfettiShower(progress: _burst.value),
                        _PulseRing(
                          progress: _burst.value,
                          color: accent,
                        ),
                        _CenterStarBurst(
                          progress: _burst.value,
                          correct: widget.correct,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.correct)
                              _CelebrationMascot(progress: _bounce.value)
                            else
                              _EncourageMascot(progress: _bounce.value),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.5),
                                    blurRadius: 18,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.correct ? 'නියමයි!' : 'ආයෙ උත්සාහ කරමු!',
                                style: GoogleFonts.fredoka(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Quiz master jumps with orbiting sparkle emojis.
class _CelebrationMascot extends StatelessWidget {
  const _CelebrationMascot({required this.progress});

  final double progress;

  static const _sparkles = ['⭐', '✨', '🎉'];

  @override
  Widget build(BuildContext context) {
    final jump = math.sin(progress * math.pi) * 22;
    final scale = 1.0 + math.sin(progress * math.pi) * 0.1;
    final wiggle = math.sin(progress * math.pi * 2) * 0.06;

    return SizedBox(
      width: 160,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ...List.generate(_sparkles.length, (i) {
            final angle = progress * math.pi * 2 + i * (math.pi * 2 / 3);
            final radius = 52 + math.sin(progress * math.pi) * 8;
            return Positioned(
              left: 80 + math.cos(angle) * radius - 14,
              top: 52 + math.sin(angle) * radius - 14,
              child: Transform.rotate(
                angle: angle,
                child: Text(
                  _sparkles[i],
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            );
          }),
          Transform.translate(
            offset: Offset(0, -jump),
            child: Transform.rotate(
              angle: wiggle,
              child: Transform.scale(
                scale: scale,
                child: const MonsterCharacter(
                  size: 96,
                  imagePath: 'assets/characters/quiz_master.png',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EncourageMascot extends StatelessWidget {
  const _EncourageMascot({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final bob = math.sin(progress * math.pi) * 12;
    final scale = 0.94 + math.sin(progress * math.pi) * 0.06;

    return Transform.translate(
      offset: Offset(0, -bob),
      child: Transform.scale(
        scale: scale,
        child: const MonsterCharacter(
          size: 92,
          imagePath: 'assets/characters/solo_pink.png',
        ),
      ),
    );
  }
}

/// Expanding ring from the center.
class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = 60.0 + progress * 200;
    final opacity = (1 - progress).clamp(0.0, 1.0) * 0.55;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: opacity), width: 3),
        ),
      ),
    );
  }
}

/// Tiny confetti squares drifting down (success only).
class _ConfettiShower extends StatelessWidget {
  const _ConfettiShower({required this.progress});

  final double progress;

  static final _pieces = List.generate(18, (i) {
    final r = math.Random(i * 17);
    return _ConfettiPiece(
      x: r.nextDouble() * 280 - 140,
      delay: r.nextDouble() * 0.35,
      speed: 0.65 + r.nextDouble() * 0.5,
      size: 6 + r.nextDouble() * 6,
      color: [
        AppColors.gold,
        AppColors.mint,
        AppColors.orange,
        AppColors.mintLight,
        Colors.white,
      ][i % 5],
      rotation: r.nextDouble() * math.pi,
    );
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: _pieces.map((p) {
          final t = ((progress - p.delay) / p.speed).clamp(0.0, 1.0);
          final y = -120 + t * 260;
          final opacity = t < 0.1 ? t / 0.1 : (1 - t).clamp(0.0, 1.0);

          return Positioned(
            left: 150 + p.x,
            top: 150 + y,
            child: Opacity(
              opacity: opacity,
              child: Transform.rotate(
                angle: p.rotation + t * math.pi * 3,
                child: Container(
                  width: p.size,
                  height: p.size * 0.65,
                  decoration: BoxDecoration(
                    color: p.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
  });

  final double x;
  final double delay;
  final double speed;
  final double size;
  final Color color;
  final double rotation;
}

class _CenterStarBurst extends StatelessWidget {
  const _CenterStarBurst({
    required this.progress,
    required this.correct,
  });

  final double progress;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final count = correct ? 14 : 7;
    final maxDist = correct ? 140.0 : 95.0;
    final colors = correct
        ? [AppColors.gold, AppColors.mintLight, AppColors.orangeLight, Colors.white]
        : [AppColors.orangeLight, AppColors.gold];

    return SizedBox(
      width: maxDist * 2 + 40,
      height: maxDist * 2 + 40,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: List.generate(count, (i) {
          final angle = (i / count) * math.pi * 2 - math.pi / 2;
          final stagger = (i / count) * 0.1;
          final t = ((progress - stagger) / (1 - stagger)).clamp(0.0, 1.0);
          final dist = Curves.easeOut.transform(t) * maxDist;
          final scale = t < 0.12 ? t / 0.12 : 1.0 - (t - 0.12) * 0.3;
          final opacity = (1 - t * 0.88).clamp(0.0, 1.0);

          return Transform.translate(
            offset: Offset(math.cos(angle) * dist, math.sin(angle) * dist),
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Icon(
                  correct ? Icons.star_rounded : Icons.favorite_rounded,
                  size: 16 + (i % 4) * 5,
                  color: colors[i % colors.length],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

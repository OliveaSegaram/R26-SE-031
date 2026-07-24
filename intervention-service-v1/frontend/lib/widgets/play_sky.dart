import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/play_theme.dart';

class PlaySky extends StatelessWidget {
  const PlaySky({super.key, required this.child, this.variant = SkyVariant.day});

  final Widget child;
  final SkyVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = switch (variant) {
      SkyVariant.day => const [
          PlayTheme.skyTop,
          PlayTheme.skyMid,
          PlayTheme.skyBot,
        ],
      SkyVariant.ice => const [
          Color(0xFF89CFF0),
          PlayTheme.ice,
          Color(0xFFE8F8FF),
        ],
      SkyVariant.party => const [
          Color(0xFFFF9A9E),
          Color(0xFFFECFEF),
          PlayTheme.sun,
        ],
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _FloatingShapes(),
          child,
        ],
      ),
    );
  }
}

enum SkyVariant { day, ice, party }

class _FloatingShapes extends StatefulWidget {
  const _FloatingShapes();

  @override
  State<_FloatingShapes> createState() => _FloatingShapesState();
}

class _FloatingShapesState extends State<_FloatingShapes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return CustomPaint(
          painter: _ShapePainter(t),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    for (var i = 0; i < 10; i++) {
      final x = rnd.nextDouble() * size.width;
      final baseY = rnd.nextDouble() * size.height;
      final y = (baseY + sin((t * 2 * pi) + i) * 18) % size.height;
      final s = 10.0 + rnd.nextDouble() * 28;
      final paint = Paint()
        ..color = [
          Colors.white.withValues(alpha: 0.35),
          PlayTheme.grape.withValues(alpha: 0.18),
          PlayTheme.coral.withValues(alpha: 0.16),
          PlayTheme.leaf.withValues(alpha: 0.16),
        ][i % 4];
      if (i % 3 == 0) {
        canvas.drawCircle(Offset(x, y), s / 2, paint);
      } else if (i % 3 == 1) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: s, height: s),
            const Radius.circular(8),
          ),
          paint,
        );
      } else {
        final path = Path()
          ..moveTo(x, y - s / 2)
          ..lineTo(x + s / 2, y + s / 2)
          ..lineTo(x - s / 2, y + s / 2)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) =>
      oldDelegate.t != t;
}

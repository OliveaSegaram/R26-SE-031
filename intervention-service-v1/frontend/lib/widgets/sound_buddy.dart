import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/play_theme.dart';

enum BuddyMood { hello, listen, think, yay, sleep }

/// Abstract "sound buddy" — glowing orb with headphones. NOT the owl.
class SoundBuddy extends StatefulWidget {
  const SoundBuddy({
    super.key,
    this.mood = BuddyMood.hello,
    this.size = 120,
    this.line,
  });

  final BuddyMood mood;
  final double size;
  final String? line;

  @override
  State<SoundBuddy> createState() => _SoundBuddyState();
}

class _SoundBuddyState extends State<SoundBuddy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.mood == BuddyMood.yay ? 500 : 1600,
      ),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant SoundBuddy oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _c.duration = Duration(
        milliseconds: widget.mood == BuddyMood.yay ? 500 : 1600,
      );
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Color get _fill {
    switch (widget.mood) {
      case BuddyMood.listen:
        return PlayTheme.grape;
      case BuddyMood.think:
        return const Color(0xFF5DADE2);
      case BuddyMood.yay:
        return PlayTheme.coral;
      case BuddyMood.sleep:
        return const Color(0xFF95A5A6);
      case BuddyMood.hello:
        return PlayTheme.sun;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.line != null && widget.line!.isNotEmpty) ...[
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: PlayTheme.foam,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: PlayTheme.ink.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              widget.line!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: PlayTheme.ink,
                    fontSize: 16,
                  ),
            ),
          ),
        ],
        AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            final bounce = sin(_c.value * pi) *
                (widget.mood == BuddyMood.yay ? 10 : 5);
            final scale = widget.mood == BuddyMood.listen
                ? 1 + (_c.value * 0.06)
                : 1.0;
            return Transform.translate(
              offset: Offset(0, -bounce),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _BuddyPainter(color: _fill, mood: widget.mood),
            ),
          ),
        ),
      ],
    );
  }
}

class _BuddyPainter extends CustomPainter {
  _BuddyPainter({required this.color, required this.mood});
  final Color color;
  final BuddyMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // glow
    canvas.drawCircle(
      Offset(cx, cy),
      r * 1.25,
      Paint()..color = color.withValues(alpha: 0.25),
    );

    // body
    final body = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.95), color],
        center: const Alignment(-0.3, -0.4),
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, body);

    // headphones band
    final hp = Paint()
      ..color = PlayTheme.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy - r * 0.15), radius: r * 0.95),
      pi * 1.15,
      pi * 0.7,
      false,
      hp,
    );
    // ear cups
    final cup = Paint()..color = PlayTheme.ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - r * 0.95, cy),
          width: size.width * 0.14,
          height: size.width * 0.22,
        ),
        const Radius.circular(8),
      ),
      cup,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + r * 0.95, cy),
          width: size.width * 0.14,
          height: size.width * 0.22,
        ),
        const Radius.circular(8),
      ),
      cup,
    );

    // eyes
    final eyeY = cy - r * 0.1;
    final eyePaint = Paint()..color = PlayTheme.ink;
    if (mood == BuddyMood.sleep) {
      final lid = Paint()
        ..color = PlayTheme.ink
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
          Offset(cx - r * 0.35, eyeY), Offset(cx - r * 0.15, eyeY), lid);
      canvas.drawLine(
          Offset(cx + r * 0.15, eyeY), Offset(cx + r * 0.35, eyeY), lid);
    } else {
      canvas.drawCircle(Offset(cx - r * 0.28, eyeY), r * 0.12, eyePaint);
      canvas.drawCircle(Offset(cx + r * 0.28, eyeY), r * 0.12, eyePaint);
      final shine = Paint()..color = Colors.white;
      canvas.drawCircle(
          Offset(cx - r * 0.32, eyeY - r * 0.05), r * 0.04, shine);
      canvas.drawCircle(
          Offset(cx + r * 0.24, eyeY - r * 0.05), r * 0.04, shine);
    }

    // smile / mouth
    final mouth = Paint()
      ..color = PlayTheme.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    if (mood == BuddyMood.yay) {
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx, cy + r * 0.25), width: r * 0.7, height: r * 0.5),
        0.15,
        pi - 0.3,
        false,
        mouth,
      );
    } else if (mood == BuddyMood.think) {
      canvas.drawLine(
        Offset(cx - r * 0.15, cy + r * 0.28),
        Offset(cx + r * 0.15, cy + r * 0.28),
        mouth,
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx, cy + r * 0.18), width: r * 0.55, height: r * 0.35),
        0.2,
        pi - 0.4,
        false,
        mouth,
      );
    }

    // sound rings when listening
    if (mood == BuddyMood.listen) {
      final ring = Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(cx, cy), r * 1.35, ring);
      canvas.drawCircle(Offset(cx, cy), r * 1.55, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _BuddyPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.mood != mood;
}

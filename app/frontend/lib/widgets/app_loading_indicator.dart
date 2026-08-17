import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({super.key});

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 2-second loop for a calm, professional rotation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 80,
        height: 80,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(80, 80),
              painter: _AdvancedCirclePainter(progress: _controller.value),
            );
          },
        ),
      ),
    );
  }
}

class _AdvancedCirclePainter extends CustomPainter {
  final double progress;

  _AdvancedCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // A static, beautiful sweep gradient using the app's brand colors.
    // Because it's static, the arc changes color as it travels around the circle!
    final gradient = SweepGradient(
      colors: const [
        AppColors.calmBlue,
        AppColors.gentleGreen,
        AppColors.warmAmber,
        AppColors.calmBlue, // Loop back to start
      ],
      stops: const [0.0, 0.33, 0.66, 1.0],
    );

    // Advanced Animation 1: The stroke width breathes (gets thicker and thinner)
    // Using a sine wave that completes 2 cycles per rotation
    final strokeWidth = 5.0 + math.sin(progress * 4 * math.pi) * 2.0;

    // Advanced Animation 2: The arc travels around the circle
    // The start angle rotates steadily
    final double startAngle = progress * 2 * math.pi;
    
    // Advanced Animation 3: The arc expands and contracts like a caterpillar
    // Base sweep is half a circle (pi), and it grows/shrinks by a quarter circle
    final double sweepAngle = math.pi + math.sin(progress * 2 * math.pi) * (math.pi / 2);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Draw the glowing shadow (The premium touch)
    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6); // Soft glowing blur
      
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // 2. Draw the crisp inner arc
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _AdvancedCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

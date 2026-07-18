import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Decorative floating shapes for backgrounds.
/// Not used in the current minimalistic design, but kept as a utility.
class FloatingShapes extends StatefulWidget {
  final int count;
  final List<Color>? colors;

  const FloatingShapes({
    super.key,
    this.count = 15,
    this.colors,
  });

  @override
  State<FloatingShapes> createState() => _FloatingShapesState();
}

class _FloatingShapesState extends State<FloatingShapes>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ShapeData> _shapes;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    final random = Random();
    final colors = widget.colors ??
        [
          AppColors.gold.withValues(alpha: 0.3),
          AppColors.orange.withValues(alpha: 0.25),
          AppColors.orangeLight.withValues(alpha: 0.2),
          AppColors.mint.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.15),
        ];

    _shapes = List.generate(widget.count, (i) {
      return _ShapeData(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 4 + random.nextDouble() * 12,
        speed: 0.3 + random.nextDouble() * 0.7,
        phase: random.nextDouble() * 2 * pi,
        color: colors[random.nextInt(colors.length)],
        shape: _ShapeType.values[random.nextInt(_ShapeType.values.length)],
        rotationSpeed: (random.nextDouble() - 0.5) * 2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _FloatingShapesPainter(
            shapes: _shapes,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

enum _ShapeType { circle, star, diamond, dot }

class _ShapeData {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;
  final Color color;
  final _ShapeType shape;
  final double rotationSpeed;

  _ShapeData({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.color,
    required this.shape,
    required this.rotationSpeed,
  });
}

class _FloatingShapesPainter extends CustomPainter {
  final List<_ShapeData> shapes;
  final double progress;

  _FloatingShapesPainter({required this.shapes, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final shape in shapes) {
      final time = progress * 2 * pi;
      final dx = shape.x * size.width +
          sin(time * shape.speed + shape.phase) * 15;
      final dy = shape.y * size.height +
          cos(time * shape.speed * 0.7 + shape.phase) * 20;

      final paint = Paint()
        ..color = shape.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(time * shape.rotationSpeed * 0.3);

      switch (shape.shape) {
        case _ShapeType.circle:
          canvas.drawCircle(Offset.zero, shape.size, paint);
          break;
        case _ShapeType.star:
          _drawStar(canvas, shape.size, paint);
          break;
        case _ShapeType.diamond:
          _drawDiamond(canvas, shape.size, paint);
          break;
        case _ShapeType.dot:
          canvas.drawCircle(Offset.zero, shape.size * 0.4, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * pi / 180;
      final outerX = cos(outerAngle) * size;
      final outerY = sin(outerAngle) * size;
      final innerX = cos(innerAngle) * size * 0.4;
      final innerY = sin(innerAngle) * size * 0.4;

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, double size, Paint paint) {
    final path = Path()
      ..moveTo(0, -size)
      ..lineTo(size * 0.6, 0)
      ..lineTo(0, size)
      ..lineTo(-size * 0.6, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FloatingShapesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

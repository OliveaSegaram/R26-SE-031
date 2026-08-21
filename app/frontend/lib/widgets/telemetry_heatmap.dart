import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';

class HeatmapVisualizer extends StatelessWidget {
  final List<TouchPoint> touchPoints;
  final String title;
  final String subtitle;

  const HeatmapVisualizer({
    super.key,
    required this.touchPoints,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.calmBlue.withValues(alpha: 0.05),
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.heading(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: AppTypography.caption(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          
          // Heatmap Canvas
          AspectRatio(
            aspectRatio: 16 / 9, // Standard tablet landscape ratio
            child: Container(
              color: const Color(0xFFF0F4F8), // Soft background for the mock activity
              child: CustomPaint(
                painter: _HeatmapPainter(touchPoints: touchPoints),
              ),
            ),
          ),
          
          // Footer Legend
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.blue.withValues(alpha: 0.5), 'Low Density'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.yellow.withValues(alpha: 0.7), 'Medium Density'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red.withValues(alpha: 0.8), 'High Density'),
                const Spacer(),
                Text(
                  '${touchPoints.length} total taps',
                  style: AppTypography.caption(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.caption(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<TouchPoint> touchPoints;

  _HeatmapPainter({required this.touchPoints});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Placeholder Activity Background
    _drawPlaceholderBackground(canvas, size);

    // 2. Draw Heatmap overlay
    if (touchPoints.isEmpty) return;

    // We draw the points in layers. A simple heatmap effect can be achieved 
    // by drawing semi-transparent blurred circles. Where they overlap, the opacity increases.
    // To make it look like a real thermal heatmap, we can use a BlendMode or just simple opacity layering.
    
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
      ..style = PaintingStyle.fill;

    for (var point in touchPoints) {
      final dx = point.xRatio * size.width;
      final dy = point.yRatio * size.height;
      final center = Offset(dx, dy);

      // We draw 3 concentric circles for each point to simulate heat gradient
      
      // Core (Hottest - Red)
      paint.color = Colors.red.withValues(alpha: 0.2);
      canvas.drawCircle(center, 10, paint);

      // Mid (Warm - Yellow)
      paint.color = Colors.yellow.withValues(alpha: 0.1);
      canvas.drawCircle(center, 25, paint);

      // Outer (Cool - Blue)
      paint.color = Colors.blue.withValues(alpha: 0.05);
      canvas.drawCircle(center, 45, paint);
    }
  }

  void _drawPlaceholderBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    final borderPaint = Paint()
      ..color = AppColors.borderLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw a top banner placeholder (Instruction area)
    final bannerRect = Rect.fromLTWH(20, 10, size.width - 40, size.height * 0.15);
    canvas.drawRRect(RRect.fromRectAndRadius(bannerRect, const Radius.circular(8)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bannerRect, const Radius.circular(8)), borderPaint);

    // Draw 4 interaction target boxes in the center
    final double boxWidth = size.width * 0.25;
    final double boxHeight = size.height * 0.4;
    final double spacingX = (size.width - (boxWidth * 2)) / 3;
    final double spacingY = (size.height * 0.85 - (boxHeight * 2)) / 3;

    final double startY = size.height * 0.15 + 10 + spacingY;

    // Top Left
    final tlRect = Rect.fromLTWH(spacingX, startY, boxWidth, boxHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(tlRect, const Radius.circular(16)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(tlRect, const Radius.circular(16)), borderPaint);

    // Top Right
    final trRect = Rect.fromLTWH(spacingX * 2 + boxWidth, startY, boxWidth, boxHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(trRect, const Radius.circular(16)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(trRect, const Radius.circular(16)), borderPaint);

    // Bottom Left
    final blRect = Rect.fromLTWH(spacingX, startY + boxHeight + spacingY, boxWidth, boxHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(blRect, const Radius.circular(16)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(blRect, const Radius.circular(16)), borderPaint);

    // Bottom Right
    final brRect = Rect.fromLTWH(spacingX * 2 + boxWidth, startY + boxHeight + spacingY, boxWidth, boxHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(brRect, const Radius.circular(16)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(brRect, const Radius.circular(16)), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.touchPoints != touchPoints;
  }
}

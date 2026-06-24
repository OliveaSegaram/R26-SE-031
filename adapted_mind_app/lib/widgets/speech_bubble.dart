import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Animated speech bubble with typewriter text effect.
/// Pops in with a scale animation, then types out text character by character.
class SpeechBubble extends StatefulWidget {
  final String text;
  final double maxWidth;
  final Duration delay;

  const SpeechBubble({
    super.key,
    required this.text,
    this.maxWidth = 280,
    this.delay = const Duration(milliseconds: 400),
  });

  @override
  State<SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<SpeechBubble>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _typeController;
  late Animation<double> _scaleAnimation;

  // Break text into grapheme clusters to safely handle all characters
  late List<String> _characters;

  @override
  void initState() {
    super.initState();

    _characters = widget.text.characters.toList();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _typeController = AnimationController(
      duration: Duration(milliseconds: _characters.length * 45),
      vsync: this,
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _scaleController.forward().then((_) {
          if (mounted) _typeController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.darkSlate.withValues(alpha: 0.6), // Translucent dark background instead of white
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.8), // Highlight border
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.15), // Neon glow
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typeController,
              builder: (context, child) {
                final charCount =
                    (_typeController.value * _characters.length).round();
                final displayText = _characters.take(charCount).join();
                return Text(
                  displayText,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight, // Bright text instead of dark text
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
          // Triangle tail pointing down
          CustomPaint(
            size: const Size(24, 14),
            painter: _BubbleTailPainter(),
          ),
        ],
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../skill_1/widgets/pattern_background.dart';

class SharedGameLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final int currentRoundIndex;
  final int totalRounds;
  final bool isRoundComplete;
  final bool isActivityComplete;
  final VoidCallback onNext;

  const SharedGameLayout({
    Key? key,
    required this.child,
    required this.title,
    required this.currentRoundIndex,
    required this.totalRounds,
    required this.isRoundComplete,
    required this.isActivityComplete,
    required this.onNext,
  }) : super(key: key);

  @override
  State<SharedGameLayout> createState() => _SharedGameLayoutState();
}

class _SharedGameLayoutState extends State<SharedGameLayout> with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScale;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _celebrationScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(SharedGameLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActivityComplete && !oldWidget.isActivityComplete) {
      _celebrationController.forward();
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Layer
          const Positioned.fill(
            child: PatternBackground(imagePath: 'assets/images/backgrounds/act1_bg.jpg'),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildTopHUD(),
                const SizedBox(height: 8),
                Expanded(child: widget.child),
              ],
            ),
          ),

          // Celebration Overlay
          if (widget.isActivityComplete) _buildCelebrationOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopHUD() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90D9).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Color(0xFF4A90D9), size: 24),
            ),
          ),
          const SizedBox(width: 12),

          // Center: Title & Progress
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Flexible(
                      child: Text(
                        widget.title,
                        style: AppTypography.heading(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3E3E3E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildProgressDots(),
              ],
            ),
          ),

          // Right: Round counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.currentRoundIndex + 1}/${widget.totalRounds > 0 ? widget.totalRounds : 1}',
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A90D9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDots() {
    int total = widget.totalRounds > 0 ? widget.totalRounds : 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total * 2 - 1, (index) {
        if (index % 2 == 1) {
          final lineIndex = index ~/ 2;
          final isCompleted = lineIndex < widget.currentRoundIndex;
          return Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isCompleted
                  ? const Color(0xFF6DBE6D)
                  : const Color(0xFFE0E0E0),
            ),
          );
        } else {
          final dotIndex = index ~/ 2;
          final isCompleted = dotIndex < widget.currentRoundIndex;
          final isCurrent = dotIndex == widget.currentRoundIndex;
          return Container(
            width: isCurrent ? 14 : 10,
            height: isCurrent ? 14 : 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? const Color(0xFF6DBE6D)
                  : isCurrent
                      ? const Color(0xFFF9C623)
                      : const Color(0xFFE0E0E0),
              border: isCurrent
                  ? Border.all(color: const Color(0xFFF9C623).withValues(alpha: 0.3), width: 2)
                  : null,
            ),
          );
        }
      }),
    );
  }

  Widget _buildCelebrationOverlay() {
    return AnimatedBuilder(
      animation: _celebrationScale,
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.4 * _celebrationScale.value),
          child: Center(
            child: Transform.scale(
              scale: _celebrationScale.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90D9).withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStar(36),
                const SizedBox(width: 10),
                _buildStar(52),
                const SizedBox(width: 10),
                _buildStar(36),
              ],
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/characters/mascots/solo_green.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const SizedBox(width: 80, height: 80),
            ),
            const SizedBox(height: 16),
            Text(
              'හොඳයි! 🎉',
              style: AppTypography.sinhala(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3E3E3E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ඔබ සියල්ල අවසන් කළා!',
              style: AppTypography.sinhala(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: widget.onNext,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6DBE6D), Color(0xFF4E9E4E)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6DBE6D).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'ඉදිරියට යමු →',
                  style: AppTypography.sinhala(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStar(double size) {
    return Icon(
      Icons.star_rounded,
      size: size,
      color: const Color(0xFFF9C623),
    );
  }
}

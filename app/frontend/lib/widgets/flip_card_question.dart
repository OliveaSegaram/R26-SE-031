import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

/// Dyslexia-accessible question card with warm white bg, calm blue border.
class FlipCardQuestion extends StatelessWidget {
  final String text;

  const FlipCardQuestion({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.borderBlue,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.calmBlue.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.left,
          style: AppTypography.body(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// A custom transition for AnimatedSwitcher that flips a widget in 3D
class Flip3DTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const Flip3DTransition({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, childWidget) {
        double rotation;

        bool isIncoming = animation.status == AnimationStatus.forward || animation.status == AnimationStatus.completed;
        
        if (animation.value < 0.5) {
          rotation = animation.value * math.pi;
        } else {
          rotation = (animation.value - 1.0) * math.pi;
        }

        bool isVisible = true;
        if (isIncoming && animation.value < 0.5) isVisible = false;
        if (!isIncoming && animation.value >= 0.5) isVisible = false;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(rotation),
          alignment: Alignment.center,
          child: isVisible ? childWidget : const SizedBox.shrink(),
        );
      },
      child: child,
    );
  }
}

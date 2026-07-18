import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

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
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.darkSlateLight,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.mint.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
          // Inner glow
          BoxShadow(
            color: AppColors.mint.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textLight,
            height: 1.3,
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
        // Animation goes from 0.0 to 1.0.
        // We want the outgoing widget to rotate from 0 to pi/2 (disappears)
        // We want the incoming widget to rotate from -pi/2 to 0 (appears)
        
        final isUnder = (ValueKey(animation.status) != childWidget?.key);
        // We use an approximation: if animation is running forward, the incoming child's animation goes 0->1
        // The angle calculation:
        var tilt = ((animation.value - 0.5) * math.pi);
        
        // If it's the widget going out, its animation is reversing from 1.0 to 0.0.
        // If it's the widget coming in, its animation is going from 0.0 to 1.0.
        // But AnimatedSwitcher provides an animation that goes 0.0 -> 1.0 for the INCOMING child.
        // For the OUTGOING child, the animation goes 1.0 -> 0.0.

        // So the angle is:
        double rotation = (1.0 - animation.value) * math.pi; // Goes from pi -> 0
        
        // To make it look like a single card flipping, the outgoing should rotate 0 -> 90deg, 
        // and the incoming should rotate -90deg -> 0.
        
        bool isIncoming = animation.status == AnimationStatus.forward || animation.status == AnimationStatus.completed;
        
        if (animation.value < 0.5) {
          // Outgoing half of the flip
          rotation = animation.value * math.pi; // 0 to pi/2
        } else {
          // Incoming half of the flip
          rotation = (animation.value - 1.0) * math.pi; // -pi/2 to 0
        }

        // We only show the child if it's currently on the visible half of the flip
        bool isVisible = true;
        if (isIncoming && animation.value < 0.5) isVisible = false;
        if (!isIncoming && animation.value >= 0.5) isVisible = false;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002) // Perspective
            ..rotateY(rotation),
          alignment: Alignment.center,
          child: isVisible ? childWidget : const SizedBox.shrink(),
        );
      },
      child: child,
    );
  }
}

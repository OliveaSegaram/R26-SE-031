import 'package:flutter/material.dart';

/// Animated character widget that uses the actual character.png asset.
/// Supports bounce, wave (tilt), excited, peek, and curious animations.
class MonsterCharacter extends StatefulWidget {
  final double size;
  final MonsterAnimation animation;
  final bool showBody; // if false, clips to show only upper portion
  final String imagePath;

  const MonsterCharacter({
    super.key,
    this.size = 200,
    this.animation = MonsterAnimation.idle,
    this.showBody = true,
    this.imagePath = 'assets/images/solo_yellow.png',
  });

  @override
  State<MonsterCharacter> createState() => _MonsterCharacterState();
}

enum MonsterAnimation { none, idle, wave, excited, peek, curious }

class _MonsterCharacterState extends State<MonsterCharacter>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _entranceController;
  late AnimationController _tiltController;

  late Animation<double> _bounceAnimation;
  late Animation<double> _entranceAnimation;
  late Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();

    // Bounce/Float animation
    final bounceDuration = widget.animation == MonsterAnimation.excited
        ? 600
        : 2500; // Slower, elegant floating
    final bounceHeight = widget.animation == MonsterAnimation.excited
        ? -16.0
        : -8.0;

    _bounceController = AnimationController(
      duration: Duration(milliseconds: bounceDuration),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: bounceHeight).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOutSine),
    );
    
    // Always float to feel alive, unless none is specified
    if (widget.animation != MonsterAnimation.none) {
      _bounceController.repeat(reverse: true);
    }

    // Entrance scale animation
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );
    _entranceController.forward();

    // Tilt/breathing animation
    _tiltController = AnimationController(
      duration: const Duration(milliseconds: 3000), // Very slow breathing
      vsync: this,
    );
    _tiltAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeInOutSine),
    );

    if (widget.animation == MonsterAnimation.wave ||
        widget.animation == MonsterAnimation.curious ||
        widget.animation == MonsterAnimation.idle) {
      _tiltController.repeat(reverse: true); 
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _entranceController.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _bounceAnimation,
        _entranceAnimation,
        _tiltAnimation,
      ]),
      builder: (context, child) {
        double rotation = 0;
        if (widget.animation == MonsterAnimation.wave ||
            widget.animation == MonsterAnimation.curious) {
          rotation = _tiltAnimation.value;
        }

        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Transform.scale(
            scale: _entranceAnimation.value,
            child: Transform.rotate(
              angle: rotation,
              child: child,
            ),
          ),
        );
      },
      child: _buildCharacterImage(),
    );
  }

  Widget _buildCharacterImage() {
    final imageWidget = Image.asset(
      widget.imagePath,
      width: widget.size,
      height: widget.showBody ? widget.size : widget.size * 0.65,
      fit: widget.showBody ? BoxFit.contain : BoxFit.cover,
      alignment: widget.showBody ? Alignment.center : Alignment.topCenter,
    );

    if (!widget.showBody) {
      // Clip to show only the top portion (face area)
      return ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 0.65,
          child: Image.asset(
            widget.imagePath,
            width: widget.size,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return imageWidget;
  }
}

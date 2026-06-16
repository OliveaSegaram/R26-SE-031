import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/play_theme.dart';
import 'child_pictogram.dart';

class FlipFlashcard extends StatefulWidget {
  const FlipFlashcard({
    super.key,
    this.visual = 'letter',
    this.letter,
    this.backText,
    this.cardColor,
    this.height = 220,
    this.onFlipped,
    this.tapToFlipHint = true,
  });

  final String visual;
  final String? letter;
  final String? backText;
  final String? cardColor;
  final double height;
  final VoidCallback? onFlipped;
  final bool tapToFlipHint;

  @override
  State<FlipFlashcard> createState() => FlipFlashcardState();
}

class FlipFlashcardState extends State<FlipFlashcard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _showFront = true;
  bool _hasFlipped = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void flip() {
    if (_ctrl.isAnimating) return;
    if (_showFront) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
    setState(() {
      _showFront = !_showFront;
      if (!_hasFlipped) {
        _hasFlipped = true;
        widget.onFlipped?.call();
      }
    });
  }

  bool get hasFlipped => _hasFlipped;

  void resetFlip() {
    _ctrl.reset();
    _showFront = true;
    _hasFlipped = false;
  }

  Color get _accent {
    if (widget.cardColor != null) {
      return Color(int.parse('FF${widget.cardColor!.replaceAll('#', '')}', radix: 16));
    }
    return PlayTheme.purple;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final angle = _ctrl.value * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle >= math.pi / 2
                ? Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _backFace(),
                  )
                : _frontFace(),
          );
        },
      ),
    );
  }

  Widget _frontFace() {
    return _cardShell(
      child: ChildPictogram(
        visual: widget.visual,
        letter: widget.letter,
        cardColor: widget.cardColor,
        height: widget.height,
      ),
    );
  }

  Widget _backFace() {
    return _cardShell(
      child: Container(
        height: widget.height,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8A65), Color(0xFFFFB74D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(PlayTheme.cardRadius),
        ),
        child: Text(
          widget.backText ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PlayTheme.cardRadius + 4),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: .3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          child,
          if (widget.tapToFlipHint && !_hasFlipped)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: PlayTheme.purple,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: PlayTheme.purple.withValues(alpha: .4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text('හරවන්න',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

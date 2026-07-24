import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/reading_theme.dart';

/// Soft cream / mint backdrop for Grade-1 intervention games.
class SoftPlayBg extends StatelessWidget {
  const SoftPlayBg({super.key, required this.child, this.mint = false});

  final Widget child;
  final bool mint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: mint
              ? const [Color(0xFFF1F7F4), Color(0xFFE8F5EF), Color(0xFFFAF8F2)]
              : const [Color(0xFFFAF8F2), Color(0xFFFFF6EA), Color(0xFFFFE8D6)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -28,
            child: _blob(const Color(0xFFE2DFEB), 150),
          ),
          Positioned(
            bottom: 70,
            left: -40,
            child: _blob(const Color(0xFFD8EDE4), 170),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(Color c, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(.55)),
      );
}

class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.current, this.total = 5});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final on = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: on ? 15 : 11,
          height: on ? 15 : 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? const Color(0xFF8C86A8) : const Color(0xFFE2DFEB),
          ),
        );
      }),
    );
  }
}

class StageChip extends StatelessWidget {
  const StageChip({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE2DFEB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF8C86A8),
        ),
      ),
    );
  }
}

class BigPlayOrb extends StatefulWidget {
  const BigPlayOrb({
    super.key,
    required this.onTap,
    this.playing = false,
    this.size = 78,
  });

  final VoidCallback onTap;
  final bool playing;
  final double size;

  @override
  State<BigPlayOrb> createState() => _BigPlayOrbState();
}

class _BigPlayOrbState extends State<BigPlayOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.playing) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant BigPlayOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.playing && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) {
          final glow = widget.playing ? 12 + _pulse.value * 16 : 8.0;
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8C86A8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB8B2D4).withOpacity(.6),
                  blurRadius: glow,
                  spreadRadius: widget.playing ? 3 : 1,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Icon(
          widget.playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
          color: Colors.white,
          size: widget.size * 0.42,
        ),
      ),
    );
  }
}

class GlyphCard extends StatefulWidget {
  const GlyphCard({
    super.key,
    required this.glyph,
    required this.onTap,
    this.selected = false,
  });

  final String glyph;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<GlyphCard> createState() => _GlyphCardState();
}

class _GlyphCardState extends State<GlyphCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 0.94).animate(_press),
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) {
          _press.reverse();
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        onTapCancel: () => _press.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 132,
          height: 142,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: widget.selected
                  ? const Color(0xFF8C86A8)
                  : const Color(0xFFE2DFEB),
              width: widget.selected ? 3.5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C86A8)
                    .withOpacity(widget.selected ? 0.22 : 0.08),
                blurRadius: widget.selected ? 16 : 10,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.glyph,
            style: ReadingKidTheme.chunk.copyWith(fontSize: 52),
          ),
        ),
      ),
    );
  }
}

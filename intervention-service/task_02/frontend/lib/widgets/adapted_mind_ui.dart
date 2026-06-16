import 'package:flutter/material.dart';

import 'kid_art.dart';

/// AdaptedMind-style soft sky background.
class AmBackground extends StatelessWidget {
  const AmBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF64B5F6),
                Color(0xFF42A5F5),
                Color(0xFF1E88E5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(top: -40, left: -30, child: _blob(180, const Color(0x66FFFFFF))),
        Positioned(bottom: 60, right: -50, child: _blob(220, const Color(0x55FFFFFF))),
        Positioned(top: 200, right: 40, child: _blob(100, const Color(0x44B3E5FC))),
        child,
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// Big book-style flashcard like AdaptedMind reading cards.
class AmBookCard extends StatefulWidget {
  const AmBookCard({
    super.key,
    required this.visual,
    required this.onTap,
    this.label,
    this.showLabel = true,
    this.selected = false,
    this.showResult,
    this.letter,
    this.height = 200,
    this.bounce = true,
  });

  final String visual;
  final String? label;
  final String? letter;
  final VoidCallback onTap;
  final bool showLabel;
  final bool selected;
  final bool? showResult;
  final double height;
  final bool bounce;

  @override
  State<AmBookCard> createState() => _AmBookCardState();
}

class _AmBookCardState extends State<AmBookCard> with SingleTickerProviderStateMixin {
  late AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: .96,
      upperBound: 1.04,
    );
    if (widget.bounce) _bounce.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color border = Colors.white;
    if (widget.showResult == true) border = const Color(0xFF00C853);
    if (widget.showResult == false && widget.selected) border = const Color(0xFFFF5252);
    if (widget.selected && widget.showResult == null) border = const Color(0xFFFFD600);

    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) => Transform.scale(
        scale: widget.bounce && widget.showResult == null ? _bounce.value : 1,
        child: child,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.showResult == null ? widget.onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: widget.height.isFinite ? widget.height : null,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .18),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.showLabel && widget.label != null
                  ? Column(
                      children: [
                        Expanded(child: KidArt(visual: widget.visual, letter: widget.letter)),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: Colors.white,
                          child: Text(
                            widget.label!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ],
                    )
                  : KidArt(visual: widget.visual, letter: widget.letter),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square picture panel — keeps drawings from stretching wide.
class AmPicturePanel extends StatelessWidget {
  const AmPicturePanel({
    super.key,
    required this.visual,
    this.onTap,
    this.size = 260,
  });

  final String visual;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: AmBookCard(
          visual: visual,
          showLabel: false,
          height: size,
          bounce: false,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }
}

/// Pink speaker button like AdaptedMind.
class AmSpeakerBtn extends StatelessWidget {
  const AmSpeakerBtn({super.key, required this.onTap, this.size = 52});
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFF4081),
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

/// Huge word display for Grade 1.
class AmWordHero extends StatelessWidget {
  const AmWordHero({
    super.key,
    required this.word,
    required this.hint,
    required this.onSpeak,
  });

  final String word;
  final String hint;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AmSpeakerBtn(onTap: onSpeak, size: 52),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  word,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1565C0),
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF546E7A),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple mascot + progress path (AdaptedMind style).
class AmProgressBar extends StatelessWidget {
  const AmProgressBar({
    super.key,
    required this.answered,
    required this.total,
    required this.coins,
    this.level = 2,
    this.onBack,
  });

  final int answered;
  final int total;
  final int coins;
  final int level;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (onBack != null)
            _roundBtn(Icons.close_rounded, const Color(0xFFFF4081), onBack!),
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _levelColor(level),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'මට්ටම $level',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 36,
              child: CustomPaint(
                painter: _PathPainter(answered: answered, total: total),
                child: Align(
                  alignment: Alignment(-1 + (answered / total.clamp(1, 9)) * 1.8, 0),
                  child: _mascot(),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond_rounded, color: Color(0xFFFF4081), size: 22),
                const SizedBox(width: 4),
                Text('$coins',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundBtn(IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _mascot() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF7E57C2),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: const Icon(Icons.emoji_emotions_rounded, color: Color(0xFFFFEB3B), size: 24),
    );
  }

  Color _levelColor(int level) {
    return switch (level) {
      1 => const Color(0xFF43A047),
      3 => const Color(0xFFE53935),
      _ => const Color(0xFF1565C0),
    };
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({required this.answered, required this.total});
  final int answered;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(8, size.height / 2), Offset(size.width - 8, size.height / 2), paint);
    for (var i = 0; i < total.clamp(0, 9); i++) {
      final x = 8 + (size.width - 16) * i / (total - 1).clamp(1, 8);
      canvas.drawCircle(
        Offset(x, size.height / 2),
        6,
        Paint()..color = i < answered ? const Color(0xFF00C853) : Colors.white.withValues(alpha: .8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) =>
      old.answered != answered || old.total != total;
}

/// Big green next-style word button.
class AmWordChoice extends StatelessWidget {
  const AmWordChoice({
    super.key,
    required this.label,
    required this.onTap,
    required this.onSpeak,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onSpeak;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 6,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? const Color(0xFF00C853) : const Color(0xFFBBDEFB),
                width: 3,
              ),
            ),
            child: Row(
              children: [
                AmSpeakerBtn(onTap: onSpeak, size: 44),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

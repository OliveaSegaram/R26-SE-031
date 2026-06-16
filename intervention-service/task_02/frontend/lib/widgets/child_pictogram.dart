import 'package:flutter/material.dart';

import '../theme/play_theme.dart';

/// Bright, simple pictogram flashcards — clear for Grade 1 (no photos).
class ChildPictogram extends StatelessWidget {
  const ChildPictogram({
    super.key,
    required this.visual,
    this.letter,
    this.cardColor,
    this.height = 160,
    this.compact = false,
  });

  final String visual;
  final String? letter;
  final String? cardColor;
  final double height;
  final bool compact;

  Color get _accent {
    if (cardColor != null) {
      return Color(int.parse('FF${cardColor!.replaceAll('#', '')}', radix: 16));
    }
    return _palette[visual]?.bg ?? PlayTheme.purple;
  }

  static final _palette = <String, _PictoStyle>{
    'letter': _PictoStyle(Color(0xFF7E57C2), Color(0xFFB39DDB), Icons.abc_rounded),
    'moon': _PictoStyle(Color(0xFF5C6BC0), Color(0xFF9FA8DA), Icons.nightlight_round),
    'mosquito': _PictoStyle(Color(0xFF26A69A), Color(0xFF80CBC4), Icons.pest_control),
    'nut': _PictoStyle(Color(0xFF8D6E63), Color(0xFFBCAAA4), Icons.eco_rounded),
    'road': _PictoStyle(Color(0xFF78909C), Color(0xFFB0BEC5), Icons.add_road_rounded),
    'honey': _PictoStyle(Color(0xFFFFB300), Color(0xFFFFE082), Icons.breakfast_dining_rounded),
    'bird': _PictoStyle(Color(0xFF42A5F5), Color(0xFF90CAF9), Icons.flutter_dash_rounded),
    'tree': _PictoStyle(Color(0xFF66BB6A), Color(0xFFA5D6A7), Icons.park_rounded),
    'water': _PictoStyle(Color(0xFF29B6F6), Color(0xFF81D4FA), Icons.water_drop_rounded),
    'river': _PictoStyle(Color(0xFF26C6DA), Color(0xFF80DEEA), Icons.waves_rounded),
    'cat': _PictoStyle(Color(0xFFFF7043), Color(0xFFFFAB91), Icons.pets_rounded),
    'dog': _PictoStyle(Color(0xFFFF8F00), Color(0xFFFFCC80), Icons.pets_rounded),
    'flower': _PictoStyle(Color(0xFFEC407A), Color(0xFFF48FB1), Icons.local_florist_rounded),
    'mother': _PictoStyle(Color(0xFFAB47BC), Color(0xFFCE93D8), Icons.favorite_rounded),
    'father': _PictoStyle(Color(0xFF5C6BC0), Color(0xFF9FA8DA), Icons.man_rounded),
    'girl': _PictoStyle(Color(0xFFFF80AB), Color(0xFFFFB2DD), Icons.face_3_rounded),
    'house': _PictoStyle(Color(0xFFEF5350), Color(0xFFFF8A80), Icons.home_rounded),
    'book': _PictoStyle(Color(0xFF7E57C2), Color(0xFFB39DDB), Icons.menu_book_rounded),
    'school': _PictoStyle(Color(0xFF42A5F5), Color(0xFF90CAF9), Icons.school_rounded),
    'teacher': _PictoStyle(Color(0xFF26A69A), Color(0xFF80CBC4), Icons.person_rounded),
    'sun': _PictoStyle(Color(0xFFFFCA28), Color(0xFFFFEE58), Icons.wb_sunny_rounded),
    'stars': _PictoStyle(Color(0xFF5C6BC0), Color(0xFFC5CAE9), Icons.star_rounded),
    'food': _PictoStyle(Color(0xFFFF8F00), Color(0xFFFFCC80), Icons.rice_bowl_rounded),
    'milk': _PictoStyle(Color(0xFFECEFF1), Color(0xFFFFFFFF), Icons.local_drink_rounded),
    'apple': _PictoStyle(Color(0xFFE53935), Color(0xFFEF9A9A), Icons.emoji_food_beverage_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final style = _palette[visual] ?? _palette['letter']!;
    final bg = cardColor != null ? _accent : style.bg;
    final light = cardColor != null ? _accent.withValues(alpha: .5) : style.light;
    final iconSize = compact ? height * 0.38 : height * 0.42;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PlayTheme.cardRadius),
        gradient: LinearGradient(
          colors: [light, bg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: .35),
            blurRadius: compact ? 8 : 16,
            offset: Offset(0, compact ? 4 : 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.circle,
              size: height * 0.55,
              color: Colors.white.withValues(alpha: .15),
            ),
          ),
          Positioned(
            left: -10,
            bottom: -10,
            child: Icon(
              Icons.circle,
              size: height * 0.35,
              color: Colors.white.withValues(alpha: .12),
            ),
          ),
          if (visual == 'letter' && letter != null)
            Text(
              letter!,
              style: TextStyle(
                fontSize: height * 0.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
            )
          else
            Icon(
              style.icon,
              size: iconSize,
              color: Colors.white,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
        ],
      ),
    );
  }
}

class _PictoStyle {
  const _PictoStyle(this.bg, this.light, this.icon);
  final Color bg;
  final Color light;
  final IconData icon;
}

/// Tappable pictogram option card for match games.
class PictogramPickCard extends StatefulWidget {
  const PictogramPickCard({
    super.key,
    required this.visual,
    required this.label,
    required this.onTap,
    this.letter,
    this.cardColor,
    this.selected = false,
    this.showResult,
  });

  final String visual;
  final String label;
  final VoidCallback onTap;
  final String? letter;
  final String? cardColor;
  final bool selected;
  final bool? showResult;

  @override
  State<PictogramPickCard> createState() => _PictogramPickCardState();
}

class _PictogramPickCardState extends State<PictogramPickCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0.97,
      upperBound: 1.03,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color border = PlayTheme.purple.withValues(alpha: .25);
    if (widget.showResult == true) border = PlayTheme.teal;
    if (widget.showResult == false && widget.selected) border = PlayTheme.coral;
    if (widget.selected && widget.showResult == null) border = PlayTheme.purple;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: widget.showResult == null ? _pulse.value : 1.0,
        child: child,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.showResult == null ? widget.onTap : null,
          borderRadius: BorderRadius.circular(PlayTheme.cardRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(PlayTheme.cardRadius),
              border: Border.all(color: border, width: 3),
              boxShadow: [
                BoxShadow(
                  color: border.withValues(alpha: .2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ChildPictogram(
                    visual: widget.visual,
                    letter: widget.letter,
                    cardColor: widget.cardColor,
                    height: 100,
                    compact: true,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: PlayTheme.navy,
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

/// Playful background with soft bubbles (AdaptedMind feel).
class PlayBackground extends StatelessWidget {
  const PlayBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF3E5F5), Color(0xFFFFF8F0), Color(0xFFE3F2FD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: 40,
          right: -30,
          child: Icon(Icons.circle, size: 120, color: PlayTheme.sun.withValues(alpha: .15)),
        ),
        Positioned(
          bottom: 80,
          left: -40,
          child: Icon(Icons.circle, size: 160, color: PlayTheme.purple.withValues(alpha: .08)),
        ),
        Positioned(
          top: 200,
          left: 30,
          child: Icon(Icons.circle, size: 60, color: PlayTheme.teal.withValues(alpha: .12)),
        ),
        child,
      ],
    );
  }
}

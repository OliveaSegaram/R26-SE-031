import 'package:flutter/material.dart';

/// Bouncing mascot from adapted_mind_app assets.
class MonsterCharacter extends StatefulWidget {
  const MonsterCharacter({
    super.key,
    this.size = 120,
    this.imagePath = 'assets/characters/quiz_master.png',
  });

  final double size;
  final String imagePath;

  @override
  State<MonsterCharacter> createState() => _MonsterCharacterState();
}

class _MonsterCharacterState extends State<MonsterCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, -6 * _float.value),
          child: child,
        );
      },
      child: Image.asset(
        widget.imagePath,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}

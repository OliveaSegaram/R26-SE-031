import 'package:flutter/material.dart';

class PatternCarriage extends StatelessWidget {
  final String? imagePath;
  final Color accentColor;
  final bool isMissing;
  final GlobalKey? carriageKey;
  final Animation<double>? bounceAnimation;

  const PatternCarriage({
    Key? key,
    this.imagePath,
    required this.accentColor,
    this.isMissing = false,
    this.carriageKey,
    this.bounceAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget carriageBody = SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Roof
          Container(
            width: 70,
            height: 10,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
          ),
          // Body
          Container(
            key: carriageKey,
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isMissing ? Colors.white.withOpacity(0.9) : Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              border: Border.all(
                color: isMissing ? Colors.grey.withOpacity(0.5) : accentColor.withOpacity(0.4),
                width: isMissing ? 2 : 1.5,
                style: isMissing ? BorderStyle.solid : BorderStyle.solid,
              ),
              boxShadow: [
                if (!isMissing)
                  BoxShadow(
                    color: accentColor.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: _buildContent(),
          ),
          const SizedBox(height: 4),
          // Wheels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWheel(18),
              _buildWheel(18),
            ],
          ),
        ],
      ),
    );

    if (bounceAnimation != null) {
      return AnimatedBuilder(
        animation: bounceAnimation!,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -10 * bounceAnimation!.value),
            child: child,
          );
        },
        child: carriageBody,
      );
    }

    return carriageBody;
  }

  Widget _buildContent() {
    if (isMissing) {
      if (imagePath == null || imagePath!.isEmpty) {
        return const Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        );
      }
    }
    
    if (imagePath == null || imagePath!.isEmpty) {
      return const SizedBox();
    }

    return Image.asset(
      'assets/images/activity_icons/$imagePath',
      fit: BoxFit.contain,
      errorBuilder: (c, e, s) => const Icon(
        Icons.image_outlined,
        color: Colors.grey,
        size: 32,
      ),
    );
  }

  Widget _buildWheel(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF333333), // dark grey/black
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Container(
          width: size * 0.4,
          height: size * 0.4,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// AdaptedMind-inspired palette: playful purple, teal rewards, sunny accents.
class PlayTheme {
  static const purple = Color(0xFF6C3CE9);
  static const purpleLight = Color(0xFF9B7EF5);
  static const teal = Color(0xFF00BFA5);
  static const tealDark = Color(0xFF00897B);
  static const sun = Color(0xFFFFB300);
  static const coral = Color(0xFFFF6B6B);
  static const sky = Color(0xFF4FC3F7);
  static const navy = Color(0xFF1A237E);
  static const cream = Color(0xFFFFF8F0);
  static const cardWhite = Color(0xFFFFFEFE);

  static const radius = 24.0;
  static const cardRadius = 20.0;

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: purple,
        primary: purple,
        secondary: teal,
        tertiary: sun,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: navy,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF455A64),
        ),
      ),
    );
  }

  static BoxDecoration gamePanel(Color c) => BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.withValues(alpha: .25), width: 2),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: .12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      );

  static LinearGradient heroGradient = const LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

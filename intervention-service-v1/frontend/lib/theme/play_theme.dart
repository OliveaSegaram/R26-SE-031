import 'package:flutter/material.dart';

/// Fresh play-world palette (not the old yellow reading hub).
class PlayTheme {
  static const skyTop = Color(0xFF7EC8E3);
  static const skyMid = Color(0xFFB8E0D2);
  static const skyBot = Color(0xFFFFE5B4);
  static const ink = Color(0xFF1F2A44);
  static const inkSoft = Color(0xFF4A5A78);
  static const coral = Color(0xFFFF6B6B);
  static const sun = Color(0xFFFFC857);
  static const grape = Color(0xFF7B6CF6);
  static const leaf = Color(0xFF3DDC97);
  static const foam = Color(0xFFFFFFF5);
  static const ice = Color(0xFFA8E6FF);

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: skyMid,
      colorScheme: ColorScheme.fromSeed(
        seedColor: grape,
        brightness: Brightness.light,
        primary: grape,
        secondary: coral,
        surface: foam,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: ink,
          letterSpacing: 0.5,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: inkSoft,
          height: 1.35,
        ),
      ),
    );
  }

  static const glyph = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w800,
    color: ink,
    height: 1.05,
  );
}

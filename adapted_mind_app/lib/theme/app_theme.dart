import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Navy Blue + Orange + Mint Green color palette.
/// Energetic and kid-friendly — designed for a Sinhala learning app.
class AppColors {
  // Primary — Navy Blue
  static const Color primary = Color(0xFF1B3A5C); // Deep navy
  static const Color primaryLight = Color(0xFF2E5A8A); // Medium navy
  static const Color primaryDark = Color(0xFF0F2440); // Darkest navy

  // Secondary — Vibrant Orange
  static const Color orange = Color(0xFFFF7B3A); // Bright warm orange
  static const Color orangeLight = Color(0xFFFF9F6C); // Soft orange
  static const Color orangeDark = Color(0xFFE65C1A); // Deep orange

  // Tertiary — Mint Green
  static const Color mint = Color(0xFF2DD4A8); // Fresh mint green
  static const Color mintLight = Color(0xFF6EEECF); // Light mint
  static const Color mintDark = Color(0xFF1AAF8A); // Deep mint

  // Accent — Warm Gold (highlights)
  static const Color gold = Color(0xFFFFD166); // Sunshine gold
  static const Color goldLight = Color(0xFFFFE099); // Pale gold

  // Neutrals
  static const Color darkSlate = Color(0xFF0E1E33); // Dark bg (navy-tinted)
  static const Color darkSlateLight = Color(0xFF172D4A); // Card bg
  static const Color cream = Color(0xFFFFFDF7); // Light bg
  static const Color backgroundLight = Color(0xFFF4F7F9); // Light blueish-grey bg
  static const Color warmGrey = Color(0xFFF5F0EB);
  static const Color textDark = Color(0xFF1B3A5C);
  static const Color textLight = Color(0xFFF0F4F8);
  static const Color textMuted = Color(0xFF7A8FA3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [orange, Color(0xFFFF9F6C)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0F2440), Color(0xFF1B3A5C), Color(0xFF2E5A8A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient mintGradient = LinearGradient(
    colors: [mint, mintLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [orange, gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkSlate,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.orange,
        secondary: AppColors.mint,
        tertiary: AppColors.gold,
        surface: AppColors.darkSlateLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textLight,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.fredoka(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: AppColors.textLight,
        ),
        displayMedium: GoogleFonts.fredoka(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        displaySmall: GoogleFonts.fredoka(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        headlineLarge: GoogleFonts.fredoka(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textLight,
        ),
        headlineMedium: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        headlineSmall: GoogleFonts.fredoka(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textLight,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textLight,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSlateLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.mint.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.mint.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.orange,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.nunito(
          color: AppColors.textMuted.withValues(alpha: 0.6),
          fontSize: 16,
        ),
        prefixIconColor: AppColors.textMuted,
      ),
    );
  }
}

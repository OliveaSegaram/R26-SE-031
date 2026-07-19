import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Navy + Orange + Mint — matches adapted_mind_app onboarding flow.
class AppColors {
  static const Color primary = Color(0xFF1B3A5C);
  static const Color primaryLight = Color(0xFF2E5A8A);
  static const Color primaryDark = Color(0xFF0F2440);

  static const Color orange = Color(0xFFFF7B3A);
  static const Color orangeLight = Color(0xFFFF9F6C);
  static const Color orangeDark = Color(0xFFE65C1A);

  static const Color mint = Color(0xFF2DD4A8);
  static const Color mintLight = Color(0xFF6EEECF);
  static const Color mintDark = Color(0xFF1AAF8A);

  static const Color gold = Color(0xFFFFD166);
  static const Color goldLight = Color(0xFFFFE099);

  static const Color darkSlate = Color(0xFF0E1E33);
  static const Color darkSlateLight = Color(0xFF172D4A);
  static const Color cream = Color(0xFFFFFDF7);
  static const Color warmGrey = Color(0xFFF5F0EB);
  static const Color textDark = Color(0xFF1B3A5C);
  static const Color textLight = Color(0xFFF0F4F8);
  static const Color textMuted = Color(0xFF7A8FA3);

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
        titleLarge: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
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
    );
  }
}

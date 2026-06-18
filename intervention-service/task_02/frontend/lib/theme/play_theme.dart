import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Legacy alias — maps to adapted_mind_app palette.
class PlayTheme {
  static const purple = AppColors.primary;
  static const purpleLight = AppColors.primaryLight;
  static const teal = AppColors.mint;
  static const tealDark = AppColors.mintDark;
  static const sun = AppColors.gold;
  static const coral = AppColors.orange;
  static const sky = AppColors.primaryLight;
  static const navy = AppColors.primary;
  static const cream = AppColors.cream;
  static const cardWhite = AppColors.darkSlateLight;

  static const radius = 24.0;
  static const cardRadius = 20.0;

  static ThemeData theme() => AppTheme.darkTheme;
}

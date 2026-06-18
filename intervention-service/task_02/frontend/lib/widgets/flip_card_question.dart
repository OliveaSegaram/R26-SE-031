import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class FlipCardQuestion extends StatelessWidget {
  const FlipCardQuestion({super.key, required this.text, this.child});

  final String text;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 72 : 120),
      padding: EdgeInsets.all(compact ? 14 : 24),
      decoration: BoxDecoration(
        color: AppColors.darkSlateLight,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.mint.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.mint.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: child ??
          Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: compact ? 16 : 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textLight,
                height: 1.3,
              ),
            ),
          ),
    );
  }
}

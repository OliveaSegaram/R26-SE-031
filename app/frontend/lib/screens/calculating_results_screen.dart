import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/monster_character.dart';

/// Calculating Results Screen
/// Dyslexia-accessible: crème bg, gentle green progress, dark grey text.
class CalculatingResultsScreen extends StatefulWidget {
  final int score;

  const CalculatingResultsScreen({super.key, required this.score});

  @override
  State<CalculatingResultsScreen> createState() => _CalculatingResultsScreenState();
}

class _CalculatingResultsScreenState extends State<CalculatingResultsScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate network/calculation delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'analysis complete',
              style: AppTypography.heading(
                fontSize: 22,
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              'your dyslexia screening score is: ${widget.score}\n\nthis is just a prototype calculation!',
              style: AppTypography.body(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'finish',
                  style: AppTypography.button(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.calmBlue,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MonsterCharacter(
              size: 180,
              animation: MonsterAnimation.excited,
              imagePath: 'assets/images/solo_yellow.png',
            ),
            const SizedBox(height: 32),
            Text(
              'analyzing results...',
              style: AppTypography.heading(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                color: AppColors.gentleGreen,
                backgroundColor: AppColors.borderLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

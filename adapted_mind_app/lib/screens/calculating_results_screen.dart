import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/monster_character.dart';

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
        // TODO: Navigate to home screen or dashboard
        // For now, we just show a dialog to demonstrate completion.
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.darkSlateLight,
            title: Text(
              'Analysis Complete',
              style: GoogleFonts.fredoka(color: AppColors.textLight),
            ),
            content: Text(
              'Your dyslexia screening score is: ${widget.score}\n\nThis is just a prototype calculation!',
              style: GoogleFonts.nunito(color: AppColors.textLight),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Pop dialog
                  Navigator.of(context).pop();
                  // Go back to splash or home
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'FINISH',
                  style: GoogleFonts.nunito(
                    color: AppColors.orange,
                    fontWeight: FontWeight.bold,
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
      backgroundColor: AppColors.darkSlate,
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
              'Analyzing Results...',
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                color: AppColors.mint,
                backgroundColor: AppColors.darkSlateLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

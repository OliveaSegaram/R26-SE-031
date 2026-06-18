import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/adapted_mind_ui.dart';
import '../widgets/gradient_button.dart';
import '../widgets/kid_art.dart';
import 'task_flow_screen.dart';

class PlayHubScreen extends StatelessWidget {
  const PlayHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSlate,
      body: AmBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const buttonBlock = 54.0 + 16.0 + 8.0;
              final contentHeight = math.max(0, constraints.maxHeight - buttonBlock);
              final pictureSize = math
                  .min(constraints.maxWidth * 0.38, contentHeight * 0.42)
                  .clamp(80.0, 180.0);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              'Adapted Mind',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.orange,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ආයුබෝවන්!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              'පළමු ශ්‍රේණිය — කියවීම',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textLight,
                              ),
                            ),
                            SizedBox(height: math.max(16, constraints.maxHeight * 0.04)),
                            Center(
                              child: Container(
                                width: pictureSize,
                                height: pictureSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.mint.withValues(alpha: 0.35),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.mint.withValues(alpha: 0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: const KidArt(visual: 'book'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'පින්තූර, වචන, සහ කොටස්\nක්‍රීඩාව එකටම එනවා!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textLight,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'මධ්‍යම මට්ටමෙන් පටන් ගන්නවා.\nවැරදුණොත් සරල මට්ටමට යනවා.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16, top: 8),
                      child: GradientButton(
                        text: 'පටන් ගමු!',
                        icon: Icons.play_arrow_rounded,
                        height: 54,
                        gradient: AppColors.mintGradient,
                        onPressed: () => _start(context),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _start(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaskFlowScreen()),
    );
  }
}

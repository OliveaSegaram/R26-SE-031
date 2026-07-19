import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/monster_character.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/gradient_button.dart';
import 'signin_screen.dart';
import 'assessment_screen.dart';

/// Screen 4: Onboarding Questions Intro
/// Dyslexia-accessible: crème bg, colored info cards on mint/blue/amber backgrounds.
class OnboardingIntroScreen extends StatefulWidget {
  const OnboardingIntroScreen({super.key});

  @override
  State<OnboardingIntroScreen> createState() => _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends State<OnboardingIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _contentController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // Gradient accent — gentle green glow bottom-left
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gentleGreen.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _buildBackButton(context),
                      const Spacer(),
                      // Progress indicator dots
                      Row(
                        children: List.generate(3, (i) {
                          return Container(
                            width: i <= 1 ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i <= 1
                                  ? AppColors.calmBlue
                                  : AppColors.borderLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Speech bubble
                SlideTransition(
                  position: _contentSlide,
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: const SpeechBubble(
                      text:
                          "Just a few quick questions before we start your adventure!",
                      delay: Duration(milliseconds: 500),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Character with curious tilt
                FadeTransition(
                  opacity: _contentFade,
                  child: const MonsterCharacter(
                    size: 200,
                    animation: MonsterAnimation.curious,
                    showBody: true,
                  ),
                ),

                const Spacer(flex: 1),

                // Info cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SlideTransition(
                    position: _contentSlide,
                    child: FadeTransition(
                      opacity: _contentFade,
                      child: Column(
                        children: [
                          _buildInfoCard(
                            icon: Icons.timer_rounded,
                            text: 'takes less than 2 minutes',
                            bgColor: AppColors.mintBg,
                            iconColor: AppColors.gentleGreen,
                          ),
                          const SizedBox(height: 10),
                          _buildInfoCard(
                            icon: Icons.auto_awesome_rounded,
                            text: 'helps us personalize your learning',
                            bgColor: AppColors.slateBg,
                            iconColor: AppColors.calmBlue,
                          ),
                          const SizedBox(height: 10),
                          _buildInfoCard(
                            icon: Icons.favorite_rounded,
                            text: 'no wrong answers — just be you!',
                            bgColor: const Color(0xFFFFF3E0),
                            iconColor: AppColors.warmAmber,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Continue button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SlideTransition(
                    position: _contentSlide,
                    child: FadeTransition(
                      opacity: _contentFade,
                      child: GradientButton(
                        text: "let's go!",
                        icon: Icons.celebration_rounded,
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation,
                                      secondaryAnimation) =>
                                  const AssessmentScreen(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                );
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/monster_character.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/gradient_button.dart';
import 'onboarding_intro_screen.dart';

/// Screen 3: Character Introduction
/// Monster introduces itself with speech bubble and typewriter effect.
/// Clean background, excited bounce animation.
class CharacterIntroScreen extends StatefulWidget {
  const CharacterIntroScreen({super.key});

  @override
  State<CharacterIntroScreen> createState() => _CharacterIntroScreenState();
}

class _CharacterIntroScreenState extends State<CharacterIntroScreen>
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
      backgroundColor: AppColors.darkSlate,
      body: Stack(
        children: [
          // Subtle gradient accent
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.orange.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar with back button
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
                            width: i == 0 ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? AppColors.orange
                                  : AppColors.textLight.withValues(alpha: 0.15),
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
                      text: "Hi there! I'm Moko!\nI'm so excited to meet you!",
                      delay: Duration(milliseconds: 600),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Character with no animation as requested
                FadeTransition(
                  opacity: _contentFade,
                  child: const MonsterCharacter(
                    size: 220,
                    animation: MonsterAnimation.none,
                    showBody: true,
                    imagePath: 'assets/images/solo_yellow_straight.png',
                  ),
                ),

                const Spacer(flex: 3),

                // Continue button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SlideTransition(
                    position: _contentSlide,
                    child: FadeTransition(
                      opacity: _contentFade,
                      child: GradientButton(
                        text: 'CONTINUE',
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation,
                                      secondaryAnimation) =>
                                  const OnboardingIntroScreen(),
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

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.textLight.withValues(alpha: 0.08),
          ),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textLight,
          size: 22,
        ),
      ),
    );
  }
}

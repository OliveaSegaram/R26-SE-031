import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/onboarding_page_content.dart';
import 'select_student_screen.dart';
import '../widgets/monster_character.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  void _nextPage() {
    if (_currentPageIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Finished onboarding, go to select student screen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SelectStudentScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_currentPageIndex > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        } else {
           Navigator.of(context).pop();
        }
      },
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

  // UI 1: The Original Character Intro Layout
  Widget _buildPage1() {
    return const OnboardingPageContent(
      imagePath: 'assets/images/mascots/solo_yellow_straight.png',
      text: "Welcome to Sipsara!\nI'm Moko, your new learning buddy!",
    );
  }

  // UI 2: The Spotlight Layout (Blue Character)
  Widget _buildPage2() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Spotlight Character
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.calmBlue.withValues(alpha: 0.15),
          ),
          child: const Center(
            child: MonsterCharacter(
              size: 200,
              animation: MonsterAnimation.none,
              showBody: true,
              imagePath: 'assets/images/mascots/solo_blue.png',
            ),
          ),
        ),
        const SizedBox(height: 48),
        
        // Clean Text Block
        Text(
          "Fun Learning Games!",
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            "Master reading, spelling, and shapes with dyslexia-friendly games designed just for you.",
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // UI 3: Text Above + Floating Stars Layout (Green Character)
  Widget _buildPage3() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Text Above
        Text(
          "Track Your Progress!",
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            "Earn exciting rewards and unlock new levels as you master skills every day!",
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 48),
        
        // Character Below with Floating Stars
        SizedBox(
          height: 260,
          width: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned(
                top: 20, left: 20,
                child: Icon(Icons.star_rounded, color: AppColors.warmAmber, size: 32),
              ),
              const Positioned(
                top: 40, right: 30,
                child: Icon(Icons.star_rounded, color: AppColors.mintBg, size: 24),
              ),
              const Positioned(
                bottom: 60, left: 10,
                child: Icon(Icons.star_rounded, color: AppColors.calmBlue, size: 28),
              ),
              const Positioned(
                bottom: 30, right: 20,
                child: Icon(Icons.star_rounded, color: AppColors.warmAmber, size: 36),
              ),
              const MonsterCharacter(
                size: 250,
                animation: MonsterAnimation.none,
                showBody: true,
                imagePath: 'assets/images/mascots/solo_green.png',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPageIndex == 2;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // Subtle gradient accent — warm amber glow
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
                    AppColors.warmAmber.withValues(alpha: 0.08),
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
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: i == _currentPageIndex ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i == _currentPageIndex
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
                
                // Swipeable Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildPage1(),
                      _buildPage2(),
                      _buildPage3(),
                    ],
                  ),
                ),
                
                // Continue button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: GradientButton(
                    text: isLastPage ? 'get started' : 'continue',
                    onPressed: _nextPage,
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
}

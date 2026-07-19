import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'character_intro_screen.dart';
import 'signin_screen.dart';

/// Screen 2: Welcome / Get Started
/// Updated to precisely match the Collaboo design layout, but using original Adapted Mind assets and colors.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _topController;
  late AnimationController _characterController;
  late AnimationController _buttonController;
  late AnimationController _bounceController;

  late Animation<double> _topFadeAnimation;
  late Animation<double> _topSlideAnimation;
  late Animation<double> _characterScaleAnimation;
  late Animation<double> _characterFadeAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<Offset> _buttonSlideAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Top section (app name) fade + slide
    _topController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _topFadeAnimation = CurvedAnimation(
      parent: _topController,
      curve: Curves.easeOut,
    );
    _topSlideAnimation = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(parent: _topController, curve: Curves.easeOutCubic),
    );

    // Characters pop in
    _characterController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _characterScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _characterController,
        curve: Curves.elasticOut,
      ),
    );
    _characterFadeAnimation = CurvedAnimation(
      parent: _characterController,
      curve: Curves.easeOut,
    );

    // Gentle floating bounce
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Buttons slide up
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _buttonFadeAnimation = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeIn,
    );
    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutCubic),
    );

    // Staggered animation sequence
    _topController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _characterController.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _bounceController.repeat(reverse: true);
        _buttonController.forward();
      }
    });
  }

  @override
  void dispose() {
    _topController.dispose();
    _characterController.dispose();
    _buttonController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          // === NAVY BLUE BOTTOM BACKGROUND ===
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // === WHITE WAVY TOP SECTION ===
          ClipPath(
            clipper: WavyClipper(),
            child: Container(
              width: double.infinity,
              height: screenHeight * 0.72,
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.04),

                    // App name — animated slide down
                    AnimatedBuilder(
                      animation: _topController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _topSlideAnimation.value),
                          child: Opacity(
                            opacity: _topFadeAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Adapted',
                            style: GoogleFonts.fredoka(
                              fontSize: 50,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              height: 1.0,
                              letterSpacing: -1.0,
                            ),
                          ),
                          Text(
                            'Mind',
                            style: GoogleFonts.fredoka(
                              fontSize: 50,
                              fontWeight: FontWeight.w700,
                              color: AppColors.orange,
                              height: 1.0,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12), // Reduced gap under title

                    // === MONSTER CHARACTERS GROUP ===
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.04), // Reduced bottom padding since image moved up
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            _characterController,
                            _bounceController,
                          ]),
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                _bounceController.isAnimating
                                    ? _bounceAnimation.value
                                    : 0,
                              ),
                              child: Transform.scale(
                                scale: _characterScaleAnimation.value,
                                child: Opacity(
                                  opacity: _characterFadeAnimation.value,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: Align(
                            alignment: Alignment.topCenter, // Aligns image closer to the title
                            child: _buildCharacterGroup(screenWidth),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // === BOTTOM SECTION — text + buttons ===
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: SlideTransition(
                  position: _buttonSlideAnimation,
                  child: FadeTransition(
                    opacity: _buttonFadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Your Sinhala learning\nadventure awaits!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // GET STARTED button
                        GradientButton(
                          text: 'GET STARTED',
                          icon: Icons.rocket_launch_rounded,
                          onPressed: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation,
                                        secondaryAnimation) =>
                                    const CharacterIntroScreen(),
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

                        const SizedBox(height: 14),

                        // I ALREADY HAVE AN ACCOUNT button
                        OutlinedGradientButton(
                          text: 'I ALREADY HAVE AN ACCOUNT',
                          onPressed: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation,
                                        secondaryAnimation) =>
                                    const SignInScreen(),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 1),
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

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Displays the generated single image of the furry monsters group.
  Widget _buildCharacterGroup(double screenWidth) {
    final groupWidth = screenWidth * 0.85;

    return SizedBox(
      width: groupWidth,
      child: Image.asset(
        'assets/images/furry_monsters_group.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Custom wavy curve matching the reference image.
class WavyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    // Start at top left, go down
    path.lineTo(0, size.height * 0.85);
    
    // Curve dipping down in the middle-left, and going up towards the right
    path.quadraticBezierTo(
      size.width * 0.45, size.height * 1.05, 
      size.width, size.height * 0.65,
    );
    
    // Line to top right, close path
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

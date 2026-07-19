import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import 'welcome_screen.dart';

/// Screen 1: Splash Screen
/// Dyslexia-accessible: warm crème gradient, dark grey text particles,
/// calm blue & amber accents. No pure black on white.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // --- Animation controllers ---
  late AnimationController _bgController;
  late AnimationController _letterController;
  late AnimationController _characterBounceController;
  late AnimationController _glowController;
  late AnimationController _taglineController;
  late AnimationController _particleController;
  late AnimationController _exitController;

  // --- Animations ---
  late Animation<double> _bgFadeAnimation;
  late Animation<double> _characterBounceAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _taglineFadeAnimation;
  late Animation<Offset> _taglineSlideAnimation;
  late Animation<double> _exitAnimation;

  // Dyslexia-accessible color constants matching AppTheme
  static const Color _creamLight = AppColors.cream;
  static const Color _creamMid = AppColors.warmWhite;
  static const Color _creamDark = Color(0xFFF3EDDF); // Slightly darker for gradient depth
  static const Color _calmBlue = AppColors.calmBlue;
  static const Color _calmBlueLight = AppColors.calmBlueLight;
  static const Color _gentleGreen = AppColors.gentleGreen;
  static const Color _warmAmber = AppColors.warmAmber;
  static const Color _textDark = AppColors.textPrimary;

  // Sinhala hodiya characters for background animation
  static const List<String> _sinhalaChars = [
    'අ', 'ආ', 'ඇ', 'ඈ', 'ඉ', 'ඊ', 'උ', 'ඌ', 'එ', 'ඒ', 'ඔ', 'ඕ',
    'ක', 'ඛ', 'ග', 'ඝ', 'ඟ', 'ච', 'ඡ', 'ජ',
    'ට', 'ඨ', 'ඩ', 'ඪ', 'ණ', 'ත', 'ථ', 'ද', 'ධ', 'න',
    'ප', 'ඵ', 'බ', 'භ', 'ම', 'ය', 'ර', 'ල', 'ව',
    'ශ', 'ෂ', 'ස', 'හ', 'ළ', 'ෆ',
  ];

  // Particle data
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _initParticles();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 20 + 16, // Larger letters
        speed: _random.nextDouble() * 0.15 + 0.05,
        opacity: _random.nextDouble() * 0.3 + 0.15, // Higher visibility (0.15 to 0.45)
        color: [_calmBlue, _gentleGreen, _warmAmber, _textDark][_random.nextInt(4)],
        character: _sinhalaChars[_random.nextInt(_sinhalaChars.length)],
        rotation: (_random.nextDouble() - 0.5) * 0.4,
      ));
    }
  }

  void _initAnimations() {
    _bgController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _bgFadeAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeOut,
    );

    _letterController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _characterBounceController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _characterBounceAnimation =
        Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(
        parent: _characterBounceController,
        curve: Curves.easeInOut,
      ),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _taglineController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _taglineFadeAnimation = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeIn,
    );
    _taglineSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeOutCubic,
    ));

    _particleController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );

    _exitController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _exitAnimation = CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeIn,
    );
  }

  void _startAnimationSequence() {
    _bgController.forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _letterController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) {
        _characterBounceController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
      }
    });

    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) _taglineController.forward();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _particleController.repeat();
    });

    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        _exitController.forward().then((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const WelcomeScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _letterController.dispose();
    _characterBounceController.dispose();
    _glowController.dispose();
    _taglineController.dispose();
    _particleController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Widget _buildLetterElement({
    required String text,
    required double delay,
    required Offset fromOffset,
    required double fontSize,
    bool isImage = false,
    String? imagePath,
    double imageSize = 60,
    Color? textColor,
  }) {
    final begin = delay;
    final end = (delay + 0.35).clamp(0.0, 1.0);

    final slideAnimation = Tween<Offset>(
      begin: fromOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _letterController,
      curve: Interval(begin, end, curve: Curves.elasticOut),
    ));

    final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _letterController,
        curve: Interval(begin, (begin + 0.15).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      ),
    );

    final scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _letterController,
        curve: Interval(begin, end, curve: Curves.elasticOut),
      ),
    );

    return AnimatedBuilder(
      animation: _letterController,
      builder: (context, child) {
        return Transform.translate(
          offset: slideAnimation.value,
          child: Opacity(
            opacity: fadeAnimation.value,
            child: Transform.scale(
              scale: scaleAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: isImage
          ? _buildCharacterLetter(imagePath!, imageSize)
          : Text(
              text,
              style: AppTypography.heading(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: textColor ?? _textDark,
              ),
            ),
    );
  }

  Widget _buildCharacterLetter(String imagePath, double size) {
    return AnimatedBuilder(
      animation: _characterBounceController,
      builder: (context, child) {
        final scale = _characterBounceController.isAnimating
            ? _characterBounceAnimation.value
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _warmAmber.withValues(alpha: 0.25),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 380;
    final letterSize = isSmallScreen ? 38.0 : 46.0;
    final charImageSize = isSmallScreen ? 52.0 : 62.0;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          return Opacity(
            opacity: 1.0 - _exitAnimation.value,
            child: child,
          );
        },
        child: AnimatedBuilder(
          animation: _bgFadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _bgFadeAnimation.value,
              child: child,
            );
          },
          child: Stack(
            children: [
              // === BACKGROUND — warm crème gradient ===
              _buildBackground(screenSize),

              // === FLOATING PARTICLES ===
              _buildParticles(screenSize),

              // === CENTER GLOW ===
              _buildCenterGlow(screenSize),

              // === MAIN CONTENT ===
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top word: "Adapted"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildLetterElement(
                          text: 'A',
                          delay: 0.0,
                          fromOffset: const Offset(-80, -60),
                          fontSize: letterSize,
                          textColor: _textDark,
                        ),
                        _buildLetterElement(
                          text: 'd',
                          delay: 0.05,
                          fromOffset: const Offset(0, -100),
                          fontSize: letterSize,
                          textColor: _calmBlue,
                        ),
                        _buildLetterElement(
                          text: 'a',
                          delay: 0.10,
                          fromOffset: const Offset(60, -40),
                          fontSize: letterSize,
                          textColor: _textDark,
                        ),
                        _buildLetterElement(
                          text: 'p',
                          delay: 0.15,
                          fromOffset: const Offset(-50, 80),
                          fontSize: letterSize,
                          textColor: _warmAmber,
                        ),
                        _buildLetterElement(
                          text: 't',
                          delay: 0.20,
                          fromOffset: const Offset(90, 30),
                          fontSize: letterSize,
                          textColor: _textDark,
                        ),
                        _buildLetterElement(
                          text: 'e',
                          delay: 0.25,
                          fromOffset: const Offset(-40, -70),
                          fontSize: letterSize,
                          textColor: _calmBlue,
                        ),
                        // Monster character replaces the final 'd'
                        _buildLetterElement(
                          text: '',
                          delay: 0.30,
                          fromOffset: const Offset(0, 120),
                          fontSize: letterSize,
                          isImage: true,
                          imagePath: 'assets/images/character.png',
                          imageSize: charImageSize,
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Bottom word: "Mind"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildLetterElement(
                          text: 'M',
                          delay: 0.38,
                          fromOffset: const Offset(-100, 0),
                          fontSize: letterSize,
                          textColor: _warmAmber,
                        ),
                        _buildLetterElement(
                          text: '',
                          delay: 0.45,
                          fromOffset: const Offset(0, -120),
                          fontSize: letterSize,
                          isImage: true,
                          imagePath: 'assets/images/ace-avatar.png',
                          imageSize: charImageSize,
                        ),
                        _buildLetterElement(
                          text: 'n',
                          delay: 0.50,
                          fromOffset: const Offset(80, 60),
                          fontSize: letterSize,
                          textColor: _textDark,
                        ),
                        _buildLetterElement(
                          text: 'd',
                          delay: 0.55,
                          fromOffset: const Offset(100, 0),
                          fontSize: letterSize,
                          textColor: _calmBlue,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Tagline
                    AnimatedBuilder(
                      animation: _taglineController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: _taglineSlideAnimation.value,
                          child: Opacity(
                            opacity: _taglineFadeAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mintBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _gentleGreen.withValues(alpha: 0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _gentleGreen.withValues(alpha: 0.1),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          'learn, play and grow!',
                          style: AppTypography.body(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textBrown,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(Size screenSize) {
    return Container(
      width: screenSize.width,
      height: screenSize.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _creamLight,
            _creamMid,
            _creamLight,
            _creamDark,
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomPaint(
        painter: _GridPatternPainter(),
      ),
    );
  }

  Widget _buildParticles(Size screenSize) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, _) {
        return CustomPaint(
          size: screenSize,
          painter: _ParticlePainter(
            particles: _particles,
            progress: _particleController.value,
          ),
        );
      },
    );
  }

  Widget _buildCenterGlow(Size screenSize) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glowOpacity =
            _glowController.isAnimating ? _glowAnimation.value : 0.0;
        return Center(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _warmAmber.withValues(alpha: glowOpacity * 0.35),
                  _calmBlue.withValues(alpha: glowOpacity * 0.15),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

// === PARTICLE DATA ===
class _Particle {
  double x, y;
  final double size;
  final double speed;
  final double opacity;
  final Color color;
  final String character;
  final double rotation;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
    required this.character,
    required this.rotation,
  });
}

// === SINHALA CHARACTER PARTICLE PAINTER ===
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y = (particle.y - progress * particle.speed) % 1.0;
      final dx = particle.x * size.width;
      final dy = y * size.height;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(particle.rotation);

      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.character,
          style: TextStyle(
            fontSize: particle.size,
            color: particle.color.withValues(alpha: particle.opacity),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

// === GRID PATTERN PAINTER (very subtle warm grey lines) ===
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3E3E3E).withValues(alpha: 0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/monster_character.dart';
import '../widgets/gradient_button.dart';
import 'assessment_screen.dart';

/// Screen 5: Sign In / Sign In
/// Form with large kid-friendly inputs, social login options,
/// and a peek-a-boo character in the corner.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  late AnimationController _contentController;
  late AnimationController _monsterPeekController;

  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<Offset> _monsterPeekAnimation;

  bool _obscurePassword = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    // Character peek-a-boo from bottom right
    _monsterPeekController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _monsterPeekAnimation = Tween<Offset>(
      begin: const Offset(100, 100),
      end: const Offset(-5, -30), // Moved right so arm isn't cut off, and further up
    ).animate(
      CurvedAnimation(
        parent: _monsterPeekController,
        curve: Curves.elasticOut,
      ),
    );

    _contentController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _monsterPeekController.forward();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _monsterPeekController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSlate,
      resizeToAvoidBottomInset: false, // Keeps background elements (like the monster) static when keyboard opens
      body: Stack(
        children: [
          // Subtle gradient accents
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.orange.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -80,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.mint.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // Dynamic padding so fields scroll above keyboard
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Top bar
                    Row(
                      children: [
                        _buildBackButton(context),
                        const Spacer(),
                        // Progress dots - all filled
                        Row(
                          children: List.generate(3, (i) {
                            return Container(
                              width: 24,
                              height: 8,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Header
                    SlideTransition(
                      position: _contentSlide,
                      child: FadeTransition(
                        opacity: _contentFade,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create an Account!',
                              style: GoogleFonts.fredoka(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join the adventure today!',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Form fields
                    SlideTransition(
                      position: _contentSlide,
                      child: FadeTransition(
                        opacity: _contentFade,
                        child: Column(
                          children: [
                            // Name field
                            _buildInputField(
                              controller: _nameController,
                              hint: 'Full Name',
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.name,
                            ),

                            const SizedBox(height: 16),

                            // Email field
                            _buildInputField(
                              controller: _emailController,
                              hint: 'Email or Username',
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: 16),

                            // Password field
                            _buildInputField(
                              controller: _passwordController,
                              hint: 'Password',
                              icon: Icons.lock_rounded,
                              isPassword: true,
                            ),

                            const SizedBox(height: 12),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.orange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Sign in button
                            GradientButton(
                              text: 'SIGN UP',
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const AssessmentScreen(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 28),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: AppColors.textLight
                                        .withValues(alpha: 0.08),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'or continue with',
                                    style: GoogleFonts.nunito(
                                      color: AppColors.textMuted
                                          .withValues(alpha: 0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: AppColors.textLight
                                        .withValues(alpha: 0.08),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Social login buttons
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                _buildSocialButton(
                                  icon: Icons.g_mobiledata_rounded,
                                  color: const Color(0xFFDB4437),
                                  label: 'Google',
                                ),
                                const SizedBox(width: 16),
                                _buildSocialButton(
                                  icon: Icons.facebook_rounded,
                                  color: const Color(0xFF4267B2),
                                  label: 'Facebook',
                                ),
                                const SizedBox(width: 16),
                                _buildSocialButton(
                                  icon: Icons.apple_rounded,
                                  color: Colors.white,
                                  label: 'Apple',
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            // Sign up link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: GoogleFonts.nunito(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    'Sign In',
                                    style: GoogleFonts.nunito(
                                      color: AppColors.orange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Terms text
                            Text(
                              'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                color: AppColors.textMuted
                                    .withValues(alpha: 0.6),
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 100), // Increased bottom padding so text scrolls above character
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Character peek-a-boo from bottom left
          Positioned(
            bottom: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _monsterPeekAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: _monsterPeekAnimation.value,
                  child: child,
                );
              },
              child: const MonsterCharacter(
                size: 110,
                animation: MonsterAnimation.idle,
                showBody: true,
                imagePath: 'assets/images/solo_pink_up.png',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.mint.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: keyboardType,
        style: GoogleFonts.nunito(
          color: AppColors.textLight,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, size: 22),
          ),
          suffixIcon: isPassword
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.darkSlateLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppColors.mint.withValues(alpha: 0.15),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppColors.mint.withValues(alpha: 0.15),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppColors.orange,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 90,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.darkSlateLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textLight.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.nunito(
                  color: AppColors.textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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

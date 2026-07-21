import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/monster_character.dart';
import '../services/auth_service.dart';
import 'select_student_screen.dart';
import 'signup_screen.dart';

/// Sign-In Screen
/// Dyslexia-accessible: crème background, warm white inputs, 18pt+ text,
/// calm blue accents, left-aligned, sentence case.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;



  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await AuthService().login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.softCoral),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SelectStudentScreen()),
      );
    }
  }

  Future<void> _onGoogleSignIn() async {
    setState(() => _isLoading = true);

    final error = await AuthService().loginWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == 'CANCELED') {
      return;
    } else if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.softCoral),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SelectStudentScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.calmBlueDark.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Character
                  Center(
                    child: MonsterCharacter(
                      size: 110,
                      animation: MonsterAnimation.wave,
                      imagePath: 'assets/images/solo_yellow.png',
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Heading
                  Text(
                    'welcome back!',
                    style: AppTypography.heading(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'sign in to continue your adventure',
                    style: AppTypography.body(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.calmBlueDark.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Email input
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTypography.body(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'email address',
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password input
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: AppTypography.body(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'forgot password?',
                        style: AppTypography.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.calmBlue,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sign in button
                  GradientButton(
                    text: _isLoading ? 'signing in...' : 'sign in',
                    icon: Icons.login_rounded,
                    onPressed: _isLoading ? () {} : _onSignIn,
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.borderLight)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: AppTypography.caption(fontSize: 14),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.borderLight)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Social login
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          Icons.g_mobiledata_rounded, 
                          'google',
                          onTap: _isLoading ? null : _onGoogleSignIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSocialButton(
                          Icons.apple_rounded, 
                          'apple',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Sign up link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "don't have an account? ",
                          style: AppTypography.body(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'sign up',
                            style: AppTypography.body(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.calmBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.calmBlueDark.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.body(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

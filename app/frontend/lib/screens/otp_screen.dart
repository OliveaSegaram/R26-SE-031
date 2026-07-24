import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../services/auth_service.dart';
import 'reset_password_screen.dart';
import 'select_student_screen.dart';
import 'onboarding_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final bool isSignup;
  
  const OtpScreen({super.key, required this.email, this.isSignup = false});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Request focus automatically, unless it's a demo bypass
    if (widget.email.startsWith('demo_')) {
      // Auto-fill and auto-verify for demo users
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _otpController.text = "000000";
          _verifyOtp();
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    String otp = _otpController.text;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 digits.'), backgroundColor: AppColors.softCoral),
      );
      return;
    }

    if (widget.isSignup) {
      setState(() => _isLoading = true);
      final error = await AuthService().verifyEmail(widget.email, otp);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.softCoral),
        );
      } else {
        if (widget.isSignup) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SelectStudentScreen()),
            (route) => false,
          );
        }
      }
    } else {
      // Forgot Password flow: pass OTP to ResetPasswordScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(email: widget.email, otp: otp),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'check your email',
                style: AppTypography.heading(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: AppTypography.body(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'We\'ve sent a 6-digit code to '),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const TextSpan(text: '. Enter it below to verify your account.'),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // World-Class OTP Input (Single Hidden TextField + Visual Boxes)
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).requestFocus(_focusNode);
                },
                child: Stack(
                  children: [
                    // Hidden TextField that controls the actual keyboard
                    Opacity(
                      opacity: 0.0,
                      child: TextField(
                        controller: _otpController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) {
                          setState(() {}); // Rebuild to update UI boxes
                          if (value.length == 6) {
                            _focusNode.unfocus();
                            _verifyOtp(); // Auto-verify when 6 digits are entered
                          }
                        },
                      ),
                    ),
                    
                    // Visual Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        String currentDigit = '';
                        if (index < _otpController.text.length) {
                          currentDigit = _otpController.text[index];
                        }
                        
                        bool isFocused = index == _otpController.text.length || 
                                       (index == 5 && _otpController.text.length == 6);
                        
                        return Container(
                          width: 45,
                          height: 55,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFocused ? AppColors.calmBlue : AppColors.borderLight,
                              width: 2,
                            ),
                            boxShadow: isFocused ? [
                              BoxShadow(
                                color: AppColors.calmBlue.withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ] : [],
                          ),
                          child: Text(
                            currentDigit,
                            style: AppTypography.heading(
                              fontSize: 24, 
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.calmBlue))
                  : GradientButton(
                      text: 'verify',
                      onPressed: _verifyOtp,
                      icon: Icons.check_circle_outline,
                    ),
              const SizedBox(height: 20), // Extra padding for keyboard
            ],
          ),
        ),
      ),
    );
  }
}

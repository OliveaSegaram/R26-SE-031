import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.'), backgroundColor: AppColors.softCoral),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final error = await AuthService().requestPasswordReset(email);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.softCoral),
      );
    } else {
      // Proceed to OTP Screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            email: _emailController.text.trim(), 
            isSignup: false,
          ),
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
              // Image/Icon
              Center(
                child: Image.asset(
                  'assets/images/monster_pink.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              
              const SizedBox(height: 40),
              
              Text(
                'forgot password?',
                style: AppTypography.heading(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Don\'t worry! Enter the email address associated with your account, and we\'ll send you a pin to reset it.',
                style: AppTypography.body(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTypography.body(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              
              const SizedBox(height: 40),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.calmBlue))
                  : GradientButton(
                      text: 'send code',
                      onPressed: _submitEmail,
                      icon: Icons.send_rounded,
                    ),
              const SizedBox(height: 20), // Extra padding at bottom for keyboard
            ],
          ),
        ),
      ),
    );
  }
}

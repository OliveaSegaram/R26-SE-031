import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../services/auth_service.dart';

class ConsentSpecialistScreen extends StatefulWidget {
  final String clinicCode;
  final String studentId;

  const ConsentSpecialistScreen({super.key, required this.clinicCode, required this.studentId});

  @override
  State<ConsentSpecialistScreen> createState() => _ConsentSpecialistScreenState();
}

class _ConsentSpecialistScreenState extends State<ConsentSpecialistScreen> {
  bool _agreed = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('please tap the checkbox to agree.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await AuthService().connectSpecialist(widget.clinicCode, widget.studentId);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.softCoral),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('successfully connected!'), backgroundColor: AppColors.calmBlue),
      );
      // Pop ConsentSpecialistScreen AND ConnectSpecialistScreen
      int count = 0;
      Navigator.popUntil(context, (route) => count++ == 2);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'privacy consent',
          style: AppTypography.heading(fontSize: 22, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('what you are sharing:', style: AppTypography.heading(fontSize: 18, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  _buildBulletPoint('phonetic error patterns (e.g., visual reversals like b/d)'),
                  _buildBulletPoint('time spent on learning activities'),
                  _buildBulletPoint('overall reading level progression'),
                  const SizedBox(height: 24),
                  Text('why we share this:', style: AppTypography.heading(fontSize: 18, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Text(
                    "this allows your child's specialist to track their response to intervention (RTI) in real-time, helping them adjust therapy sessions.",
                    style: AppTypography.body(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Checkbox(
                  value: _agreed,
                  activeColor: AppColors.calmBlue,
                  onChanged: (val) => setState(() => _agreed = val ?? false),
                ),
                Expanded(
                  child: Text(
                    "i consent to sharing my child's learning data with the specialist associated with clinic code ${widget.clinicCode}.",
                    style: AppTypography.body(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            GradientButton(
              text: _isLoading ? 'connecting...' : 'agree & connect',
              icon: Icons.check_circle_outline,
              onPressed: _isLoading ? () {} : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: Icon(Icons.circle, size: 8, color: AppColors.calmBlue),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTypography.body(fontSize: 14, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'assessment_screen.dart';

/// Parental Consent Screen
/// Displayed before the assessment when registering a new student.
/// The parent must agree to all terms and provide a digital signature.
class ConsentScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const ConsentScreen({super.key, required this.studentData});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _signatureController = TextEditingController();

  bool _consentGuardian = false;
  bool _consentData = false;
  bool _consentPurpose = false;
  bool _consentTerms = false;

  bool get _allConsentsGiven =>
      _consentGuardian &&
      _consentData &&
      _consentPurpose &&
      _consentTerms &&
      _signatureController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  void _onAgreeAndContinue() {
    if (!_allConsentsGiven) return;

    final consentData = Map<String, dynamic>.from(widget.studentData);
    consentData['consent_given'] = true;
    consentData['consent_parent_name'] = _signatureController.text.trim();
    consentData['consent_date'] = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentScreen(studentData: consentData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'parental consent',
          style: AppTypography.heading(fontSize: 22, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Card ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.calmBlue.withValues(alpha: 0.08),
                      AppColors.calmBlue.withValues(alpha: 0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.calmBlue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.calmBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: AppColors.calmBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'student protection agreement',
                            style: AppTypography.heading(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'please review and accept the following terms before proceeding.',
                            style: AppTypography.body(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- Student Info Summary ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.cream,
                      backgroundImage: AssetImage(
                        widget.studentData['avatar_url'] ?? 'assets/images/solo_blue.png',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.studentData['first_name']} ${widget.studentData['last_name']}',
                          style: AppTypography.body(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Grade 1 • @${widget.studentData['username']}',
                          style: AppTypography.caption(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --- Consent Checkboxes ---
              Text(
                'consent items',
                style: AppTypography.heading(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.calmBlue,
                ),
              ),
              const SizedBox(height: 16),

              _buildConsentItem(
                value: _consentGuardian,
                onChanged: (val) => setState(() => _consentGuardian = val ?? false),
                icon: Icons.family_restroom_rounded,
                title: 'guardian confirmation',
                description: 'I confirm that I am the parent or legal guardian of this child and have the authority to provide consent on their behalf.',
              ),

              _buildConsentItem(
                value: _consentData,
                onChanged: (val) => setState(() => _consentData = val ?? false),
                icon: Icons.analytics_outlined,
                title: 'learning data collection',
                description: 'I consent to the collection and processing of my child\'s learning data (responses, progress, and performance) to personalize their educational experience.',
              ),

              _buildConsentItem(
                value: _consentPurpose,
                onChanged: (val) => setState(() => _consentPurpose = val ?? false),
                icon: Icons.psychology_outlined,
                title: 'dyslexia screening purpose',
                description: 'I understand that this app is designed for Grade 1 dyslexia screening and learning support. It does not provide medical diagnoses and should be used alongside professional guidance.',
              ),

              _buildConsentItem(
                value: _consentTerms,
                onChanged: (val) => setState(() => _consentTerms = val ?? false),
                icon: Icons.description_outlined,
                title: 'terms of use & privacy policy',
                description: 'I have read and agree to the terms of use and privacy policy. I understand my child\'s data will be stored securely and will not be shared with third parties.',
              ),

              const SizedBox(height: 28),

              // --- Digital Signature ---
              Text(
                'digital signature',
                style: AppTypography.heading(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.calmBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'type your full name below as your digital signature.',
                style: AppTypography.body(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.calmBlueDark.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _signatureController,
                      onChanged: (_) => setState(() {}),
                      style: AppTypography.body(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'parent / guardian full name',
                        prefixIcon: const Icon(Icons.draw_rounded),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    Divider(color: AppColors.borderLight),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'date: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                          style: AppTypography.caption(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- Agree Button ---
              GradientButton(
                text: 'i agree & continue',
                icon: Icons.check_circle_rounded,
                gradient: _allConsentsGiven
                    ? AppColors.greenGradient
                    : LinearGradient(
                        colors: [Colors.grey.shade400, Colors.grey.shade500],
                      ),
                onPressed: _allConsentsGiven ? _onAgreeAndContinue : () {},
              ),

              const SizedBox(height: 12),

              Center(
                child: Text(
                  'you can withdraw consent at any time\nfrom the parent account settings.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentItem({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value
            ? AppColors.gentleGreen.withValues(alpha: 0.06)
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? AppColors.gentleGreen.withValues(alpha: 0.4)
              : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.gentleGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: value ? AppColors.gentleGreen : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.body(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

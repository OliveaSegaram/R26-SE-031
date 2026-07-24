import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../welcome_screen.dart';
import '../add_student_screen.dart';
import '../connect_specialist_screen.dart';
import '../../services/auth_service.dart';
import '../../services/student_service.dart';

/// Parent Settings Screen — Clean settings for account, students,
/// subscription, email preferences, help & support.
class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  bool progressEmails = true;
  bool promotions = false;
  bool newsletters = false;
  bool periodicUpdates = true;

  bool _isLoading = true;
  String _userName = 'loading...';
  String _userEmail = 'loading...';
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await AuthService().getUserProfile();
    final students = await StudentService().getStudents();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _students = students;
        if (profile != null) {
          _userName = profile['name'] ?? 'unknown';
          _userEmail = profile['email'] ?? 'unknown';
        } else {
          _userName = 'error loading profile';
          _userEmail = '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.calmBlue))
              else ...[
                _buildSection('account', _buildAccountCard()),
                _buildSection('manage students', _buildStudentsCard()),
                _buildSection('manage subscription', _buildSubscriptionCard()),
                _buildSection('email settings', _buildEmailSettingsCard()),
                _buildSection('help & support', _buildHelpCard()),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.softCoral.withValues(alpha: 0.12),
            AppColors.cream,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'settings',
            style: AppTypography.heading(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.heading(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.calmBlue,
            ),
          ),
          const SizedBox(height: 12),
          content,
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAccountCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('owner name', _userName),
          Divider(color: AppColors.borderLight, height: 24),
          _buildInfoRow('email', _userEmail),
          Divider(color: AppColors.borderLight, height: 24),
          _buildInfoRow('password', '********'),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _showChangePasswordDialog,
              icon: const Icon(Icons.edit, color: AppColors.calmBlue, size: 18),
              label: Text(
                'edit password',
                style: AppTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.calmBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_students.isEmpty)
            Text(
              'no students added yet. add a student to get started!',
              style: AppTypography.body(
                  fontSize: 14, color: AppColors.textSecondary),
            )
          else
            ..._students.map((student) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.cardSurface,
                      backgroundImage: AssetImage(
                          student['avatar_url'] ?? 'assets/images/solo_blue.png'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['first_name'] ?? 'unknown',
                            style: AppTypography.body(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            student['grade'] ?? 'n/a',
                            style: AppTypography.caption(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddStudentScreen(
                                editStudentData:
                                    student as Map<String, dynamic>),
                          ),
                        );
                      },
                      child: const Icon(Icons.edit,
                          color: AppColors.calmBlue, size: 20),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddStudentScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add, color: AppColors.gentleGreen, size: 18),
            label: Text(
              'add student',
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gentleGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('current plan', 'premium monthly'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showComingSoon('cancel subscription'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.softCoral,
                    side: const BorderSide(color: AppColors.softCoral),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('cancel',
                      style: AppTypography.button(
                          fontSize: 14, color: AppColors.softCoral)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showComingSoon('hold subscription'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warmAmber,
                    side: const BorderSide(color: AppColors.warmAmber),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('hold',
                      style: AppTypography.button(
                          fontSize: 14, color: AppColors.warmAmber)),
                ),
              ),
            ],
          ),
          Divider(color: AppColors.borderLight, height: 32),
          _buildInfoRow('payment method', 'visa ending in 4242'),
          const SizedBox(height: 8),
          _buildInfoRow('next payment', 'aug 15, 2026 (\$9.99)'),
        ],
      ),
    );
  }

  Widget _buildEmailSettingsCard() {
    return _buildCard(
      child: Column(
        children: [
          _buildSwitchRow('progress emails', progressEmails,
              (val) => setState(() => progressEmails = val)),
          Divider(color: AppColors.borderLight),
          _buildSwitchRow('promotions', promotions,
              (val) => setState(() => promotions = val)),
          Divider(color: AppColors.borderLight),
          _buildSwitchRow('newsletters', newsletters,
              (val) => setState(() => newsletters = val)),
          Divider(color: AppColors.borderLight),
          _buildSwitchRow('periodic updates', periodicUpdates,
              (val) => setState(() => periodicUpdates = val)),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('email support', 'support@adaptedmind.com'),
          Divider(color: AppColors.borderLight, height: 24),
          _buildInfoRow('phone support', '1-800-123-4567'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await AuthService().logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label:
                  Text('logout', style: AppTypography.button(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softCoral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.body(
                fontSize: 14, color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            style: AppTypography.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                AppTypography.body(fontSize: 16, color: AppColors.textPrimary)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.gentleGreen,
          activeTrackColor: AppColors.gentleGreen.withValues(alpha: 0.3),
          inactiveThumbColor: AppColors.textSecondary,
          inactiveTrackColor: AppColors.borderLight,
        ),
      ],
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature feature coming soon!')),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: Text('change password',
                  style: AppTypography.heading(
                      fontSize: 20, color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(errorMessage!,
                          style: AppTypography.body(
                              fontSize: 14, color: AppColors.softCoral)),
                    ),
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    style: AppTypography.body(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'current password',
                      labelStyle: AppTypography.caption(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: AppTypography.body(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'new password',
                      labelStyle: AppTypography.caption(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.pop(context),
                  child: Text('cancel',
                      style: AppTypography.body(
                          fontSize: 14, color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          final error = await AuthService().changePassword(
                            oldPasswordController.text,
                            newPasswordController.text,
                          );
                          setState(() => isLoading = false);
                          if (error != null) {
                            setState(() => errorMessage = error);
                          } else {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('password changed successfully!'),
                                backgroundColor: AppColors.gentleGreen,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.calmBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('save',
                          style: AppTypography.button(fontSize: 14)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

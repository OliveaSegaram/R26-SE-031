import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'welcome_screen.dart';
import 'assessment_screen.dart';
import 'assessment_prompt_screen.dart';
import 'add_student_screen.dart';
import 'connect_specialist_screen.dart';
import 'dashboard_screen.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';

/// Parent Account Screen
/// Dyslexia-accessible: crème bg, warm white cards, calm blue section headers,
/// gentle green switches, sentence case text.
class ParentAccountScreen extends StatefulWidget {
  const ParentAccountScreen({super.key});

  @override
  State<ParentAccountScreen> createState() => _ParentAccountScreenState();
}

class _ParentAccountScreenState extends State<ParentAccountScreen> {
  bool progressEmails = true;
  bool promotions = false;
  bool newsletters = false;
  bool periodicUpdates = true;

  bool _isLoading = true;
  String _userName = 'loading...';
  String _userEmail = 'loading...';
  List<dynamic> _students = [];
  final Set<String> _deletingStudentIds = {};

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'parent account',
          style: AppTypography.heading(fontSize: 22, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('account'),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.calmBlue))
            else
              _buildAccountCard(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('manage students'),
            _buildStudentsCard(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('specialist access'),
            _buildSpecialistCard(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('manage subscription'),
            _buildSubscriptionCard(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('email settings'),
            _buildEmailSettingsCard(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('additional help'),
            _buildHelpCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: AppTypography.heading(
          fontSize: 20,
          color: AppColors.calmBlue,
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
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
    return _buildCardContainer(
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
              onPressed: () {
                _showChangePasswordDialog();
              },
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
          )
        ],
      ),
    );
  }

  Widget _buildStudentsCard() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_students.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'no students added yet. add a student to get started!',
                style: AppTypography.body(fontSize: 14, color: AppColors.textSecondary),
              ),
            )
          else
            ..._students.map((student) {
              final bool needsScreening = student['assessment_completed'] != true;
              final bool isDeleting = _deletingStudentIds.contains(student['id']);

              return AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: isDeleting ? 0.0 : 1.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 400),
                  scale: isDeleting ? 0.01 : 1.0,
                  curve: Curves.easeInBack, // Gives that "sucked into magic dust" effect
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DashboardScreen(studentData: student as Map<String, dynamic>),
                          ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warmWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.cream,
                          backgroundImage: AssetImage(student['avatar_url'] ?? 'assets/images/solo_blue.png'),
                        ),
                        const SizedBox(width: 12),

                        // Name + screening nudge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['first_name'] ?? 'unknown',
                                style: AppTypography.body(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (needsScreening)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AssessmentPromptScreen(
                                          studentId: student['id'],
                                          studentName: student['first_name'] ?? 'Student',
                                          avatarUrl: student['avatar_url'],
                                        ),
                                      ),
                                    ).then((_) => _loadUserProfile());
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'complete screening →',
                                      style: AppTypography.caption(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.calmBlue,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  'screening completed ✓',
                                  style: AppTypography.caption(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.gentleGreen,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Daily limit pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            student['daily_limit'] ?? 'no limit',
                            style: AppTypography.caption(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Edit button
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddStudentScreen(editStudentData: student as Map<String, dynamic>),
                              ),
                            );
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.calmBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit_rounded, color: AppColors.calmBlue, size: 16),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Delete button
                        GestureDetector(
                          onTap: () {
                            _showDeleteConfirmationDialog(student as Map<String, dynamic>);
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 16),
                          ),
                        ),
                      ],
                    ), // Row
                  ), // Container
                ), // InkWell
              ), // Padding
              ), // AnimatedScale
              ); // AnimatedOpacity
            }),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
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
          )
        ],
      ),
    );
  }

  Widget _buildSpecialistCard() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "connect your child's reading specialist or speech-language pathologist to share learning data.",
            style: AppTypography.body(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConnectSpecialistScreen()),
                );
              },
              icon: const Icon(Icons.link_rounded, color: AppColors.calmBlue, size: 18),
              label: Text(
                'connect specialist',
                style: AppTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.calmBlue,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('current plan', 'premium monthly'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showComingSoon('cancel subscription');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.softCoral,
                    side: const BorderSide(color: AppColors.softCoral),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('cancel', style: AppTypography.button(fontSize: 14, color: AppColors.softCoral)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showComingSoon('hold subscription');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warmAmber,
                    side: const BorderSide(color: AppColors.warmAmber),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('hold', style: AppTypography.button(fontSize: 14, color: AppColors.warmAmber)),
                ),
              ),
            ],
          ),
          Divider(color: AppColors.borderLight, height: 32),
          _buildInfoRow('payment method', 'visa ending in 4242'),
          const SizedBox(height: 8),
          _buildInfoRow('next payment', 'aug 15, 2026 (\$9.99)'),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                _showComingSoon('update payment method');
              },
              icon: const Icon(Icons.credit_card, color: AppColors.calmBlue, size: 18),
              label: Text(
                'update payment',
                style: AppTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.calmBlue,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmailSettingsCard() {
    return _buildCardContainer(
      child: Column(
        children: [
          _buildSwitchRow('progress emails', progressEmails, (val) {
            setState(() => progressEmails = val);
          }),
          Divider(color: AppColors.borderLight),
          _buildSwitchRow('promotions', promotions, (val) {
            setState(() => promotions = val);
          }),
          Divider(color: AppColors.borderLight),
          _buildSwitchRow('newsletters', newsletters, (val) {
            setState(() => newsletters = val);
          }),
          Divider(color: AppColors.borderLight),
          _buildSwitchRow('periodic updates', periodicUpdates, (val) {
            setState(() => periodicUpdates = val);
          }),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('email support', 'support@sipsara.com'),
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
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: Text('logout', style: AppTypography.button(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softCoral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.body(fontSize: 14, color: AppColors.textSecondary),
        ),
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

  Widget _buildSwitchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.body(fontSize: 16, color: AppColors.textPrimary),
        ),
        Row(
          children: [
            Text(
              value ? 'on' : 'off',
              style: AppTypography.caption(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: value ? AppColors.gentleGreen : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.gentleGreen,
              activeTrackColor: AppColors.gentleGreen.withValues(alpha: 0.3),
              inactiveThumbColor: AppColors.textSecondary,
              inactiveTrackColor: AppColors.borderLight,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Text(
      text,
      style: AppTypography.caption(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.calmBlue,
      ),
    );
  }

  Widget _buildTableData(String text) {
    return Text(
      text,
      style: AppTypography.body(fontSize: 14, color: AppColors.textPrimary),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('change password', style: AppTypography.heading(fontSize: 20, color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(errorMessage!, style: AppTypography.body(fontSize: 14, color: AppColors.softCoral)),
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
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text('cancel', style: AppTypography.body(fontSize: 14, color: AppColors.textSecondary)),
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

                          setState(() {
                            isLoading = false;
                          });

                          if (error != null) {
                            setState(() {
                              errorMessage = error;
                            });
                          } else {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('password changed successfully!'), backgroundColor: AppColors.gentleGreen),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.calmBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('save', style: AppTypography.button(fontSize: 14)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(Map<String, dynamic> student) async {
    final studentName = student['first_name'] ?? 'this student';
    final studentId = student['id'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isDeleting = false;
        String? deleteError;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.warmWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'delete student?',
                    style: AppTypography.heading(fontSize: 20, color: Colors.redAccent),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'are you absolutely sure you want to delete $studentName? this action cannot be undone and all learning progress will be lost permanently.',
                    style: AppTypography.body(fontSize: 15, color: AppColors.textPrimary),
                  ),
                  if (deleteError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        deleteError!,
                        style: AppTypography.body(fontSize: 13, color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: Text('cancel', style: AppTypography.body(fontSize: 14, color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setState(() {
                            isDeleting = true;
                            deleteError = null;
                          });

                          final error = await StudentService().deleteStudent(studentId);

                          if (error != null) {
                            setState(() {
                              isDeleting = false;
                              deleteError = error;
                            });
                          } else {
                            if (!context.mounted) return;
                            Navigator.pop(context); // Close dialog first
                            
                            // Now use the PARENT's setState to trigger the disappear animation
                            this.setState(() {
                              _deletingStudentIds.add(studentId);
                            });
                            
                            // Wait for the shrink+fade animation to finish
                            await Future.delayed(const Duration(milliseconds: 500));
                            
                            // Remove the student from the local list (no server re-fetch needed)
                            if (!mounted) return;
                            this.setState(() {
                              _students.removeWhere((s) => s['id'] == studentId);
                              _deletingStudentIds.remove(studentId);
                            });
                            
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$studentName deleted successfully.'),
                                backgroundColor: AppColors.gentleGreen,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('delete forever', style: AppTypography.button(fontSize: 14)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

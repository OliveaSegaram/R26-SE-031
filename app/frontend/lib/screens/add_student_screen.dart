import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'consent_screen.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';
import 'parent_account_screen.dart';

/// Add Student Screen
/// Dyslexia-accessible: crème bg, warm white form, calm blue border,
/// gentle green avatar selection, sentence case text.
class AddStudentScreen extends StatefulWidget {
  final Map<String, dynamic>? editStudentData;

  const AddStudentScreen({super.key, this.editStudentData});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedGrade = 'Grade 1';
  String? _selectedDailyLimit = 'No Limit';
  String _selectedAvatarUrl = 'assets/images/solo_blue.png';

  final List<String> _avatars = [
    'assets/images/solo_blue.png',
    'assets/images/solo_green.png',
    'assets/images/solo_pink.png',
    'assets/images/solo_yellow.png',
  ];

  final List<String> _limits = [
    'No Limit',
    '15 minutes',
    '30 minutes',
    '45 minutes',
    '1 hour',
    '1.5 hours',
    '2 hours',
  ];

  bool _isLoading = false;
  bool _isGoogleUser = false;

  @override
  void initState() {
    super.initState();
    if (widget.editStudentData != null) {
      _firstNameController.text = widget.editStudentData!['first_name'] ?? '';
      _lastNameController.text = widget.editStudentData!['last_name'] ?? '';
      _usernameController.text = widget.editStudentData!['username'] ?? '';
      _selectedGrade = widget.editStudentData!['grade'];
      _selectedDailyLimit =
          widget.editStudentData!['daily_limit'] ?? 'No Limit';
      _selectedAvatarUrl =
          widget.editStudentData!['avatar_url'] ??
          'assets/images/solo_blue.png';
    }

    _checkGoogleUser();
  }

  Future<void> _checkGoogleUser() async {
    final provider = await AuthService().getAuthProvider();
    if (mounted) {
      setState(() {
        _isGoogleUser = provider == 'google';
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.editStudentData != null) ...[
                        Center(
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.calmBlue,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: AppColors.cardSurface,
                                  backgroundImage: AssetImage(
                                    _selectedAvatarUrl,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'editing ${widget.editStudentData!['first_name']}',
                                style: AppTypography.heading(
                                  fontSize: 20,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ] else ...[
                        Text(
                          'add an additional student for free. you are allowed to add up to 5 children to your account.',
                          style: AppTypography.body(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      Text(
                        widget.editStudentData == null
                            ? 'new student information'
                            : 'student information',
                        style: AppTypography.heading(
                          fontSize: 20,
                          color: AppColors.calmBlue,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'choose a monster profile picture',
                        style: AppTypography.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _avatars.map((url) {
                            final isSelected = _selectedAvatarUrl == url;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedAvatarUrl = url),
                              child: Container(
                                margin: const EdgeInsets.only(right: 16),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.gentleGreen
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 36,
                                  backgroundColor: AppColors.cardSurface,
                                  backgroundImage: AssetImage(url),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form Fields Container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.borderBlue,
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
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                hintText: 'student first name',
                              ),
                              style: AppTypography.body(fontSize: 16),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                hintText: 'student last name',
                              ),
                              style: AppTypography.body(fontSize: 16),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                hintText: 'student username (login)',
                              ),
                              style: AppTypography.body(fontSize: 16),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Grade — locked to Grade 1
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mintBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.gentleGreen.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    color: AppColors.gentleGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Grade 1',
                                    style: AppTypography.body(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.gentleGreen.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'auto-set',
                                      style: AppTypography.caption(
                                        fontSize: 12,
                                        color: AppColors.gentleGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              value: _selectedDailyLimit,
                              decoration: const InputDecoration(),
                              dropdownColor: AppColors.cardSurface,
                              style: AppTypography.body(fontSize: 16),
                              items: _limits.map((limit) {
                                return DropdownMenuItem(
                                  value: limit,
                                  child: Text('daily limit: $limit'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedDailyLimit = val);
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Save Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate() &&
                                      _selectedGrade != null) {
                                    final studentData = {
                                      'first_name': _firstNameController.text
                                          .trim(),
                                      'last_name': _lastNameController.text
                                          .trim(),
                                      'username': _usernameController.text
                                          .trim(),
                                      'grade': _selectedGrade,
                                      'daily_limit': _selectedDailyLimit,
                                      'avatar_url': _selectedAvatarUrl,
                                    };

                                    if (widget.editStudentData == null) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ConsentScreen(
                                            studentData: studentData,
                                          ),
                                        ),
                                      );
                                    } else {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      final error = await StudentService()
                                          .updateStudent(
                                            widget.editStudentData!['id'],
                                            studentData,
                                          );
                                      if (!mounted) return;
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      if (error != null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(error),
                                            backgroundColor:
                                                AppColors.softCoral,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'student updated successfully!',
                                            ),
                                            backgroundColor:
                                                AppColors.gentleGreen,
                                          ),
                                        );
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ParentAccountScreen(),
                                          ),
                                        );
                                      }
                                    }
                                  } else if (_selectedGrade == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'grade is set to Grade 1',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.calmBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.editStudentData == null
                                      ? 'save changes'
                                      : 'update changes',
                                  style: AppTypography.button(fontSize: 18),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.calmBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.calmBlue,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Parent Hub',
                  style: AppTypography.body(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.calmBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.calmBlue,
                      AppColors.calmBlue.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.calmBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                widget.editStudentData == null ? 'Add Student' : 'Edit Student',
                style: AppTypography.heading(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

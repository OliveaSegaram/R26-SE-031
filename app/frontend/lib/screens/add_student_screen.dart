import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'assessment_screen.dart'; // Navigation after SAVE CHANGES
import '../services/auth_service.dart';
import 'parent_account_screen.dart';

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

  String? _selectedGrade;
  String? _selectedDailyLimit = 'No Limit';
  String _selectedAvatarUrl = 'assets/images/solo_blue.png';

  final List<String> _avatars = [
    'assets/images/solo_blue.png',
    'assets/images/solo_green.png',
    'assets/images/solo_pink.png',
    'assets/images/solo_yellow.png',
  ];

  final List<String> _grades = ['Pre-K', 'Kindergarten', '1st Grade', '2nd Grade', '3rd Grade', '4th Grade', '5th Grade', '6th Grade', '7th Grade', '8th Grade'];
  final List<String> _limits = ['No Limit', '15 minutes', '30 minutes', '45 minutes', '1 hour', '1.5 hours', '2 hours'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editStudentData != null) {
      _firstNameController.text = widget.editStudentData!['first_name'] ?? '';
      _lastNameController.text = widget.editStudentData!['last_name'] ?? '';
      _usernameController.text = widget.editStudentData!['username'] ?? '';
      _selectedGrade = widget.editStudentData!['grade'];
      _selectedDailyLimit = widget.editStudentData!['daily_limit'] ?? 'No Limit';
      _selectedAvatarUrl = widget.editStudentData!['avatar_url'] ?? 'assets/images/solo_blue.png';
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.editStudentData == null ? 'Add a student' : 'Edit student',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.editStudentData != null) ...[
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.darkSlateLight,
                        backgroundImage: AssetImage(_selectedAvatarUrl),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Editing ${widget.editStudentData!['first_name']}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ] else ...[
                Text(
                  'Add an additional student for free. You are allowed to add up to 5 children to your account.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 32),
              ],
              
              Text(
                widget.editStudentData == null ? 'New Student Information' : 'Student Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.mint,
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Choose a Monster Profile Picture',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _avatars.map((url) {
                    final isSelected = _selectedAvatarUrl == url;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatarUrl = url),
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.mint : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.darkSlateLight,
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
                  color: AppColors.darkSlateLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.mint.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        hintText: 'Student First Name',
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        hintText: 'Student Last Name',
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        hintText: 'Student Username (login)',
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedGrade,
                      hint: const Text('Student Grade'),
                      decoration: const InputDecoration(),
                      dropdownColor: AppColors.darkSlate,
                      style: const TextStyle(color: Colors.white),
                      items: _grades.map((grade) {
                        return DropdownMenuItem(
                          value: grade,
                          child: Text(grade),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedGrade = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedDailyLimit,
                      decoration: const InputDecoration(),
                      dropdownColor: AppColors.darkSlate,
                      style: const TextStyle(color: Colors.white),
                      items: _limits.map((limit) {
                        return DropdownMenuItem(
                          value: limit,
                          child: Text('Daily Limit: $limit'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedDailyLimit = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'AdaptedMind Parent Account Password',
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Save Changes Button
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (_formKey.currentState!.validate() && _selectedGrade != null) {
                      final studentData = {
                        'first_name': _firstNameController.text.trim(),
                        'last_name': _lastNameController.text.trim(),
                        'username': _usernameController.text.trim(),
                        'grade': _selectedGrade,
                        'daily_limit': _selectedDailyLimit,
                        'parent_password': _passwordController.text,
                        'avatar_url': _selectedAvatarUrl,
                      };

                      if (widget.editStudentData == null) {
                        setState(() { _isLoading = true; });
                        final pwdError = await AuthService().verifyPassword(_passwordController.text);
                        if (!mounted) return;
                        setState(() { _isLoading = false; });
                        
                        if (pwdError != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pwdError), backgroundColor: Colors.red));
                          return;
                        }

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssessmentScreen(studentData: studentData),
                          ),
                        );
                      } else {
                        setState(() { _isLoading = true; });
                        final error = await AuthService().updateStudent(
                          widget.editStudentData!['id'], 
                          studentData
                        );
                        if (!mounted) return;
                        setState(() { _isLoading = false; });
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student updated successfully!'), backgroundColor: Colors.green));
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ParentAccountScreen(),
                            ),
                          );
                        }
                      }
                    } else if (_selectedGrade == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a grade')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        widget.editStudentData == null ? 'SAVE CHANGES' : 'UPDATE CHANGES',
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

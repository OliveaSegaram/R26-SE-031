import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'assessment_screen.dart'; // Navigation after SAVE CHANGES

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedGrade;
  String? _selectedDailyLimit = 'No Limit';

  final List<String> _grades = ['Pre-K', 'Kindergarten', '1st Grade', '2nd Grade', '3rd Grade', '4th Grade', '5th Grade', '6th Grade', '7th Grade', '8th Grade'];
  final List<String> _limits = ['No Limit', '15 minutes', '30 minutes', '45 minutes', '1 hour', '1.5 hours', '2 hours'];

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
          'Add a student',
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
              Text(
                'Add an additional student for free. You are allowed to add up to 5 children to your account.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'New Student Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.mint,
                ),
              ),
              const SizedBox(height: 24),

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
                      decoration: const InputDecoration(
                        hintText: 'Student First Name',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Student Last Name',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Student Username (login)',
                      ),
                      style: const TextStyle(color: Colors.white),
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
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'AdaptedMind Parent Account Password',
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Save Changes Button
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: () {
                    // In a real app, validate and save here
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AssessmentScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'SAVE CHANGES',
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

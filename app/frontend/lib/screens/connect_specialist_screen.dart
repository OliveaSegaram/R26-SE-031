import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../services/student_service.dart';
import 'consent_specialist_screen.dart';

class ConnectSpecialistScreen extends StatefulWidget {
  const ConnectSpecialistScreen({super.key});

  @override
  State<ConnectSpecialistScreen> createState() => _ConnectSpecialistScreenState();
}

class _ConnectSpecialistScreenState extends State<ConnectSpecialistScreen> {
  final _codeController = TextEditingController();
  List<dynamic> _students = [];
  String? _selectedStudentId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final students = await StudentService().getStudents();
    if (mounted) {
      setState(() {
        _students = students;
        if (_students.isNotEmpty) {
          _selectedStudentId = _students.first['_id'];
        }
        _isLoading = false;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'connect specialist',
          style: AppTypography.heading(fontSize: 22, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "link your child's account to their therapist or reading specialist.",
                    style: AppTypography.body(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  
                  Text('clinic code', style: AppTypography.heading(fontSize: 18, color: AppColors.calmBlue)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _codeController,
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    style: AppTypography.heading(fontSize: 24).copyWith(letterSpacing: 8),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'XXXXXX',
                      hintStyle: AppTypography.heading(fontSize: 24, color: AppColors.textSecondary.withValues(alpha: 0.5)).copyWith(letterSpacing: 8),
                      filled: true,
                      fillColor: AppColors.cardSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (_students.isNotEmpty) ...[
                    Text('select child', style: AppTypography.heading(fontSize: 18, color: AppColors.calmBlue)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStudentId,
                          isExpanded: true,
                          items: _students.map((student) {
                            return DropdownMenuItem<String>(
                              value: student['_id'],
                              child: Text(student['first_name'], style: AppTypography.body(fontSize: 16)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedStudentId = val),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 48),
                  
                  GradientButton(
                    text: 'continue to consent',
                    icon: Icons.shield_rounded,
                    onPressed: () {
                      if (_codeController.text.trim().length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('please enter a valid 6-digit clinic code')),
                        );
                        return;
                      }
                      if (_selectedStudentId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('please select a child')),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConsentSpecialistScreen(
                            clinicCode: _codeController.text.trim().toUpperCase(),
                            studentId: _selectedStudentId!,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

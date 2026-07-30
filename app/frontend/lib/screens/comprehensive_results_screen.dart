import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/comprehensive_assessment_questions.dart';
import '../services/student_service.dart';

class ComprehensiveResultsScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const ComprehensiveResultsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ComprehensiveResultsScreen> createState() => _ComprehensiveResultsScreenState();
}

class _ComprehensiveResultsScreenState extends State<ComprehensiveResultsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final students = await StudentService().getStudents();
    if (mounted) {
      setState(() {
        try {
          _studentData = students.firstWhere((s) => s['id'] == widget.studentId);
        } catch (_) {
          _studentData = null;
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
        title: Text('${widget.studentName} ගේ ප්‍රතිඵල', style: AppTypography.heading(fontSize: 20, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.calmBlue))
          : _studentData == null
              ? const Center(child: Text('Student not found'))
              : _buildResultsList(),
    );
  }

  Widget _buildResultsList() {
    final results = _studentData!['comprehensive_assessment_results'] as Map<String, dynamic>? ?? {};

    if (results.isEmpty) {
      return Center(
        child: Text(
          'කිසිදු පරීක්ෂණයක් සම්පූර්ණ කර නොමැත.',
          style: AppTypography.body(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (results.containsKey('basic')) _buildCategorySection('basic', results['basic']),
        if (results.containsKey('reading')) _buildCategorySection('reading', results['reading']),
        if (results.containsKey('writing')) _buildCategorySection('writing', results['writing']),
        if (results.containsKey('other')) _buildCategorySection('other', results['other']),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<dynamic> answers) {
    final title = ComprehensiveAssessmentData.getCategoryTitle(category);
    final questions = ComprehensiveAssessmentData.getQuestionsByCategory(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.calmBlue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Text(
              title,
              style: AppTypography.heading(fontSize: 16, color: AppColors.calmBlueDark),
            ),
          ),
          ...List.generate(answers.length, (index) {
            final isYes = answers[index] == true;
            final qText = index < questions.length ? questions[index].text : 'Unknown question';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.5))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${index + 1}. $qText',
                      style: AppTypography.body(fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isYes ? AppColors.gentleGreen.withValues(alpha: 0.2) : AppColors.softCoral.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isYes ? 'ඔව්' : 'නැත',
                      style: AppTypography.caption(
                        fontWeight: FontWeight.bold,
                        color: isYes ? AppColors.gentleGreenDark : AppColors.softCoralDark,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

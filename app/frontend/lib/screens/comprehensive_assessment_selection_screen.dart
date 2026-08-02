import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'comprehensive_assessment_screen.dart';

class ComprehensiveAssessmentSelectionScreen extends StatelessWidget {
  final String studentId;
  final String studentName;

  const ComprehensiveAssessmentSelectionScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Screening Categories',
          style: AppTypography.heading(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'student: $studentName',
                style: AppTypography.caption(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.calmBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please select an assessment category to begin the screening process.',
                style: AppTypography.body(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              _buildAssessmentCategoryCard(
                context, 
                'basic', 
                'මූලික ඩිස්ලෙක්සියා පරීක්ෂණය', 
                Icons.psychology_rounded
              ),
              _buildAssessmentCategoryCard(
                context, 
                'reading', 
                'කියවීම හා දෘශ්‍ය සංජානන අපහසුතා', 
                Icons.menu_book_rounded
              ),
              _buildAssessmentCategoryCard(
                context, 
                'writing', 
                'ලිවීම සම්බන්ධ අපහසුතා', 
                Icons.edit_rounded
              ),
              _buildAssessmentCategoryCard(
                context, 
                'other', 
                'වෙනත් සම්බන්ධ අපහසුතා', 
                Icons.more_horiz_rounded
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentCategoryCard(
    BuildContext context, 
    String category, 
    String title, 
    IconData icon
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ComprehensiveAssessmentScreen(
                  studentId: studentId,
                  category: category,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight, width: 1.5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.calmBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.calmBlue, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.body(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600, 
                      color: AppColors.textPrimary
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded, 
                  color: AppColors.textHint, 
                  size: 16
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

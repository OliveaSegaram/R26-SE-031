import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      backgroundColor: const Color(0xFFF8FAFC), // Clean, premium slate-white background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant Sliver App Bar
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 22),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE0F2FE), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Student Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.calmBlue.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.calmBlue.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.child_care_rounded, size: 16, color: AppColors.calmBlue),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            studentName,
                            style: AppTypography.caption(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Assessment Profile',
                      style: AppTypography.heading(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select an area to evaluate.',
                      style: AppTypography.body(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          
          // Cards List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPremiumCategoryCard(
                  context: context, 
                  category: 'basic', 
                  title: 'මූලික ඩිස්ලෙක්සියා පරීක්ෂණය', 
                  subtitle: 'Basic Dyslexia Evaluation',
                  icon: Icons.psychology_rounded,
                  gradient: AppColors.blueButtonGradient,
                ),
                _buildPremiumCategoryCard(
                  context: context, 
                  category: 'reading', 
                  title: 'කියවීම හා දෘශ්‍ය සංජානන අපහසුතා', 
                  subtitle: 'Reading & Visual Perception',
                  icon: Icons.menu_book_rounded,
                  gradient: AppColors.greenGradient,
                ),
                _buildPremiumCategoryCard(
                  context: context, 
                  category: 'writing', 
                  title: 'ලිවීම සම්බන්ධ අපහසුතා', 
                  subtitle: 'Writing Difficulties',
                  icon: Icons.edit_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                _buildPremiumCategoryCard(
                  context: context, 
                  category: 'other', 
                  title: 'වෙනත් සම්බන්ධ අපහසුතා', 
                  subtitle: 'Other Related Difficulties',
                  icon: Icons.more_horiz_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                const SizedBox(height: 40), // Bottom padding
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCategoryCard({
    required BuildContext context, 
    required String category, 
    required String title, 
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          highlightColor: Colors.black.withValues(alpha: 0.02),
          splashColor: Colors.black.withValues(alpha: 0.04),
          onTap: () {
            HapticFeedback.lightImpact();
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Glowing Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 20),
                
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.body(
                          fontSize: 15, 
                          fontWeight: FontWeight.w700, 
                          color: AppColors.textPrimary
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.caption(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Chevron
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded, 
                    color: AppColors.textSecondary, 
                    size: 14
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

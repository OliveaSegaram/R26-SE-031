import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'level_map_screen.dart';
import 'select_student_screen.dart';
import 'parent_account_screen.dart';

/// Dashboard Screen
/// Dyslexia-accessible: crème bg, warm white skill cards, gentle green progress,
/// calm blue accents, 16pt+ Sinhala text.
class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? studentData;

  const DashboardScreen({super.key, this.studentData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedTabIndex = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'all skills', 'icon': Icons.apps_rounded},
    {'label': 'visual', 'icon': Icons.visibility_rounded},
    {'label': 'auditory', 'icon': Icons.hearing_rounded},
    {'label': 'reading', 'icon': Icons.menu_book_rounded},
    {'label': 'writing', 'icon': Icons.edit_rounded},
  ];

  final List<Map<String, dynamic>> _skills = [
    {
      'title': 'හැඩ හඳුනාගැනීම',
      'subtitle': 'shape recognition',
      'icon': 'assets/images/category_visual.png',
      'progress': 0.45,
      'category': 'visual',
      'color': AppColors.calmBlue,
      'isNew': true,
    },
    {
      'title': 'වර්ණ වර්ගීකරණය',
      'subtitle': 'color classification',
      'icon': 'assets/images/category_reading.png',
      'progress': 0.70,
      'category': 'visual',
      'color': AppColors.gentleGreen,
      'isNew': false,
    },
    {
      'title': 'ශබ්ද හඳුනාගැනීම',
      'subtitle': 'sound recognition',
      'icon': 'assets/images/category_auditory.png',
      'progress': 0.30,
      'category': 'auditory',
      'color': AppColors.warmAmber,
      'isNew': true,
    },
    {
      'title': 'අකුරු කියවීම',
      'subtitle': 'letter reading',
      'icon': 'assets/images/category_reading.png',
      'progress': 0.15,
      'category': 'reading',
      'color': AppColors.softCoral,
      'isNew': false,
    },
    {
      'title': 'රටා ගැලපීම',
      'subtitle': 'pattern matching',
      'icon': 'assets/images/category_visual.png',
      'progress': 0.55,
      'category': 'visual',
      'color': AppColors.calmBlue,
      'isNew': false,
    },
    {
      'title': 'වචන ලිවීම',
      'subtitle': 'word writing',
      'icon': 'assets/images/category_writing.png',
      'progress': 0.0,
      'category': 'writing',
      'color': AppColors.gentleGreen,
      'isNew': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredSkills {
    if (_selectedTabIndex == 0) return _skills;
    final category = _categories[_selectedTabIndex]['label'] as String;
    return _skills.where((s) => s['category'] == category).toList();
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.studentData?['first_name'] ?? 'learner';
    final avatarUrl = widget.studentData?['avatar_url'] ?? 'assets/images/solo_blue.png';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(studentName, avatarUrl),

              const SizedBox(height: 16),

              // Welcome message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'hello, $studentName!',
                      style: AppTypography.heading(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "let's continue learning today",
                      style: AppTypography.body(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Category tabs
              _buildCategoryTabs(),

              const SizedBox(height: 16),

              // Skill cards grid
              Expanded(
                child: _buildSkillsGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String avatarUrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        children: [
          // Back to student select
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SelectStudentScreen()),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          const Spacer(),
          // Avatar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ParentAccountScreen()),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.calmBlue, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.calmBlue.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(avatarUrl, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          final category = _categories[index];

          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.calmBlue : AppColors.cardSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppColors.calmBlue : AppColors.borderLight,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.calmBlue.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category['label'] as String,
                    style: AppTypography.caption(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkillsGrid() {
    final skills = _filteredSkills;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return _buildSkillCard(skill);
      },
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> skill) {
    final color = skill['color'] as Color;
    final progress = skill['progress'] as double;
    final isNew = skill['isNew'] as bool;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LevelMapScreen(studentData: widget.studentData),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        skill['icon'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.auto_awesome_rounded,
                          color: color,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sinhala title
                  Text(
                    skill['title'] as String,
                    style: AppTypography.sinhala(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // English subtitle
                  Text(
                    skill['subtitle'] as String,
                    style: AppTypography.caption(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const Spacer(),

                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.borderLight,
                            color: color,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).round()}%',
                        style: AppTypography.caption(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // "new" badge
            if (isNew)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warmAmber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'new',
                    style: AppTypography.caption(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

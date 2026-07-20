import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'level_map_screen.dart';
import 'select_student_screen.dart';
import 'parent_account_screen.dart';

/// Dashboard Screen
/// Dyslexia-accessible: crème bg, warm white skill cards, gentle green progress,
/// calm blue accents, 16pt+ text.
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

  // The 10 Phonological Skills defined for early literacy
  final List<Map<String, dynamic>> _skills = [
    {
      'title': 'Shape Recognition',
      'icon': 'assets/images/skills/s0.png',
      'progress': 0.85,
      'category': 'visual',
      'color': AppColors.calmBlue,
    },
    {
      'title': 'Vowel Identification',
      'icon': 'assets/images/skills/s1.png',
      'progress': 0.70,
      'category': 'visual',
      'color': AppColors.gentleGreen,
    },
    {
      'title': 'Consonant Recognition',
      'icon': 'assets/images/skills/s2.png',
      'progress': 0.60,
      'category': 'visual',
      'color': AppColors.warmAmber,
    },
    {
      'title': 'Syllable Formation',
      'icon': 'assets/images/skills/s3.png',
      'progress': 0.40,
      'category': 'visual',
      'color': AppColors.softCoral,
    },
    {
      'title': 'Simple Word Reading',
      'icon': 'assets/images/skills/s4.png',
      'progress': 0.20,
      'category': 'reading',
      'color': AppColors.calmBlue,
    },
    {
      'title': 'Reading "Hal" Letters',
      'icon': 'assets/images/skills/s5.png',
      'progress': 0.10,
      'category': 'reading',
      'color': AppColors.gentleGreen,
    },
    {
      'title': 'Words with Modifiers',
      'icon': 'assets/images/skills/s6.png',
      'progress': 0.0,
      'category': 'reading',
      'color': AppColors.warmAmber,
    },
    {
      'title': 'Complex & Conjunct Words',
      'icon': 'assets/images/skills/s7.png',
      'progress': 0.0,
      'category': 'reading',
      'color': AppColors.softCoral,
    },
    {
      'title': 'Sentence Reading',
      'icon': 'assets/images/skills/s8.png',
      'progress': 0.0,
      'category': 'reading',
      'color': AppColors.calmBlue,
    },
    {
      'title': 'Reading Comprehension',
      'icon': 'assets/images/skills/s9.png',
      'progress': 0.0,
      'category': 'reading',
      'color': AppColors.gentleGreen,
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
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82, // Optimized ratio for hero-image style cards
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return _buildHeroSkillCard(skill);
      },
    );
  }

  // New highly visual "Hero Image" card layout
  Widget _buildHeroSkillCard(Map<String, dynamic> skill) {
    final color = skill['color'] as Color;
    final progress = skill['progress'] as double;

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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Half: Custom Hero Image
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: Image.asset(
                  skill['icon'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: color.withValues(alpha: 0.1),
                    child: Icon(Icons.auto_awesome_rounded, color: color, size: 40),
                  ),
                ),
              ),
            ),
            
            // Bottom Half: English Title and Progress Bar
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      skill['title'] as String,
                      style: AppTypography.heading(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Progress Indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'progress',
                              style: AppTypography.caption(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: AppTypography.caption(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.borderLight,
                            color: color,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

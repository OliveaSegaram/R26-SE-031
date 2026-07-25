import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import 'level_map_screen.dart';
import 'select_student_screen.dart';
import 'parent/parent_hub_screen.dart';
import 'character_shop_screen.dart';
import '../models/curriculum_models.dart';
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
  
  // Navigation State
  int _navIndex = 0; // 0: Home, 1: Shop, 2: Progress, 3: Settings

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _navItems = [
    {'label': 'home', 'icon': FontAwesomeIcons.houseChimney, 'color': AppColors.calmBlue},
    {'label': 'shop', 'icon': FontAwesomeIcons.store, 'color': AppColors.softCoral},
    {'label': 'progress', 'icon': FontAwesomeIcons.trophy, 'color': AppColors.warmAmber},
    {'label': 'parents', 'icon': FontAwesomeIcons.userGroup, 'color': AppColors.gentleGreen},
  ];

  CurriculumIndex? _curriculum;

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
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    try {
      final data = await CurriculumIndex.load();
      if (mounted) setState(() => _curriculum = data);
    } catch (e) {
      print('Error loading curriculum: $e');
    }
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
              // Header (Avatar Profile + Welcome Message perfectly aligned)
              _buildHeader(studentName, avatarUrl),

              const SizedBox(height: 24),

              // Custom Top Navigation Bar (replaces the old category filters)
              _buildTopNavBar(),

              const SizedBox(height: 24),

              // Skill cards grid
              Expanded(
                child: _curriculum == null 
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSkillsGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String avatarUrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Side: Welcome Text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'hello, $name!',
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
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          
          // Right Side: Avatar Profile
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SelectStudentScreen()),
              );
            },
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.calmBlue, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.calmBlue.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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

  Widget _buildTopNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_navItems.length, (index) {
          final item = _navItems[index];
          final isSelected = _navIndex == index;
          final color = item['color'] as Color;

          return GestureDetector(
            onTap: () {
              setState(() => _navIndex = index);
              
              // Handle Navigation Actions
              Future.delayed(const Duration(milliseconds: 200), () {
                if (!mounted) return;
                
                if (index == 3) { // Settings routes to Parent Screen
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentHubScreen()));
                  setState(() => _navIndex = 0);
                } else if (index == 1) { // Shop routes to Character Shop
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CharacterShopScreen()));
                  setState(() => _navIndex = 0);
                } else if (index != 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item['label']} coming soon!'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  setState(() => _navIndex = 0);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              width: 78,
              height: 84,
              margin: EdgeInsets.only(
                top: isSelected ? 4 : 8,
                bottom: isSelected ? 12 : 8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.cardSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? color : AppColors.borderLight,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    item['icon'],
                    size: 28,
                    color: isSelected ? Colors.white : color.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['label'] as String,
                    style: AppTypography.caption(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSkillsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: _curriculum!.skills.length,
      itemBuilder: (context, index) {
        final skill = _curriculum!.skills[index];
        // Cycle colors for MVP aesthetics
        final colors = [AppColors.calmBlue, AppColors.gentleGreen, AppColors.warmAmber, AppColors.softCoral];
        return _buildHeroSkillCard(skill, colors[index % colors.length]);
      },
    );
  }

  // Highly visual "Hero Image" card layout
  Widget _buildHeroSkillCard(SkillSummary skill, Color color) {
    // Dummy progress for now
    final progress = 0.5;

    return GestureDetector(
      onTap: () async {
        try {
          final skillDetail = await SkillDetail.load(skill.file);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LevelMapScreen(
                skillMap: skillDetail,
                studentData: widget.studentData,
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load ${skill.title}: $e')));
        }
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
                  'assets/images/skills/s0.png', // Hardcoded fallback for now
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
                      skill.title,
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

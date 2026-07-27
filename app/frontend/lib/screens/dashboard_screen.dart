import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import 'level_map_screen.dart';
import 'select_student_screen.dart';
import 'parent/parent_hub_screen.dart';
import 'character_shop_screen.dart';
import 'progress_analytics_screen.dart';
import '../models/curriculum_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
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
                } else if (index == 2) { // Progress routes to Analytics Screen
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProgressAnalyticsScreen(studentData: widget.studentData)));
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _curriculum!.skills.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final skill = _curriculum!.skills[index];
        // Cycle colors for MVP aesthetics
        final colors = [AppColors.calmBlue, AppColors.gentleGreen, AppColors.warmAmber, AppColors.softCoral];
        return _AnimatedSkillCard(
          skill: skill,
          color: colors[index % colors.length],
          imagePath: 'assets/images/skills/s${index % 10}.png',
          studentData: widget.studentData,
          onReturn: () {
            if (mounted) setState(() {});
          },
        );
      },
    );
  }
}

class _AnimatedSkillCard extends StatefulWidget {
  final SkillSummary skill;
  final Color color;
  final String imagePath;
  final Map<String, dynamic>? studentData;
  final VoidCallback onReturn;

  const _AnimatedSkillCard({
    required this.skill,
    required this.color,
    required this.imagePath,
    this.studentData,
    required this.onReturn,
  });

  @override
  State<_AnimatedSkillCard> createState() => _AnimatedSkillCardState();
}

class _AnimatedSkillCardState extends State<_AnimatedSkillCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService().getSkillProgress(widget.skill.id, widget.skill.totalActivities);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () async {
          try {
            final skillDetail = await SkillDetail.load(widget.skill.file);
            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LevelMapScreen(
                  skillMap: skillDetail,
                  studentData: widget.studentData,
                ),
              ),
            );
            widget.onReturn();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load ${widget.skill.title}: $e')));
          }
        },
        child: Container(
          height: 140, // Generous height for child friendly layout
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.color.withValues(alpha: 0.3), width: 3),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Half: Large Hero Image
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(21)),
                  child: Image.asset(
                    widget.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: widget.color.withValues(alpha: 0.1),
                      child: Icon(Icons.auto_awesome_rounded, color: widget.color, size: 50),
                    ),
                  ),
                ),
              ),
              
              // Right Half: Details, Audio, and Progress
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title and Speaker Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.skill.title,
                              style: AppTypography.heading(
                                fontSize: 18, // Larger font
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              TtsService().speak(widget.skill.title);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8), // Larger tap target
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.volume_up_rounded,
                                color: widget.color,
                                size: 24, // Larger icon
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Progress Bar Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: AppTypography.caption(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${(progress * 100).round()}%',
                                style: AppTypography.caption(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: widget.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.borderLight,
                              color: widget.color,
                              minHeight: 12, // Thicker progress bar
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
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../models/dashboard_config.dart';
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
  int _streak = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  DashboardConfig? _dashConfig;

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
    _loadStreak();
    _loadDashConfig();
  }

  Future<void> _loadCurriculum() async {
    try {
      final data = await CurriculumIndex.load();
      if (mounted) setState(() => _curriculum = data);
    } catch (e) {
      print('Error loading curriculum: $e');
    }
  }

  Future<void> _loadStreak() async {
    final streak = await ProgressService().updateAndGetStreak();
    if (mounted) setState(() => _streak = streak);
  }

  Future<void> _loadDashConfig() async {
    try {
      final config = await DashboardConfig.load();
      if (mounted) setState(() => _dashConfig = config);
    } catch (e) {
      print('Error loading dashboard config: $e');
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
    final config = _dashConfig;
    final hour = DateTime.now().hour;
    final greeting = config != null
        ? config.greetingFor(hour, name)
        : (hour < 12 ? 'Good morning, $name! ☀️' : hour < 17 ? 'Good afternoon, $name! 🌤️' : 'Good evening, $name! 🌙');
    final subtitle = config != null
        ? config.subtitleFor(_streak)
        : (_streak > 1 ? '🔥 $_streak day streak! Keep going!' : 'Ready to earn some stars? ⭐');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Side: Dynamic greeting + motivational subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTypography.heading(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.body(
                    fontSize: 14,
                    color: _streak > 1 ? AppColors.softCoral : AppColors.textSecondary,
                    fontWeight: _streak > 1 ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          // Right Side: Streak badge + Avatar
          Row(
            children: [
              if (_streak > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warmAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.warmAmber.withValues(alpha: 0.4),
                        width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '$_streak',
                        style: AppTypography.heading(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.warmAmber,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SelectStudentScreen()),
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
    final config = _dashConfig;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _curriculum!.skills.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final skill = _curriculum!.skills[index];

        // Lock state: first skill always unlocked; subsequent unlock when previous has progress
        bool isLocked = false;
        if (index > 0) {
          final prevSkill = _curriculum!.skills[index - 1];
          final prevCompleted = ProgressService().getCompletedActivitiesCount(prevSkill.id);
          isLocked = prevCompleted == 0;
        }

        return _AnimatedSkillCard(
          skill: skill,
          // color and image come from JSON via the model — no more hardcoded cycling
          color: skill.color,
          imagePath: skill.imagePath,
          studentData: widget.studentData,
          isLocked: isLocked,
          dashConfig: config,
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
  final bool isLocked;
  final DashboardConfig? dashConfig;
  final VoidCallback onReturn;

  const _AnimatedSkillCard({
    required this.skill,
    required this.color,
    required this.imagePath,
    this.studentData,
    required this.isLocked,
    this.dashConfig,
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
    final cfg = widget.dashConfig;
    final maxStars = cfg?.progress.maxStars ?? 5;
    final progress = ProgressService().getSkillProgress(widget.skill.id, widget.skill.totalActivities);
    final filledStars = (progress * maxStars).round();
    final lockedSnackbarText = cfg?.lockedSnackbar ?? '🔒 Complete the previous skill first!';
    final labelNotStarted = cfg?.progress.labelNotStarted ?? 'tap to start! 👆';
    final labelInProgress = cfg?.progress.labelInProgress ?? 'your stars ⭐';
    final labelLocked = cfg?.progress.labelLocked ?? 'locked 🔒';

    final cardContent = Container(
      height: 140,
      decoration: BoxDecoration(
        color: widget.isLocked
            ? AppColors.cardSurface.withValues(alpha: 0.6)
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isLocked
              ? AppColors.borderLight
              : widget.color.withValues(alpha: 0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isLocked
                ? AppColors.shadow
                : widget.color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Hero image with greyscale + lock overlay when locked
          Expanded(
            flex: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(21)),
                  child: ColorFiltered(
                    colorFilter: widget.isLocked
                        ? const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0, 0, 0, 1, 0,
                          ])
                        : const ColorFilter.mode(
                            Colors.transparent, BlendMode.multiply),
                    child: Image.asset(
                      widget.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: widget.color.withValues(alpha: 0.1),
                        child: Icon(Icons.auto_awesome_rounded,
                            color: widget.color, size: 50),
                      ),
                    ),
                  ),
                ),
                if (widget.isLocked)
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(21)),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      child: const Center(
                        child: Icon(Icons.lock_rounded,
                            color: Colors.white, size: 34),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Right: Title, audio button, star-based progress
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.skill.title,
                          style: AppTypography.heading(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: widget.isLocked
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!widget.isLocked)
                        GestureDetector(
                          onTap: () => TtsService().speak(widget.skill.title),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.volume_up_rounded,
                                color: widget.color, size: 22),
                          ),
                        ),
                    ],
                  ),

                  // Star-based progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isLocked
                            ? labelLocked
                            : (progress == 0 ? labelNotStarted : labelInProgress),
                        style: AppTypography.caption(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(
                          maxStars,
                          (i) => Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Icon(
                              i < filledStars
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: i < filledStars
                                  ? AppColors.warmAmber
                                  : AppColors.borderLight,
                              size: 24,
                            ),
                          ),
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
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () async {
          if (widget.isLocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(lockedSnackbarText),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
            return;
          }
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
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load ${widget.skill.title}: $e')));
          }
        },
        child: cardContent,
      ),
    );
  }
}

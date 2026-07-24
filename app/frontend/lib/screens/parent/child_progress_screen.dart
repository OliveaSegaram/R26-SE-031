import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import 'skill_detail_progress_screen.dart';

/// Child Progress Screen — Visual dashboard showing a specific child's
/// learning journey: weekly activity chart, overall stats, skill progress.
class ChildProgressScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const ChildProgressScreen({super.key, required this.studentData});

  @override
  State<ChildProgressScreen> createState() => _ChildProgressScreenState();
}

class _ChildProgressScreenState extends State<ChildProgressScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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

  // Mock data for skills
  List<Map<String, dynamic>> get _skills => [
        {
          'name': 'Letter Recognition',
          'icon': FontAwesomeIcons.font,
          'color': AppColors.calmBlue,
          'progress': 0.75,
          'accuracy': 82,
          'levels': '6/8',
          'lastPlayed': 'today',
        },
        {
          'name': 'Vowel Sounds',
          'icon': FontAwesomeIcons.volumeHigh,
          'color': AppColors.gentleGreen,
          'progress': 0.60,
          'accuracy': 78,
          'levels': '3/5',
          'lastPlayed': 'yesterday',
        },
        {
          'name': 'Word Building',
          'icon': FontAwesomeIcons.puzzlePiece,
          'color': AppColors.warmAmber,
          'progress': 0.40,
          'accuracy': 70,
          'levels': '2/5',
          'lastPlayed': '2 days ago',
        },
        {
          'name': 'Shape Tracking',
          'icon': FontAwesomeIcons.shapes,
          'color': AppColors.softCoral,
          'progress': 0.90,
          'accuracy': 92,
          'levels': '9/10',
          'lastPlayed': 'today',
        },
        {
          'name': 'Syllable Training',
          'icon': FontAwesomeIcons.music,
          'color': Colors.purple,
          'progress': 0.30,
          'accuracy': 65,
          'levels': '2/7',
          'lastPlayed': '3 days ago',
        },
      ];

  // Mock weekly data (minutes per day: Mon–Sun)
  final List<double> _weeklyMinutes = [25, 15, 30, 0, 20, 35, 10];
  final List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final name = widget.studentData['first_name'] ?? 'student';
    final grade = widget.studentData['grade'] ?? 'n/a';
    final avatar =
        widget.studentData['avatar_url'] ?? 'assets/images/solo_blue.png';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(name, grade, avatar),
                const SizedBox(height: 24),
                _buildOverallStats(),
                const SizedBox(height: 24),
                _buildWeeklyChart(),
                const SizedBox(height: 24),
                _buildSkillProgressSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(String name, String grade, String avatar) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.calmBlue.withValues(alpha: 0.08),
            AppColors.cream,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          // Child avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.calmBlue, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(avatar, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          // Name and grade
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$name's progress",
                  style: AppTypography.heading(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  grade,
                  style: AppTypography.caption(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Overall Stats ───
  Widget _buildOverallStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildMiniStat(FontAwesomeIcons.gamepad, '47', 'activities',
              AppColors.calmBlue),
          const SizedBox(width: 10),
          _buildMiniStat(FontAwesomeIcons.bullseye, '78%', 'accuracy',
              AppColors.gentleGreen),
          const SizedBox(width: 10),
          _buildMiniStat(FontAwesomeIcons.fire, '5', 'day streak',
              AppColors.warmAmber),
          const SizedBox(width: 10),
          _buildMiniStat(FontAwesomeIcons.star, '124', 'stars',
              AppColors.softCoral),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      dynamic icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            FaIcon(icon, size: 16, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.heading(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: AppTypography.caption(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Weekly Activity Chart ───
  Widget _buildWeeklyChart() {
    final maxMinutes =
        _weeklyMinutes.reduce((a, b) => a > b ? a : b).clamp(1, 999);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'weekly activity',
                  style: AppTypography.heading(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gentleGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_weeklyMinutes.reduce((a, b) => a + b).round()} min total',
                    style: AppTypography.caption(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gentleGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final height =
                      (_weeklyMinutes[index] / maxMinutes) * 110;
                  final isToday = index == DateTime.now().weekday - 1;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${_weeklyMinutes[index].round()}m',
                            style: AppTypography.caption(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isToday
                                  ? AppColors.calmBlue
                                  : AppColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            height: max(height, 4),
                            decoration: BoxDecoration(
                              gradient: isToday
                                  ? AppColors.blueButtonGradient
                                  : LinearGradient(
                                      colors: [
                                        AppColors.borderLight,
                                        AppColors.calmBlue
                                            .withValues(alpha: 0.3),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dayLabels[index],
                            style: AppTypography.caption(
                              fontSize: 12,
                              fontWeight: isToday
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isToday
                                  ? AppColors.calmBlue
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Skill Progress Section ───
  Widget _buildSkillProgressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'skill progress',
            style: AppTypography.heading(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.calmBlue,
            ),
          ),
          const SizedBox(height: 16),
          ..._skills.map((skill) => _buildSkillRow(skill)),
        ],
      ),
    );
  }

  Widget _buildSkillRow(Map<String, dynamic> skill) {
    final color = skill['color'] as Color;
    final progress = skill['progress'] as double;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SkillDetailProgressScreen(
              skillName: skill['name'] as String,
              skillColor: color,
              skillIcon: skill['icon'] as dynamic,
              studentData: widget.studentData,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Skill icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: FaIcon(skill['icon'] as dynamic,
                    size: 20, color: color),
              ),
            ),
            const SizedBox(width: 14),
            // Skill info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        skill['name'] as String,
                        style: AppTypography.body(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${skill['accuracy']}%',
                        style: AppTypography.caption(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.borderLight,
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'levels: ${skill['levels']}',
                        style: AppTypography.caption(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      Text(
                        'last: ${skill['lastPlayed']}',
                        style: AppTypography.caption(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Arrow
            FaIcon(FontAwesomeIcons.chevronRight,
                size: 12, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

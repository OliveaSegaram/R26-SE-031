import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/student_service.dart';
import 'child_progress_screen.dart';
import 'therapist_management_screen.dart';
import 'notifications_screen.dart';
import 'parent_settings_screen.dart';

/// Parent Hub Screen — The heart of the parent experience.
/// A beautifully designed central dashboard showing children overview,
/// quick stats, and navigation to all parent features.
class ParentHubScreen extends StatefulWidget {
  const ParentHubScreen({super.key});

  @override
  State<ParentHubScreen> createState() => _ParentHubScreenState();
}

class _ParentHubScreenState extends State<ParentHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  String _parentName = '';
  List<dynamic> _students = [];

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
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await AuthService().getUserProfile();
    final students = await StudentService().getStudents();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _parentName = profile?['name'] ?? 'parent';
        _students = students;
      });
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.calmBlue))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildQuickStats(),
                      const SizedBox(height: 28),
                      _buildNavigationGrid(),
                      const SizedBox(height: 28),
                      _buildChildrenSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ─── Header ───
  Widget _buildHeader() {
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
                boxShadow: [
                  BoxShadow(
                    color: AppColors.calmBlueDark.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          // Welcome text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'parent hub',
                  style: AppTypography.caption(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.calmBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'hello, $_parentName!',
                  style: AppTypography.heading(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Parent avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.blueButtonGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.calmBlue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _parentName.isNotEmpty ? _parentName[0].toUpperCase() : 'P',
                style: AppTypography.heading(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Stats Row ───
  Widget _buildQuickStats() {
    // Mock data for now
    final int totalChildren = _students.length;
    const int weeklyActivities = 24;
    const int connectedTherapists = 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard(
            icon: FontAwesomeIcons.userGroup,
            value: '$totalChildren',
            label: 'children',
            color: AppColors.calmBlue,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: FontAwesomeIcons.gamepad,
            value: '$weeklyActivities',
            label: 'this week',
            color: AppColors.gentleGreen,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: FontAwesomeIcons.userDoctor,
            value: '$connectedTherapists',
            label: 'therapist',
            color: AppColors.warmAmber,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required dynamic icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: FaIcon(icon, size: 18, color: color),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTypography.heading(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Navigation Grid (4 tiles) ───
  Widget _buildNavigationGrid() {
    final navItems = [
      {
        'icon': FontAwesomeIcons.chartLine,
        'label': 'progress',
        'color': AppColors.calmBlue,
        'bgColor': AppColors.slateBg,
        'onTap': () {
          if (_students.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChildProgressScreen(
                  studentData: _students.first as Map<String, dynamic>,
                ),
              ),
            );
          } else {
            _showSnackBar('add a student first to view progress');
          }
        },
      },
      {
        'icon': FontAwesomeIcons.userDoctor,
        'label': 'therapist',
        'color': AppColors.gentleGreen,
        'bgColor': AppColors.mintBg,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TherapistManagementScreen(),
            ),
          );
        },
      },
      {
        'icon': FontAwesomeIcons.bell,
        'label': 'alerts',
        'color': AppColors.warmAmber,
        'bgColor': const Color(0xFFFFF3E0),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            ),
          );
        },
      },
      {
        'icon': FontAwesomeIcons.gear,
        'label': 'settings',
        'color': AppColors.softCoral,
        'bgColor': const Color(0xFFFDE8E4),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ParentSettingsScreen(),
            ),
          );
        },
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: navItems.map((item) {
          final color = item['color'] as Color;
          final bgColor = item['bgColor'] as Color;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: item['onTap'] as VoidCallback,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: color.withValues(alpha: 0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      FaIcon(item['icon'] as dynamic,
                          size: 24, color: color),
                      const SizedBox(height: 10),
                      Text(
                        item['label'] as String,
                        style: AppTypography.caption(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Children Overview Section ───
  Widget _buildChildrenSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'your children',
            style: AppTypography.heading(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.calmBlue,
            ),
          ),
          const SizedBox(height: 16),
          if (_students.isEmpty)
            _buildEmptyChildrenState()
          else
            ..._students.map((student) =>
                _buildChildCard(student as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _buildEmptyChildrenState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          FaIcon(FontAwesomeIcons.childReaching,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'no students added yet',
            style: AppTypography.body(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'go to settings to add your first student',
            style: AppTypography.caption(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(Map<String, dynamic> student) {
    final name = student['first_name'] ?? 'student';
    final grade = student['grade'] ?? 'n/a';
    final avatar = student['avatar_url'] ?? 'assets/images/solo_blue.png';

    // Mock data
    const int streak = 5;
    const double weeklyProgress = 0.72;
    const String lastActive = 'today';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChildProgressScreen(studentData: student),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Row: Avatar + Name + Grade
            Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.calmBlue, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.calmBlue.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(avatar, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 16),
                // Name + Grade
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTypography.heading(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                // Streak badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warmAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(FontAwesomeIcons.fire,
                          size: 14, color: AppColors.warmAmber),
                      const SizedBox(width: 6),
                      Text(
                        '$streak day streak',
                        style: AppTypography.caption(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warmAmber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'weekly progress',
                      style: AppTypography.caption(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(weeklyProgress * 100).round()}%',
                      style: AppTypography.caption(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gentleGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: weeklyProgress,
                    backgroundColor: AppColors.borderLight,
                    color: AppColors.gentleGreen,
                    minHeight: 8,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Bottom Row: Last active + View button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    FaIcon(FontAwesomeIcons.clock,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Text(
                      'last active: $lastActive',
                      style: AppTypography.caption(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.calmBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'view progress →',
                    style: AppTypography.caption(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.calmBlue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

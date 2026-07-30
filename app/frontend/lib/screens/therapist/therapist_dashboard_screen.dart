import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'therapist_students_screen.dart';
import 'therapist_messages_screen.dart';
import 'therapist_profile_screen.dart';

class TherapistDashboardScreen extends StatefulWidget {
  const TherapistDashboardScreen({super.key});

  @override
  State<TherapistDashboardScreen> createState() =>
      _TherapistDashboardScreenState();
}

class _TherapistDashboardScreenState extends State<TherapistDashboardScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _profile;
  List<dynamic> _connections = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService().getUserProfile();
    final connections = await AuthService().getConnections();
    if (mounted) {
      setState(() {
        _profile = profile;
        _connections = connections;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardHome(
            profile: _profile,
            connections: _connections,
            onProfileTap: () => setState(() => _currentIndex = 3),
          ),
          const TherapistStudentsScreen(),
          const TherapistMessagesScreen(),
          const TherapistProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
          boxShadow: [
            BoxShadow(
              color: AppColors.calmBlueDark.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'home'),
                _buildNavItem(1, Icons.people_outline_rounded, 'students'),
                _buildNavItem(
                  2,
                  Icons.chat_bubble_outline_rounded,
                  'messages',
                  badgeCount: 3,
                ),
                _buildNavItem(3, Icons.person_outline_rounded, 'profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 0) _loadProfile(); // Refresh when switching to home tab
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.calmBlue.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? AppColors.calmBlue : AppColors.textHint,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: 2,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softCoral,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.calmBlue : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Home (Tab 0) ───
class _DashboardHome extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback? onProfileTap;
  final List<dynamic>? connections;
  const _DashboardHome({this.profile, this.onProfileTap, this.connections});

  @override
  Widget build(BuildContext context) {
    final name = profile?['name'] ?? profile?['first_name'] ?? 'Therapist';
    final profilePicUrl = profile?['profile_picture_url'] as String?;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'T';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'good morning,',
                          style: AppTypography.body(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Dr. $name 👋',
                          style: AppTypography.heading(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onProfileTap,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.blueButtonGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.calmBlue.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: profilePicUrl != null && profilePicUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(
                                  profilePicUrl.startsWith('http')
                                      ? profilePicUrl
                                      : 'https://adaptedmind-auth-api.onrender.com$profilePicUrl',
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profilePicUrl == null || profilePicUrl.isEmpty
                          ? Center(
                              child: Text(
                                initials,
                                style: AppTypography.heading(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Simple clean empty state for now
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.dashboard_customize_rounded,
                      size: 64,
                      color: AppColors.textHint.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Your dashboard is ready.",
                      style: AppTypography.heading(
                        fontSize: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Navigate to 'My Students' to view your connections.",
                      style: AppTypography.body(color: AppColors.textHint),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

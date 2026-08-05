import re

with open('lib/screens/therapist/therapist_dashboard_screen.dart', 'r') as f:
    code = f.read()

# 1. Update state class to fetch connections
state_vars = """class _TherapistDashboardScreenState extends State<TherapistDashboardScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _profile;
  List<dynamic> _connections = [];"""
code = code.replace("class _TherapistDashboardScreenState extends State<TherapistDashboardScreen> {\n  int _currentIndex = 0;\n  Map<String, dynamic>? _profile;", state_vars)

load_profile = """  Future<void> _loadProfile() async {
    final profile = await AuthService().getUserProfile();
    final connections = await AuthService().getConnections();
    if (mounted) {
      setState(() {
        _profile = profile;
        _connections = connections;
      });
    }
  }"""
code = re.sub(r'  Future<void> _loadProfile\(\) async \{.*?^  \}', load_profile, code, flags=re.MULTILINE | re.DOTALL)

# Pass connections to _DashboardHome
code = code.replace("_DashboardHome(\n            profile: _profile,", "_DashboardHome(\n            profile: _profile,\n            connections: _connections,")

# 2. Update _DashboardHome to accept connections
dashboard_home_start = """class _DashboardHome extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback? onProfileTap;
  final List<dynamic>? connections;
  const _DashboardHome({super.key, this.profile, this.onProfileTap, this.connections});"""
code = re.sub(r'class _DashboardHome extends StatelessWidget \{.*?const _DashboardHome\(\{super\.key, this\.profile, this\.onProfileTap\}\);', dashboard_home_start, code, flags=re.MULTILINE | re.DOTALL)

# 3. Build a new Assigned Students widget and modify demo widgets
assigned_students_widget = """
              const SizedBox(height: 32),
              Text(
                'assigned students',
                style: AppTypography.heading(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (connections == null || connections!.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.slateBg.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryBorder),
                  ),
                  child: Center(
                    child: Text(
                      'No students assigned yet.',
                      style: AppTypography.body(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...connections!.map((conn) {
                  final studentName = conn['student_name'] ?? 'Unknown Student';
                  final initials = studentName.isNotEmpty ? studentName[0].toUpperCase() : '?';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowColor.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.calmBlue.withValues(alpha: 0.2),
                          child: Text(
                            initials,
                            style: AppTypography.heading(
                              fontSize: 20,
                              color: AppColors.calmBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: AppTypography.heading(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Connected on: ${conn['connected_at'] != null ? conn['connected_at'].split('T')[0] : 'Recently'}',
                                style: AppTypography.caption(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.gentleGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            conn['status'] ?? 'Active',
                            style: AppTypography.caption(
                              color: AppColors.gentleGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
"""

# Insert the Assigned Students widget right after the greeting
code = code.replace("              const SizedBox(height: 24),\n\n              // Quick Stats Row", assigned_students_widget + "\n              const SizedBox(height: 32),\n\n              _buildComingSoonOverlay(\n                child: Column(\n                  crossAxisAlignment: CrossAxisAlignment.start,\n                  children: [\n                    // Quick Stats Row")

# Wrap the rest of the demo sections with a Column inside the new Coming Soon Overlay
end_of_schedule = "              _buildScheduleItem('2:00 PM', 'Nethmi Silva', 'Comprehension', AppColors.warmAmber),\n"
code = code.replace(end_of_schedule, end_of_schedule + "                  ],\n                ),\n              ),\n")

# Provide the _buildComingSoonOverlay method
coming_soon_method = """
  Widget _buildComingSoonOverlay({required Widget child}) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.3,
          child: IgnorePointer(child: child),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.deepBlue.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Coming Soon',
                    style: AppTypography.caption(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
"""
code = code.replace("class _DashboardHome extends StatelessWidget {", "class _DashboardHome extends StatelessWidget {" + coming_soon_method)

with open('lib/screens/therapist/therapist_dashboard_screen.dart', 'w') as f:
    f.write(code)


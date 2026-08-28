import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/parent_dashboard_service.dart';
import '../../utils/avatar_utils.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/trend_chart.dart';

class ChildProgressScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const ChildProgressScreen({super.key, required this.studentData});

  @override
  State<ChildProgressScreen> createState() => _ChildProgressScreenState();
}

class _ChildProgressScreenState extends State<ChildProgressScreen> {
  final ParentDashboardService _dashboardService = ParentDashboardService();
  bool _isLoading = true;
  
  Map<String, dynamic>? _overview;
  Map<String, dynamic>? _skills;
  Map<String, dynamic>? _learningPattern;
  Map<String, dynamic>? _activityHistory;
  String _currentFilter = "limit=10";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final studentId = widget.studentData['id']?.toString() ?? widget.studentData['_id']?.toString();
    if (studentId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final responses = await Future.wait([
      _dashboardService.getOverview(studentId),
      _dashboardService.getSkills(studentId),
      _dashboardService.getLearningPattern(studentId),
      _dashboardService.getActivityHistory(studentId, _currentFilter),
    ]);

    setState(() {
      _overview = responses[0];
      _skills = responses[1];
      _learningPattern = responses[2];
      _activityHistory = responses[3];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.studentData['first_name'] ?? 'student';
    final grade = widget.studentData['grade'] ?? 'Grade 1';
    final avatar = AvatarUtils.getCorrectedAvatarPath(
        widget.studentData['avatar_url'] as String?, 
        'assets/images/characters/human/human_student_1.png');

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: DropdownButton<String>(
                value: _currentFilter,
                underline: const SizedBox(),
                icon: const Icon(Icons.filter_list, color: AppColors.calmBlue),
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != _currentFilter) {
                    setState(() {
                      _currentFilter = newValue;
                      _isLoading = true;
                    });
                    _loadAllData();
                  }
                },
                items: const [
                  DropdownMenuItem(value: "limit=5", child: Text("Last 5 Interactions")),
                  DropdownMenuItem(value: "limit=10", child: Text("Last 10 Interactions")),
                  DropdownMenuItem(value: "limit=20", child: Text("Last 20 Interactions")),
                  DropdownMenuItem(value: "days=7", child: Text("Last 7 Days")),
                  DropdownMenuItem(value: "days=30", child: Text("Last 30 Days")),
                ],
              ),
            ),
          ],
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage(avatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$name - $grade',
                  style: AppTypography.heading(fontSize: 18, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.calmBlue,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.calmBlue,
            tabs: [
              Tab(text: "Overview"),
              Tab(text: "Skills"),
              Tab(text: "Learning Pattern"),
              Tab(text: "Recent Activity"),
              Tab(text: "Reports"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildSkillsTab(),
                  _buildLearningPatternTab(),
                  _buildActivityTab(),
                  _buildReportsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_overview == null) return const Center(child: Text("No Data"));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Quick Summary", style: AppTypography.heading(fontSize: 20)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard("Accuracy", "${_overview!['accuracy']}%", Icons.track_changes_rounded, AppColors.gentleGreen),
              _buildStatCard("Practice Time", "${_overview!['practice_time_minutes']} min", Icons.schedule_rounded, AppColors.calmBlue),
              _buildStatCard("Sessions", "${_overview!['sessions_completed']}", Icons.videogame_asset_rounded, AppColors.softCoral),
              _buildStatCard("Current Skill", _overview!['current_skill'], Icons.star_rounded, AppColors.warmAmber),
            ],
          ),
          const SizedBox(height: 24),
          Text("Behavioral Notes", style: AppTypography.heading(fontSize: 20)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.battery_full_rounded, color: AppColors.calmBlue),
            title: const Text("Fatigue Status"),
            subtitle: Text(_overview!['fatigue_status']),
            tileColor: AppColors.cardSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.bolt_rounded, color: AppColors.warmAmber),
            title: const Text("Response Speed"),
            subtitle: Text(_overview!['response_speed_status']),
            tileColor: AppColors.cardSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsTab() {
    if (_skills == null || _skills!['skills'] == null) return const Center(child: Text("No Data"));
    final List<dynamic> skills = _skills!['skills'];
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return Card(
          color: AppColors.cardSurface,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(skill['skill_name'], style: AppTypography.heading(fontSize: 16)),
                    Text("${skill['mastery_percentage']}%", style: AppTypography.caption(fontWeight: FontWeight.bold, color: AppColors.calmBlue)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: skill['mastery_percentage'] / 100.0,
                  backgroundColor: AppColors.borderLight,
                  color: AppColors.calmBlue,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text("Status: ${skill['status']}", style: AppTypography.caption(color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLearningPatternTab() {
    if (_learningPattern == null) return const Center(child: Text("No Data"));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.calmBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Observed Pattern", style: AppTypography.caption(color: AppColors.calmBlue)),
                const SizedBox(height: 8),
                Text(_learningPattern!['primary_learning_pattern'], style: AppTypography.heading(fontSize: 22, color: AppColors.calmBlue)),
                const SizedBox(height: 4),
                Text("Confidence: ${_learningPattern!['confidence_level']}", style: AppTypography.caption()),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("Supporting Observations", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          ...(_learningPattern!['supporting_observations'] as List<dynamic>).map((obs) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.gentleGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(obs.toString(), style: AppTypography.body())),
              ],
            ),
          )),
          const SizedBox(height: 24),
          Text("Recommended Practice", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              border: Border.all(color: AppColors.warmAmber),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded, color: AppColors.warmAmber),
                const SizedBox(width: 12),
                Expanded(child: Text(_learningPattern!['recommended_practice'], style: AppTypography.body())),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    if (_activityHistory == null || _activityHistory!['history'] == null) return const Center(child: Text("No Data"));
    final List<dynamic> history = _activityHistory!['history'];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TrendChart(
          title: "Practice Accuracy Trend (%)",
          dataPoints: history.map((e) => (e['accuracy'] as num).toDouble()).toList().reversed.toList(),
          lineColor: AppColors.gentleGreen,
          minY: 0,
          maxY: 100,
        ),
        const SizedBox(height: 16),
        Text("Recent Sessions", style: AppTypography.heading(fontSize: 18)),
        const SizedBox(height: 12),
        ...history.map((item) => Card(
          color: AppColors.cardSurface,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.videogame_asset_rounded, color: AppColors.calmBlue),
            title: Text(item['activity_name']),
            subtitle: Text("${item['session_date']} • ${item['duration_minutes']} min"),
            trailing: Text("${item['accuracy']}%", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gentleGreen)),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildReportsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf_rounded, size: 64, color: AppColors.softCoral),
          const SizedBox(height: 24),
          Text("Download Official Report", style: AppTypography.heading(fontSize: 20)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Implementation to download report from /api/v1/parent/students/{id}/report
            },
            icon: const Icon(Icons.download),
            label: const Text("Download PDF"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.calmBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.heading(fontSize: 18, color: AppColors.textPrimary)),
          Text(label, style: AppTypography.caption(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

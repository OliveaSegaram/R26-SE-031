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
              Tab(text: "Reading Progress"),
              Tab(text: "Reading Pattern"),
              Tab(text: "Activity History"),
              Tab(text: "Reports"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildReadingProgressTab(),
                  _buildReadingPatternTab(),
                  _buildActivityHistoryTab(),
                  _buildReportsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    // 4 KPI Cards
    // Reading Accuracy: 78%
    // Reading Practice: 18 min
    // Reading Sessions: 6
    // Reading Progress: Developing
    
    final accuracy = _overview?['accuracy'] ?? 0;
    final practice = _overview?['practice_time_minutes'] ?? 0;
    final sessions = _overview?['sessions_completed'] ?? 0;
    final progress = _overview?['reading_progress'] ?? "Developing";

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
              _buildStatCard("Reading Accuracy", "$accuracy%", Icons.track_changes_rounded, AppColors.gentleGreen),
              _buildStatCard("Reading Practice", "$practice min", Icons.schedule_rounded, AppColors.calmBlue),
              _buildStatCard("Reading Sessions", "$sessions", Icons.videogame_asset_rounded, AppColors.softCoral),
              _buildStatCard("Reading Progress", progress, Icons.trending_up_rounded, AppColors.warmAmber),
            ],
          ),
          const SizedBox(height: 24),
          
          Text("Fluency Status", style: AppTypography.heading(fontSize: 20)),
          const SizedBox(height: 16),
          _buildFluencyCard(),
        ],
      ),
    );
  }

  Widget _buildFluencyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.calmBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Reading Fluency", style: AppTypography.heading(fontSize: 18, color: AppColors.textPrimary)),
              Text(_overview?['reading_progress'] ?? "Developing", style: AppTypography.heading(fontSize: 16, color: AppColors.calmBlue)),
            ],
          ),
          const SizedBox(height: 12),
          // Simple visual progress bar approximation (70% full)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.7,
              minHeight: 12,
              backgroundColor: AppColors.borderLight,
              color: AppColors.calmBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "* System-derived reading performance indicator (not a clinically validated score).",
            style: AppTypography.caption(fontSize: 11, color: AppColors.textSecondary),
          )
        ],
      ),
    );
  }

  Widget _buildReadingProgressTab() {
    List<dynamic> trendRaw = _overview?['accuracy_trend'] ?? [];
    List<double> trendData = trendRaw.isNotEmpty ? trendRaw.map((e) => (e['accuracy'] as num).toDouble()).toList() : [0.0];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Accuracy Over Time", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 16),
          TrendChart(
            title: "Reading Accuracy (%)",
            dataPoints: trendData,
            lineColor: AppColors.calmBlue,
            minY: 0,
            maxY: 100,
          ),
        ],
      ),
    );
  }

  Widget _buildReadingPatternTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Observation", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gentleGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.insights_rounded, color: AppColors.gentleGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _learningPattern?['observation'] ?? "Your child is showing steady reading development.",
                    style: AppTypography.body(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("Recommended Practice", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          ...(_learningPattern?['recommended_practices'] as List<dynamic>? ?? []).map((p) => _buildRecommendationTile(p.toString())),
        ],
      ),
    );
  }

  Widget _buildRecommendationTile(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: Border.all(color: AppColors.warmAmber.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded, color: AppColors.warmAmber),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTypography.body())),
        ],
      ),
    );
  }

  Widget _buildActivityHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Recent Reading Activity", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.calmBlue.withValues(alpha: 0.05)),
              columns: const [
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Activity', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Result', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: const [
                DataRow(cells: [
                  DataCell(Text('Aug 30')),
                  DataCell(Text('පෙළපොතෙන් කියවමු - 1')),
                  DataCell(Text('80%')),
                  DataCell(Text('5 min')),
                ]),
                DataRow(cells: [
                  DataCell(Text('Aug 29')),
                  DataCell(Text('කවුද?')),
                  DataCell(Text('75%')),
                  DataCell(Text('4 min')),
                ]),
                DataRow(cells: [
                  DataCell(Text('Aug 28')),
                  DataCell(Text('මොනවාද?')),
                  DataCell(Text('85%')),
                  DataCell(Text('4 min')),
                ]),
              ],
            ),
          ),
        ],
      ),
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "Report includes reading progress, accuracy trend, practice time, fluency status, and simple observations.",
              textAlign: TextAlign.center,
              style: AppTypography.caption(),
            ),
          ),
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

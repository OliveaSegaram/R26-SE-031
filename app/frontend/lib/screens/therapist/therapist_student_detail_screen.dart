import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/therapist_dashboard_service.dart';
import '../../utils/avatar_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/trend_chart.dart';

class TherapistStudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const TherapistStudentDetailScreen({super.key, required this.student});

  @override
  State<TherapistStudentDetailScreen> createState() => _TherapistStudentDetailScreenState();
}

class _TherapistStudentDetailScreenState extends State<TherapistStudentDetailScreen> {
  final TherapistDashboardService _dashboardService = TherapistDashboardService();
  bool _isLoading = true;
  
  Map<String, dynamic>? _overview;
  Map<String, dynamic>? _behavior;
  Map<String, dynamic>? _kinematics;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _knowledge;
  Map<String, dynamic>? _adaptive;
  String _currentFilter = "limit=10";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final studentId = widget.student['id']?.toString() ?? widget.student['_id']?.toString();
    if (studentId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final responses = await Future.wait([
      _dashboardService.getOverview(studentId),
      _dashboardService.getBehavior(studentId, _currentFilter),
      _dashboardService.getKinematics(studentId, _currentFilter),
      _dashboardService.getProfile(studentId),
      _dashboardService.getKnowledge(studentId, _currentFilter),
      _dashboardService.getAdaptiveHistory(studentId),
    ]);

    setState(() {
      _overview = responses[0];
      _behavior = responses[1];
      _kinematics = responses[2];
      _profile = responses[3];
      _knowledge = responses[4];
      _adaptive = responses[5];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.student['first_name'] ?? 'student';
    final grade = widget.student['grade'] ?? 'Grade 1';
    final avatar = AvatarUtils.getCorrectedAvatarPath(
        widget.student['avatar_url'] as String?, 
        'assets/images/characters/human/human_student_1.png');

    return DefaultTabController(
      length: 6,
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
              Text(
                'Clinical DB: $name',
                style: AppTypography.heading(fontSize: 18, color: AppColors.textPrimary),
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
              Tab(text: "C1: Behavioral"),
              Tab(text: "C2: Kinematics"),
              Tab(text: "C3: Profile"),
              Tab(text: "C4: Adaptive"),
              Tab(text: "Reports"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildBehavioralTab(),
                  _buildKinematicsTab(),
                  _buildProfileTab(),
                  _buildAdaptiveTab(),
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
          _buildModelInfo(_overview!),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard("Accuracy", "${_overview!['accuracy']}%", FontAwesomeIcons.bullseye, AppColors.gentleGreen),
              _buildStatCard("Median Latency", "${_overview!['median_latency_ms']} ms", FontAwesomeIcons.clock, AppColors.calmBlue),
              _buildStatCard("Hesitation Rate", "${(_overview!['hesitation_rate'] * 100).toStringAsFixed(1)}%", FontAwesomeIcons.pause, AppColors.warmAmber),
              _buildStatCard("Overall Mastery", "${(_overview!['overall_mastery'] * 100).toStringAsFixed(1)}%", FontAwesomeIcons.brain, AppColors.softCoral),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBehavioralTab() {
    if (_behavior == null) return const Center(child: Text("No Data"));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(_behavior!),
          const SizedBox(height: 16),
          TrendChart(
            title: "Accuracy Trend (%)",
            dataPoints: (_behavior!['accuracy_trend'] as List<dynamic>).map((e) => (e['accuracy'] as num).toDouble()).toList(),
            lineColor: AppColors.gentleGreen,
            minY: 0,
            maxY: 100,
          ),
          TrendChart(
            title: "Latency Trend (ms)",
            dataPoints: (_behavior!['latency_trend'] as List<dynamic>).map((e) => (e['latency_ms'] as num).toDouble()).toList(),
            lineColor: AppColors.calmBlue,
            minY: 0,
          ),
          Text("Learner Indices", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          ...(_behavior!['learner_indices'] as Map<String, dynamic>).entries.map((e) => 
            ListTile(
              title: Text(e.key.replaceAll('_', ' ').toUpperCase()),
              trailing: Text("${e.value}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.calmBlue)),
              tileColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildKinematicsTab() {
    if (_kinematics == null) return const Center(child: Text("No Data"));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(_kinematics!),
          const SizedBox(height: 16),
          TrendChart(
            title: "Orthographic Confusion Index (OCI)",
            dataPoints: (_kinematics!['oci_trend'] as List<dynamic>).map((e) => (e['oci'] as num).toDouble()).toList(),
            lineColor: AppColors.softCoral,
            minY: 0,
            maxY: 1.0,
          ),
          TrendChart(
            title: "Path Efficiency",
            dataPoints: (_kinematics!['path_efficiency_trend'] as List<dynamic>).map((e) => (e['efficiency'] as num).toDouble()).toList(),
            lineColor: AppColors.warmAmber,
            minY: 0,
            maxY: 1.0,
          ),
          Text("Feature Comparison", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          ...(_kinematics!['feature_comparison'] as Map<String, dynamic>).entries.map((e) => 
            ListTile(
              title: Text(e.key.replaceAll('_', ' ').toUpperCase()),
              trailing: Text("${e.value}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.softCoral)),
              tileColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    if (_profile == null) return const Center(child: Text("No Data"));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(_profile!),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Selected Pattern", style: AppTypography.caption(color: AppColors.calmBlue)),
                Text(_profile!['selected_pattern'], style: AppTypography.heading(fontSize: 20)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("SHAP Values (XAI)", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          ...(_profile!['shap_values'] as List<dynamic>).map((shap) => 
            ListTile(
              title: Text(shap['feature']),
              trailing: Text("+${shap['contribution']}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gentleGreen)),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveTab() {
    if (_adaptive == null || _knowledge == null) return const Center(child: Text("No Data"));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(_adaptive!),
          const SizedBox(height: 16),
          if (_adaptive!['timeline'] != null)
            TrendChart(
              title: "Mastery vs Attempts",
              dataPoints: (_adaptive!['timeline'] as List<dynamic>).map((e) => (e['mastery'] as num).toDouble()).toList(),
              lineColor: AppColors.gentleGreen,
              minY: 0.0,
              maxY: 1.0,
            ),
          Text("Knowledge Components", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          ...(_knowledge!['knowledge_components'] as Map<String, dynamic>).entries.map((e) => 
            ListTile(
              title: Text(e.key),
              trailing: Text("${(e.value * 100).toStringAsFixed(0)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.calmBlue)),
              tileColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            )
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
          const FaIcon(FontAwesomeIcons.fileMedicalAlt, size: 64, color: AppColors.softCoral),
          const SizedBox(height: 24),
          Text("Download Clinical Report", style: AppTypography.heading(fontSize: 20)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
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

  Widget _buildStatCard(String label, String value, dynamic icon, Color color) {
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
          FaIcon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.heading(fontSize: 18, color: AppColors.textPrimary)),
          Text(label, style: AppTypography.caption(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildModelInfo(Map<String, dynamic> data) {
    if (data['model_version'] == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(FontAwesomeIcons.microchip, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            "Model: ${data['model_version']} | Features: ${data['feature_version']}",
            style: AppTypography.caption(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

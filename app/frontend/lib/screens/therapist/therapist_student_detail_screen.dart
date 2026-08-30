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

    // Still using old service calls until backend is refactored, but UI will mock what's needed.
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
      length: 8,
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
                  'Clinical DB: $name',
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
              Tab(text: "Reading Performance"),
              Tab(text: "Speech Analysis"),
              Tab(text: "Multimodal Evidence"),
              Tab(text: "Learner Profile"),
              Tab(text: "Knowledge"),
              Tab(text: "Adaptive Learning"),
              Tab(text: "Reports"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildReadingPerformanceTab(),
                  _buildSpeechAnalysisTab(),
                  _buildMultimodalEvidenceTab(),
                  _buildLearnerProfileTab(),
                  _buildKnowledgeTab(),
                  _buildAdaptiveTab(),
                  _buildReportsTab(),
                ],
              ),
      ),
    );
  }

  // --- 1. OVERVIEW ---
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(_overview ?? {}),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard("Reading Accuracy", "${_overview?['accuracy'] ?? 0}%", FontAwesomeIcons.bullseye, AppColors.gentleGreen),
              _buildStatCard("Attempted Items", "${_overview?['attempted_items'] ?? 0}", FontAwesomeIcons.listOl, AppColors.calmBlue),
              _buildStatCard("Fluency Status", _overview?['fluency_status'] ?? "-", FontAwesomeIcons.chartLine, AppColors.warmAmber),
              _buildStatCard("Overall Mastery", "${((_overview?['overall_mastery'] ?? 0) * 100).toInt()}%", FontAwesomeIcons.brain, AppColors.softCoral),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. READING PERFORMANCE ---
  Widget _buildReadingPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(_behavior ?? {}),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: [
              _buildStatCard("Accuracy", "${_behavior?['accuracy'] ?? 0}%", Icons.check_circle_outline, AppColors.gentleGreen),
              _buildStatCard("Attempted", "${_behavior?['attempted'] ?? 0}", Icons.menu_book, AppColors.calmBlue),
              _buildStatCard("Correct", "${_behavior?['correct'] ?? 0}", Icons.check, AppColors.gentleGreen),
              _buildStatCard("Incorrect", "${_behavior?['incorrect'] ?? 0}", Icons.close, AppColors.softCoral),
              _buildStatCard("Completion Rate", "${((_behavior?['completion_rate'] ?? 0) * 100).toInt()}%", Icons.flag, AppColors.calmBlue),
            ],
          ),
          const SizedBox(height: 24),
          Text("Accuracy Trend", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          TrendChart(
            title: "Accuracy (%)",
            dataPoints: (_behavior?['accuracy_trend'] as List<dynamic>? ?? []).map((e) => (e['accuracy'] as num).toDouble()).toList().isNotEmpty ? (_behavior?['accuracy_trend'] as List<dynamic>).map((e) => (e['accuracy'] as num).toDouble()).toList() : [0.0],
            lineColor: AppColors.gentleGreen,
            minY: 0,
            maxY: 100,
          ),
        ],
      ),
    );
  }

  // --- 3. SPEECH ANALYSIS ---
  Widget _buildSpeechAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(8)),
            child: Text("STT Model: v2.1 | Acoustic Model: v1.4", style: AppTypography.caption(fontSize: 12, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 24),
          
          Text("STT Results", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Expected')),
                DataColumn(label: Text('Recognized')),
                DataColumn(label: Text('Result')),
              ],
              rows: const [
                DataRow(cells: [DataCell(Text('ගමට')), DataCell(Text('ගමට')), DataCell(Text('✓', style: TextStyle(color: Colors.green)))]),
                DataRow(cells: [DataCell(Text('යමු')), DataCell(Text('යමු')), DataCell(Text('✓', style: TextStyle(color: Colors.green)))]),
                DataRow(cells: [DataCell(Text('පාසල')), DataCell(Text('පසල')), DataCell(Text('⚠', style: TextStyle(color: Colors.orange)))]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard("WER", (_kinematics?['wer'] ?? 0).toStringAsFixed(2), Icons.text_snippet, AppColors.softCoral)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard("STT Confidence", "${((_kinematics?['stt_confidence'] ?? 0) * 100).toInt()}%", Icons.mic, AppColors.calmBlue)),
            ],
          ),
          
          const SizedBox(height: 32),
          Text("Acoustic Results", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: [
              _buildStatCard("Voice Onset", "${(_kinematics?['voice_onset_time'] ?? 0).toStringAsFixed(2)}s", Icons.play_arrow, AppColors.calmBlue),
              _buildStatCard("Latency", "${(_kinematics?['acoustic_latency'] ?? 0).toStringAsFixed(2)}s", Icons.timer, AppColors.warmAmber),
              _buildStatCard("Peaks/Syllables", "${_kinematics?['detected_peaks'] ?? 0} / ${_kinematics?['expected_syllables'] ?? 0}", Icons.graphic_eq, AppColors.calmBlue),
              _buildStatCard("Peak Delta", "${_kinematics?['peak_count_delta'] ?? 0}", Icons.difference, AppColors.softCoral),
              _buildStatCard("Silence Ratio", "${(_kinematics?['intra_word_silence_ratio'] ?? 0).toStringAsFixed(2)}", Icons.volume_mute, AppColors.warmAmber),
              _buildStatCard("Quality", _kinematics?['recording_quality']?.toString().toUpperCase() ?? "-", Icons.high_quality, AppColors.gentleGreen),
            ],
          ),
          
          const SizedBox(height: 24),
          TrendChart(title: "Acoustic Latency (ms)", dataPoints: const [1500, 1400, 1600, 1320], lineColor: AppColors.warmAmber, minY: 0),
          const SizedBox(height: 16),
          TrendChart(title: "Intra-Word Silence Ratio", dataPoints: const [0.2, 0.18, 0.15, 0.12], lineColor: AppColors.calmBlue, minY: 0, maxY: 1.0),
        ],
      ),
    );
  }

  // --- 4. MULTIMODAL EVIDENCE ---
  Widget _buildMultimodalEvidenceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.calmBlue, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Text("READING EVENT ANALYSIS", style: AppTypography.heading(fontSize: 18, color: AppColors.calmBlue))),
                const Divider(height: 32, thickness: 2),
                
                // STT Section
                Text("STT EVIDENCE", style: AppTypography.caption(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                _buildEvidenceRow("Expected", "ගමට යමු"),
                _buildEvidenceRow("STT", "ගමට යමු"),
                _buildEvidenceRow("WER", "0.00"),
                _buildEvidenceRow("STT confidence", "86%"),
                
                const Divider(height: 32),
                
                // ACOUSTIC Section
                Text("ACOUSTIC EVIDENCE", style: AppTypography.caption(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                _buildEvidenceRow("Latency", "1.32 s"),
                _buildEvidenceRow("Silence ratio", "0.12"),
                _buildEvidenceRow("Peak delta", "0"),
                _buildEvidenceRow("Jitter", "0.014"),
                _buildEvidenceRow("Shimmer", "0.031"),
                _buildEvidenceRow("Quality", "GOOD"),

                const Divider(height: 32),

                // COMBINED Section
                Text("COMBINED READING EVIDENCE", style: AppTypography.caption(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.gentleGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Reading Fluency", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Developing", style: TextStyle(color: AppColors.gentleGreen, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Evidence Quality", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Good", style: TextStyle(color: AppColors.calmBlue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "STT + Acoustic evidence are consistent.",
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          // Example of error case
          Text("Example: Error Case", style: AppTypography.heading(fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softCoral.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.softCoral.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("STT: WER = 0.25"),
                const Text("Acoustic: Latency = HIGH, Silence = HIGH, Peak Delta = +1"),
                const SizedBox(height: 8),
                const Text("Combined Conclusion:", style: TextStyle(fontWeight: FontWeight.bold)),
                const Text("The reading event showed transcription differences together with increased response latency and intra-word pausing."),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEvidenceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textDark)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- 5. LEARNER PROFILE ---
  Widget _buildLearnerProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(_profile ?? {}),
          const SizedBox(height: 16),
          Text("Learning Pattern Probabilities", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          _buildHorizontalBar("Typical", 0.12, AppColors.calmBlue),
          _buildHorizontalBar("Visual-Orthographic", 0.18, AppColors.calmBlue),
          _buildHorizontalBar("Phonological", 0.61, AppColors.softCoral),
          _buildHorizontalBar("Combined", 0.09, AppColors.calmBlue),
          
          const SizedBox(height: 32),
          Text("Model Evidence (SHAP)", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          _buildHorizontalBar("WER", 0.24, AppColors.warmAmber, prefix: "+"),
          _buildHorizontalBar("Intra-word silence", 0.18, AppColors.warmAmber, prefix: "+"),
          _buildHorizontalBar("Acoustic latency", 0.14, AppColors.warmAmber, prefix: "+"),
          _buildHorizontalBar("OCI", 0.09, AppColors.warmAmber, prefix: "+"),
          _buildHorizontalBar("Response latency", 0.08, AppColors.warmAmber, prefix: "+"),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.cardSurface, border: Border.all(color: AppColors.borderLight)),
            child: const Text(
              "Interpretation: Speech-related features contributed substantially to the predicted phonological learning pattern.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHorizontalBar(String label, double value, Color color, {String prefix = ""}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Container(height: 16, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(4))),
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                ),
              ],
            ),
          ),
          SizedBox(width: 40, child: Text(" $prefix${(value * 100).toInt()}%", textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // --- 6. KNOWLEDGE ---
  Widget _buildKnowledgeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(_knowledge ?? {}),
          const SizedBox(height: 16),
          Text("Reading Knowledge Components (BKT)", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 16),
          _buildHorizontalBar("Reading Fluency", 0.54, AppColors.gentleGreen),
          _buildHorizontalBar("Word Recognition", 0.68, AppColors.gentleGreen),
          _buildHorizontalBar("Sentence Reading", 0.42, AppColors.softCoral),
        ],
      ),
    );
  }

  // --- 7. ADAPTIVE LEARNING ---
  Widget _buildAdaptiveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(_adaptive ?? {}),
          const SizedBox(height: 16),
          
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard("Fatigue", "0.28", Icons.battery_alert, AppColors.softCoral),
              _buildStatCard("IRT Ability (θ)", "0.18", Icons.person, AppColors.calmBlue),
              _buildStatCard("Current Diff", "0.70", Icons.trending_up, AppColors.warmAmber),
            ],
          ),
          
          const SizedBox(height: 24),
          Text("Adaptive Decision", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cardSurface, border: Border.all(color: AppColors.borderLight), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEvidenceRow("Previous difficulty", "0.70"),
                _buildEvidenceRow("Next difficulty", "0.45"),
                const Divider(),
                _buildEvidenceRow("Scaffold", "Audio + Visual Hint"),
                _buildEvidenceRow("Next Activity", "පෙළපොතෙන් කියවමු - 1"),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: AppColors.calmBlue, borderRadius: BorderRadius.circular(4)),
                  child: const Center(child: Text("Decision: CONTINUE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Text("Decision Timeline (Research Loop)", style: AppTypography.heading(fontSize: 16)),
          const SizedBox(height: 12),
          Text("Reading → Speech Analysis → Learner State → BKT → C4 → Next Task", 
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  // --- 8. REPORTS ---
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon is IconData ? Icon(icon, color: color, size: 20) : FaIcon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.heading(fontSize: 16, color: AppColors.textPrimary)),
          Text(label, style: AppTypography.caption(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
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

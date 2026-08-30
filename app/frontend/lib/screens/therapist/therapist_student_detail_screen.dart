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
  Map<String, dynamic>? _c1Behavioral;
  Map<String, dynamic>? _c2Speech;
  Map<String, dynamic>? _c3Profile;
  Map<String, dynamic>? _c4Adaptive;

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
      _dashboardService.getC1Behavioral(studentId),
      _dashboardService.getC2Speech(studentId),
      _dashboardService.getC3Profile(studentId),
      _dashboardService.getC4Adaptive(studentId),
    ]);

    setState(() {
      _overview = responses[0];
      _c1Behavioral = responses[1];
      _c2Speech = responses[2];
      _c3Profile = responses[3];
      _c4Adaptive = responses[4];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.student['first_name'] ?? 'student';
    final avatar = AvatarUtils.getCorrectedAvatarPath(
        widget.student['avatar_url'] as String?, 
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
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage(avatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Therapist Student: $name',
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
              Tab(text: "C1 — Behavioral Analytics"),
              Tab(text: "C2 — Speech & Sinhala Interaction"),
              Tab(text: "C3 — Learner Profile & XAI"),
              Tab(text: "C4 — Adaptive Learning"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildC1BehavioralTab(),
                  _buildC2SpeechTab(),
                  _buildC3ProfileTab(),
                  _buildC4AdaptiveTab(),
                ],
              ),
      ),
    );
  }

  // ==========================================
  // 1. OVERVIEW
  // ==========================================
  Widget _buildOverviewTab() {
    final accuracy = _overview?['accuracy'] ?? 0.0;
    final mastery = _overview?['overall_mastery'] ?? 0.0;
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
              _buildStatCard("Reading Accuracy", "${(accuracy * 100).toInt()}%", FontAwesomeIcons.bullseye, AppColors.gentleGreen),
              _buildStatCard("Overall Mastery", "${(mastery * 100).toInt()}%", FontAwesomeIcons.brain, AppColors.calmBlue),
              _buildStatCard("Current Skill", _overview?['reading_fluency_status'] ?? "-", FontAwesomeIcons.chartLine, AppColors.warmAmber),
              _buildStatCard("Fatigue", _overview?['fatigue_status'] ?? "Low", FontAwesomeIcons.batteryHalf, AppColors.softCoral),
              _buildStatCard("Current Pattern", _overview?['current_pattern'] ?? "Unknown", FontAwesomeIcons.puzzlePiece, AppColors.calmBlue),
              _buildStatCard("Completed Sessions", "${_overview?['completed_sessions'] ?? 0}", FontAwesomeIcons.calendarCheck, AppColors.gentleGreen),
            ],
          ),
          const SizedBox(height: 24),
          Text("Latest Recommendation", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.calmBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Text("Continue short Sinhala reading practice.", style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text("Therapist Learning & Assessment Report"),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.calmBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          )
        ],
      ),
    );
  }

  // ==========================================
  // 2. C1 — BEHAVIORAL ANALYTICS
  // ==========================================
  Widget _buildC1BehavioralTab() {
    final accuracy = _c1Behavioral?['accuracy'] ?? 0.0;
    final errRate = _c1Behavioral?['error_rate'] ?? 0.0;
    final misclickRate = _c1Behavioral?['misclick_rate'] ?? 0.0;
    final indices = _c1Behavioral?['indices'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(_c1Behavioral ?? {}),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: [
              _buildStatCard("Accuracy", "${(accuracy * 100).toInt()}%", Icons.check_circle_outline, AppColors.gentleGreen),
              _buildStatCard("Median Latency", "${_c1Behavioral?['median_latency_ms'] ?? 0} ms", Icons.timer, AppColors.calmBlue),
              _buildStatCard("Latency Drift", "${_c1Behavioral?['latency_drift'] ?? 0} ms", Icons.trending_up, AppColors.warmAmber),
              _buildStatCard("Error Rate", "${(errRate * 100).toInt()}%", Icons.close, AppColors.softCoral),
              _buildStatCard("Hesitation Rate", "${((_c1Behavioral?['hesitation_rate'] ?? 0) * 100).toInt()}%", Icons.pause_circle_outline, AppColors.calmBlue),
              _buildStatCard("Fatigue Score", "${_c1Behavioral?['fatigue_score'] ?? 0}", Icons.battery_alert, AppColors.softCoral),
            ],
          ),
          
          const SizedBox(height: 24),
          Text("Behavioral Indices", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          _buildHorizontalBar("Visual Processing", indices['visual_processing'] ?? 0.0, AppColors.calmBlue),
          _buildHorizontalBar("Phonological Tasks", indices['phonological_tasks'] ?? 0.0, AppColors.gentleGreen),
          _buildHorizontalBar("Motor Interaction", indices['motor_interaction'] ?? 0.0, AppColors.warmAmber),
          _buildHorizontalBar("Attention Stability", indices['attention_stability'] ?? 0.0, AppColors.softCoral),
          
          const SizedBox(height: 24),
          Text("Error Composition", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          _buildHorizontalBar("Correct", accuracy, AppColors.gentleGreen),
          _buildHorizontalBar("Incorrect", errRate, AppColors.warmAmber),
          _buildHorizontalBar("Misclick", misclickRate, AppColors.softCoral),
        ],
      ),
    );
  }

  // ==========================================
  // 3. C2 — SPEECH & SINHALA INTERACTION
  // ==========================================
  Widget _buildC2SpeechTab() {
    final latest = _c2Speech?['latest'] ?? {};
    final trends = _c2Speech?['trends'] ?? {};
    final latTrendRaw = trends['latency'] as List<dynamic>? ?? [];
    final latTrend = latTrendRaw.map((e) => (e['value'] as num).toDouble()).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(_c2Speech ?? {}),
          const SizedBox(height: 16),
          
          // Hero Card: Combined Reading Evidence
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
                Center(child: Text("READING & SPEECH EVENT", style: AppTypography.heading(fontSize: 18, color: AppColors.calmBlue))),
                const Divider(height: 32, thickness: 2),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("STT EVIDENCE", style: AppTypography.caption(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          _buildEvidenceRow("WER", "${latest['wer'] ?? 0.0}"),
                          _buildEvidenceRow("Confidence", "${((latest['stt_confidence'] ?? 0.0) * 100).toInt()}%"),
                        ],
                      )
                    ),
                    Container(width: 1, height: 80, color: AppColors.borderLight, margin: const EdgeInsets.symmetric(horizontal: 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("ACOUSTIC EVIDENCE", style: AppTypography.caption(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          _buildEvidenceRow("Latency", "${(latest['acoustic_latency_ms'] ?? 0.0) / 1000}s"),
                          _buildEvidenceRow("Silence", "${latest['silence_ratio'] ?? 0.0}"),
                          _buildEvidenceRow("Peak Δ", "${latest['peak_delta'] ?? 0}"),
                          _buildEvidenceRow("Quality", "${latest['recording_quality'] ?? 'Unknown'}"),
                        ],
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(child: const Icon(Icons.arrow_downward, color: AppColors.textHint)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.gentleGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Text("Reading Evidence", style: AppTypography.caption(color: AppColors.textSecondary)),
                      Text("Consistent", style: AppTypography.heading(fontSize: 20, color: AppColors.gentleGreen)),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Text("Expected vs Recognized", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Expected')),
                DataColumn(label: Text('Recognized')),
                DataColumn(label: Text('Result')),
              ],
              rows: [
                DataRow(cells: [
                  DataCell(Text(latest['expected_text']?.toString() ?? '-')), 
                  DataCell(Text(latest['transcription']?.toString() ?? '-')), 
                  DataCell(Text((latest['wer'] ?? 1.0) == 0.0 ? '✓' : '⚠', style: TextStyle(color: (latest['wer'] ?? 1.0) == 0.0 ? Colors.green : Colors.orange)))
                ]),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildStatCard("Current Jitter", "${latest['jitter'] ?? 0.0}", Icons.multiline_chart, AppColors.calmBlue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard("Current Shimmer", "${latest['shimmer'] ?? 0.0}", Icons.waves, AppColors.calmBlue)),
            ],
          ),
          
          const SizedBox(height: 24),
          if (latTrend.isNotEmpty) ...[
            TrendChart(title: "Acoustic Latency (ms)", dataPoints: latTrend, lineColor: AppColors.warmAmber, minY: 0),
          ]
        ],
      ),
    );
  }

  // ==========================================
  // 4. C3 — LEARNER PROFILE & XAI
  // ==========================================
  Widget _buildC3ProfileTab() {
    final probs = _c3Profile?['probabilities'] ?? {};
    final shap = _c3Profile?['shap_explanations'] as List<dynamic>? ?? [];
    final pattern = _c3Profile?['primary_pattern'] ?? 'Unknown';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(_c3Profile ?? {}),
          const SizedBox(height: 16),
          Text("Learning Pattern Probabilities", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          _buildHorizontalBar("Typical", probs['Typical'] ?? 0.0, AppColors.calmBlue),
          _buildHorizontalBar("Visual-Orthographic", probs['Visual-Orthographic'] ?? 0.0, AppColors.calmBlue),
          _buildHorizontalBar("Phonological", probs['Phonological'] ?? 0.0, pattern == 'Phonological' ? AppColors.softCoral : AppColors.calmBlue),
          _buildHorizontalBar("Combined", probs['Combined'] ?? 0.0, pattern == 'Combined' ? AppColors.softCoral : AppColors.calmBlue),
          
          const SizedBox(height: 32),
          Text("Model Evidence (SHAP)", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          ...shap.map((s) => _buildHorizontalBar(s['feature'] ?? '', (s['contribution'] as num).toDouble(), AppColors.warmAmber, prefix: "+")).toList(),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.cardSurface, border: Border.all(color: AppColors.borderLight), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Interpretation", style: AppTypography.caption(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  "Speech-related latency and intra-word pausing contributed strongly to the current ${pattern.toLowerCase()} learning-pattern prediction.",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ==========================================
  // 5. C4 — ADAPTIVE LEARNING
  // ==========================================
  Widget _buildC4AdaptiveTab() {
    final kcs = _c4Adaptive?['knowledge_components'] as List<dynamic>? ?? [];
    final history = _c4Adaptive?['history'] as List<dynamic>? ?? [];
    final theta = _c4Adaptive?['theta'] ?? 0.0;
    final thetaSe = _c4Adaptive?['theta_se'] ?? 0.0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(_c4Adaptive ?? {}),
          const SizedBox(height: 16),
          
          // Current Decision Card
          if (history.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.cardSurface, border: Border.all(color: AppColors.calmBlue, width: 2), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Text("CURRENT DECISION", style: AppTypography.heading(fontSize: 16, color: AppColors.calmBlue))),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Difficulty", style: AppTypography.caption()),
                          Text("${history.last['previous_difficulty'] ?? 0.0} → ${history.last['selected_difficulty'] ?? 0.0}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Scaffold", style: AppTypography.caption()),
                          Text("Level ${history.last['scaffold_level'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text("Next Activity", style: AppTypography.caption()),
                  Text("${history.last['next_activity'] ?? 'Unknown'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Reason", style: AppTypography.caption()),
                  Text("${history.last['reason'] ?? 'N/A'}", style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          Text("Knowledge Mastery (BKT)", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          ...kcs.map((kc) => _buildHorizontalBar(kc['name'] ?? '', (kc['mastery'] as num).toDouble(), AppColors.gentleGreen)).toList(),
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard("IRT Ability (θ)", "${theta.toStringAsFixed(2)}", Icons.person, AppColors.calmBlue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard("IRT SE", "${thetaSe.toStringAsFixed(2)}", Icons.error_outline, AppColors.textSecondary)),
            ],
          ),
          
          const SizedBox(height: 32),
          Text("Adaptive Decision Timeline", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 16),
          
          // Timeline
          ...history.asMap().entries.map((entry) {
            int idx = entry.key;
            var dec = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderLight)),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: AppColors.calmBlue, shape: BoxShape.circle),
                    child: Center(child: Text("${idx + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Mastery ${(dec['mastery_after'] as num? ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Difficulty ${(dec['selected_difficulty'] as num? ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if ((dec['scaffold_level'] ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.warmAmber.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                      child: Text("Scaffold ON", style: TextStyle(color: AppColors.warmAmber, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED WIDGETS
  // ==========================================
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

  Widget _buildStatCard(String label, String value, dynamic icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon is IconData ? Icon(icon, color: color, size: 20) : FaIcon(icon as FaIconData, color: color, size: 20),
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

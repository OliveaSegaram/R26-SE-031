import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../services/therapist_dashboard_service.dart';
import '../../utils/avatar_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/trend_chart.dart';
import '../../widgets/research_evidence_panel.dart';

class TherapistStudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const TherapistStudentDetailScreen({super.key, required this.student});

  @override
  State<TherapistStudentDetailScreen> createState() => _TherapistStudentDetailScreenState();
}

class _TherapistStudentDetailScreenState extends State<TherapistStudentDetailScreen> {
  final TherapistDashboardService _dashboardService = TherapistDashboardService();
  bool _isLoading = true;
  Map<String, dynamic>? _evidence;
  
  Map<String, dynamic>? _overview;
  Map<String, dynamic>? _c1Behavioral;
  Map<String, dynamic>? _c2Speech;
  Map<String, dynamic>? _c3Profile;
  Map<String, dynamic>? _c4Adaptive;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (mounted) setState(() => _isLoading = true);
    final studentId = widget.student['student_id']?.toString() ?? widget.student['id']?.toString() ?? widget.student['_id']?.toString();
    Future<Map<String, dynamic>> capture(Future<Map<String, dynamic>> request) async {
      try { return await request; } catch (e) { return {'_error': e.toString()}; }
    }
    final responses = studentId == null || studentId.isEmpty
        ? List.generate(6, (_) => <String, dynamic>{'_error': 'Invalid student ID'})
        : await Future.wait([
            capture(_dashboardService.getOverview(studentId)),
            capture(_dashboardService.getC1Behavioral(studentId)),
            capture(_dashboardService.getC2Speech(studentId)),
            capture(_dashboardService.getC3Profile(studentId)),
            capture(_dashboardService.getC4Adaptive(studentId)),
            capture(_dashboardService.getResearchEvidence(studentId)),
          ]);
    if (!mounted) return;
    setState(() {
      _overview = responses[0];
      _c1Behavioral = responses[1];
      _c2Speech = responses[2];
      _c3Profile = responses[3];
      _c4Adaptive = responses[4];
      _evidence = responses[5];
      _isLoading = false;
      _errorMessage = null;
    });
  }
  Future<void> _downloadPdf() async {
    final studentId = widget.student['student_id']?.toString() ?? widget.student['id']?.toString() ?? widget.student['_id']?.toString();
    if (studentId == null) return;
    try {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF Report...')));
      // Fetch pdf
      final bytes = await _dashboardService.downloadReport(studentId);
      await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: 'Sipsara_Report.pdf')], fileNameOverrides: ['Sipsara_Report.pdf']));
      // Let's assume standard flutter 'dart:html' downloading for web, but since this is mobile/multi we just show success for now.
      // In a real app we'd use path_provider and open_file, or printing package.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report ready in the share dialog.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading report: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.student['first_name'] ?? 'student';
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
              Tab(text: "PP2 Evidence"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : _errorMessage != null 
                ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                : TabBarView(
                    children: [
                      DashboardSection(data: _overview, onRetry: _loadAllData, child: _buildOverviewTab()),
                      DashboardSection(data: _c1Behavioral, onRetry: _loadAllData, child: _buildC1BehavioralTab()),
                      DashboardSection(data: _c2Speech, onRetry: _loadAllData, child: _buildC2SpeechTab()),
                      DashboardSection(data: _c3Profile, onRetry: _loadAllData, child: _buildC3ProfileTab()),
                      DashboardSection(data: _c4Adaptive, onRetry: _loadAllData, child: _buildC4AdaptiveTab()),
                      DashboardSection(data: _evidence, onRetry: _loadAllData, child: ResearchEvidencePanel(data: _evidence ?? {})),
                    ],
                  ),
      ),
    );
  }

  // ==========================================
  // 1. OVERVIEW
  // ==========================================
  Widget _buildOverviewTab() {
    final accuracy = _overview?['accuracy'];
    final mastery = _overview?['overall_mastery'];
    final c1Avail = _overview?['c1_available'] == true;
    final c2Avail = _overview?['c2_available'] == true;
    final c3Avail = _overview?['c3_available'] == true;
    final c4Avail = _overview?['c4_available'] == true;
    final recommendation = _overview?['latest_recommendation'] ?? "No recommendation available.";
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildModelInfo(_overview ?? {}),
              if (_overview?['last_active'] != null)
                Text("Last Active: ${_overview!['last_active']}", style: AppTypography.caption()),
            ],
          ),
          const SizedBox(height: 16),
          // Availability Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAvailabilityBadge("C1", c1Avail),
              _buildAvailabilityBadge("C2", c2Avail),
              _buildAvailabilityBadge("C3", c3Avail),
              _buildAvailabilityBadge("C4", c4Avail),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard("First-attempt Accuracy", metricText(accuracy, scale: 100, suffix: '%', decimals: 0), FontAwesomeIcons.bullseye, AppColors.gentleGreen),
              _buildStatCard("Mean BKT Estimate", metricText(mastery, scale: 100, suffix: '%', decimals: 0), FontAwesomeIcons.brain, AppColors.calmBlue),
              _buildStatCard("Model Mastery Status", _overview?['reading_fluency_status'] ?? "-", FontAwesomeIcons.chartLine, AppColors.warmAmber),
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
            decoration: BoxDecoration(color: AppColors.calmBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(recommendation, style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.download),
              label: const Text("Share Therapist Report (PDF)"),
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
    final firstAttemptAcc = _c1Behavioral?['first_attempt_accuracy'];
    final medianLat = _c1Behavioral?['median_response_latency_ms'];
    final retryRate = _c1Behavioral?['retry_rate'];
    final meanAttempts = _c1Behavioral?['mean_attempts_per_round'];
    final medianTimeToCorrect = _c1Behavioral?['median_time_to_correct_ms'];
    final fatigue = _c1Behavioral?['behavioral_fatigue_proxy'];

    final kcPerformance = _c1Behavioral?['kc_performance'] != null ? Map<String, dynamic>.from(_c1Behavioral!['kc_performance']) : <String, dynamic>{};
    final errors = _c1Behavioral?['error_distribution'] != null ? Map<String, dynamic>.from(_c1Behavioral!['error_distribution']) : <String, dynamic>{};
    
    final trends = _c1Behavioral?['trends'] != null ? Map<String, dynamic>.from(_c1Behavioral!['trends']) : <String, dynamic>{};
    final accTrendRaw = trends['accuracy'] as List<dynamic>? ?? [];
    final latTrendRaw = trends['latency'] as List<dynamic>? ?? [];
    final fatTrendRaw = trends['fatigue'] as List<dynamic>? ?? [];
    
    final accTrend = accTrendRaw.map((e) => (e['value'] as num?)?.toDouble()).toList();
    final latTrend = latTrendRaw.map((e) => e['value'] is num ? (e['value'] as num).toDouble() / 1000 : null).toList();
    final fatTrend = fatTrendRaw.map((e) => (e['value'] as num?)?.toDouble()).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(_c1Behavioral ?? {}),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              int cardsPerRow = constraints.maxWidth > 600 ? 3 : 2;
              double spacing = 12.0;
              double cardWidth = (constraints.maxWidth - (spacing * (cardsPerRow - 1))) / cardsPerRow;
              
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(width: cardWidth, child: _buildStatCard("First-Attempt Accuracy", firstAttemptAcc != null ? "${((firstAttemptAcc as num) * 100).toInt()}%" : "N/A", Icons.check_circle_outline, AppColors.gentleGreen)),
                  SizedBox(width: cardWidth, child: _buildStatCard("Retry Rate", retryRate != null ? "${((retryRate as num) * 100).toInt()}%" : "N/A", Icons.replay, AppColors.warmAmber)),
                  SizedBox(width: cardWidth, child: _buildStatCard("Mean Attempts", meanAttempts != null ? (meanAttempts as num).toStringAsFixed(1) : "N/A", Icons.numbers, AppColors.softCoral)),
                  SizedBox(width: cardWidth, child: _buildStatCard("Median Response Time", medianLat != null ? "${((medianLat as num) / 1000).toStringAsFixed(1)} s" : "N/A", Icons.timer, AppColors.calmBlue)),
                  SizedBox(width: cardWidth, child: _buildStatCard("Time to Correct", medianTimeToCorrect != null ? "${((medianTimeToCorrect as num) / 1000).toStringAsFixed(1)} s" : "N/A", Icons.hourglass_bottom, AppColors.calmBlue)),
                  SizedBox(width: cardWidth, child: _buildStatCard("Behavioral Fatigue Indicator", fatigue != null ? (fatigue as num).toStringAsFixed(2) : "N/A", Icons.battery_alert, AppColors.softCoral)),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),
          Text("Attempt Behavior", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          _buildAttemptBehaviorBar(firstAttemptAcc, retryRate),
          
          const SizedBox(height: 24),
          Text("Knowledge Component Performance", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          _buildHorizontalBar("Akshara Identity", kcPerformance['KC_AKSHARA_IDENTITY'], AppColors.calmBlue),
          _buildHorizontalBar("Phoneme–Grapheme", kcPerformance['KC_PHONEME_GRAPHEME'], AppColors.gentleGreen),
          _buildHorizontalBar("Word Recognition", kcPerformance['KC_WORD_RECOGNITION'], AppColors.warmAmber),
          _buildHorizontalBar("Spelling Sequence", kcPerformance['KC_SPELLING_SEQUENCE'], AppColors.softCoral),
          _buildHorizontalBar("Sentence Language", kcPerformance['KC_SENTENCE_LANGUAGE'], AppColors.calmBlue),
          _buildHorizontalBar("Reading Comprehension", kcPerformance['KC_READING_COMPREHENSION'], AppColors.gentleGreen),
          const SizedBox(height: 16),
          Text("Supportive Measure", style: AppTypography.heading(fontSize: 14)),
          const SizedBox(height: 8),
          _buildHorizontalBar("Visual Support", kcPerformance['KC_VISUAL_SUPPORT'], AppColors.warmAmber),
          _buildHorizontalBar("Letter Sequence Memory", kcPerformance['KC_ORTHOGRAPHIC_MEMORY'], AppColors.calmBlue),
          _buildHorizontalBar("Oral Reading", kcPerformance['KC_ORAL_READING_FLUENCY'], AppColors.calmBlue),
          
          const SizedBox(height: 24),
          Text("Observed Error Pattern", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          _buildErrorPattern(errors),
          
          const SizedBox(height: 32),
          Text("Performance Across Sessions", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          if (accTrend.length < 2 && latTrend.length < 2 && fatTrend.length < 2)
            const Text("Complete more sessions to view this trend.", style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary))
          else ...[
            if (accTrend.length >= 2) ...[
              TrendChart(title: "First-Attempt Accuracy", dataPoints: accTrend, labels: accTrendRaw.map((e) => e['session'].toString()).toList(), lineColor: AppColors.gentleGreen, minY: 0),
              const SizedBox(height: 24),
            ],
            if (latTrend.length >= 2) ...[
              TrendChart(title: "Median Response Time (s)", dataPoints: latTrend, labels: latTrendRaw.map((e) => e['session'].toString()).toList(), lineColor: AppColors.calmBlue, minY: 0),
              const SizedBox(height: 24),
            ],
            if (fatTrend.length >= 2) ...[
              TrendChart(title: "Behavioral Fatigue Indicator", dataPoints: fatTrend, labels: fatTrendRaw.map((e) => e['session'].toString()).toList(), lineColor: AppColors.softCoral),
            ],
          ]
        ],
      ),
    );
  }

  Widget _buildAttemptBehaviorBar(dynamic firstAttemptAcc, dynamic retryRate) => Column(children: [
    _buildHorizontalBar('First-attempt success', firstAttemptAcc, AppColors.gentleGreen),
    _buildHorizontalBar('Trials with retries', retryRate, AppColors.warmAmber),
    const Text('Separate rates with the same trial denominator; they are not normalized into a 100% stacked chart.'),
  ]);

  Widget _buildErrorPattern(Map<String, dynamic> errors) {
    if (errors.isEmpty) {
      return const Text("No error-pattern data available yet.", style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary));
    }
    
    // Check if everything is null
    bool hasData = false;
    for (var key in ['visual_confusion', 'phonological_confusion', 'sequence_error', 'unknown_error']) {
      if (errors[key] != null) hasData = true;
    }
    if (!hasData) {
      return const Text("No error-pattern data available yet.", style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary));
    }

    double visual = (errors['visual_confusion'] as num?)?.toDouble() ?? 0.0;
    double phono = (errors['phonological_confusion'] as num?)?.toDouble() ?? 0.0;
    double seq = (errors['sequence_error'] as num?)?.toDouble() ?? 0.0;
    double unk = (errors['unknown_error'] as num?)?.toDouble() ?? 0.0;
    
    if (visual == 0 && phono == 0 && seq == 0 && unk == 0) {
      return const Text("No first-attempt errors observed in this session.", style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.gentleGreen));
    }
    
    return Column(
      children: [
        _buildHorizontalBar("Visual Confusion", errors['visual_confusion'], AppColors.calmBlue),
        _buildHorizontalBar("Phonological Confusion", errors['phonological_confusion'], AppColors.gentleGreen),
        _buildHorizontalBar("Sequence Error", errors['sequence_error'], AppColors.warmAmber),
        _buildHorizontalBar("Unknown / Unclassified", errors['unknown_error'], AppColors.softCoral),
      ],
    );
  }

  // ==========================================
  // 3. C2 — SPEECH & SINHALA INTERACTION
  // ==========================================
  Widget _buildC2SpeechTab() {
    final latest = _c2Speech?['latest'] ?? {};
    final trends = _c2Speech?['trends'] ?? {};
    final latTrendRaw = trends['latency'] as List<dynamic>? ?? [];
    final latTrend = latTrendRaw.map((e) => (e['value'] as num?)?.toDouble()).toList();
    
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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
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
                          _buildEvidenceRow("WER", metricText(latest['wer'])),
                          _buildEvidenceRow("Confidence", metricText(latest['stt_confidence'], scale: 100, suffix: '%')),
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
                          _buildEvidenceRow("Latency", metricText(latest['acoustic_latency_ms'], scale: .001, suffix: ' s')),
                          _buildEvidenceRow("Silence", metricText(latest['silence_ratio'])),
                          _buildEvidenceRow("Peak Δ", metricText(latest['peak_delta'])),
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
                  decoration: BoxDecoration(color: AppColors.gentleGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Text("Reading Evidence", style: AppTypography.caption(color: AppColors.textSecondary)),
                      Text(latest['measurement_status']?.toString() ?? "Unavailable", style: AppTypography.heading(fontSize: 20, color: AppColors.gentleGreen)),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          _buildEvidenceRow('Thresholded pauses (200–3000 ms)', metricText(latest['pause_count'], decimals: 0)),
          _buildEvidenceRow('Mean detected pause', metricText(latest['mean_pause_duration_ms'], suffix: ' ms')),
          _buildEvidenceRow('Detected pause ratio', metricText(latest['pause_ratio'])),
          _buildEvidenceRow('Active-span duration', metricText(latest['speech_duration_ms'], suffix: ' ms')),
          const Text('Thresholded acoustic intervals, not validated linguistic pause or syllable annotations.'),
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
              Expanded(child: _buildStatCard("Current Jitter", metricText(latest['jitter']), Icons.multiline_chart, AppColors.calmBlue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard("Current Shimmer", metricText(latest['shimmer']), Icons.waves, AppColors.calmBlue)),
            ],
          ),
          
          const SizedBox(height: 24),
          if (latTrend.isNotEmpty) ...[
            TrendChart(title: "Acoustic Latency (ms)", dataPoints: latTrend, lineColor: AppColors.warmAmber, minY: 0),
          ],
          const SizedBox(height: 24),
          if (trends['wer'] != null) ...[
            TrendChart(title: "Word Error Rate (WER)", dataPoints: (trends['wer'] as List).map((e) => (e['value'] as num?)?.toDouble()).toList(), lineColor: AppColors.softCoral, minY: 0),
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
          _buildHorizontalBar("Typical", probs['Typical'], AppColors.calmBlue),
          _buildHorizontalBar("Visual-Orthographic", probs['Visual-Orthographic'], AppColors.calmBlue),
          _buildHorizontalBar("Phonological", probs['Phonological'], pattern == 'Phonological' ? AppColors.softCoral : AppColors.calmBlue),
          _buildHorizontalBar("Combined", probs['Combined'], pattern == 'Combined' ? AppColors.softCoral : AppColors.calmBlue),
          
          const SizedBox(height: 32),
          Text("Model Evidence (SHAP)", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          ...shap.map((s) {
            final featureName = s['feature'] ?? '';
            final impact = (s['contribution'] as num?)?.toDouble() ?? 0.0;
            final direction = s['direction'] ?? '';
            final obs = s['observed_value'];
            
            String title = featureName;
            if (obs != null) {
              title += " (Observed: $obs $direction)";
            }
            
            return ListTile(contentPadding: EdgeInsets.zero, title: Text(title),
              subtitle: Text(impact >= 0 ? 'Increases explained model score (raw margin)' : 'Decreases explained model score (raw margin)'),
              trailing: Text('${impact >= 0 ? '+' : ''}${impact.toStringAsFixed(3)}'));
          }).toList(),
          
          const SizedBox(height: 24),
          const SizedBox(height: 24),
          if (_c3Profile?['llm_summary'] != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.calmBlue.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.calmBlue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.calmBlue, size: 20),
                      const SizedBox(width: 8),
                      Text("Experimental Model Summary", style: AppTypography.heading(fontSize: 16, color: AppColors.calmBlue)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_c3Profile!['llm_summary'], style: AppTypography.body(fontSize: 14)),
                  const SizedBox(height: 16),
                  Text("Recommendations", style: AppTypography.heading(fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(_c3Profile!['llm_recommendations'] ?? '', style: AppTypography.body(fontSize: 14)),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.cardSurface, border: Border.all(color: AppColors.borderLight), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Interpretation", style: AppTypography.caption(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    "No generated interpretation is available. SHAP describes model behavior; it does not establish a cause or a learning difficulty.",
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
    final theta = _c4Adaptive?['theta'];
    final thetaSe = _c4Adaptive?['theta_se'];
    
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
                  Center(child: Text("LATEST RECOMMENDATION (NOT APPLIED IN GAME)", style: AppTypography.heading(fontSize: 16, color: AppColors.calmBlue))),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Difficulty", style: AppTypography.caption()),
                          Text("${metricText(history.last['previous_difficulty'])} → ${metricText(history.last['selected_difficulty'])}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
          
          Text("Estimated KC Mastery (BKT)", style: AppTypography.heading(fontSize: 18)),
          const SizedBox(height: 12),
          ...kcs.map((kc) => _buildHorizontalBar(kc['name'] ?? '', (kc['mastery'] as num).toDouble(), AppColors.gentleGreen)).toList(),
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard("IRT Ability (θ)", metricText(theta), Icons.person, AppColors.calmBlue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard("IRT SE", metricText(thetaSe), Icons.error_outline, AppColors.textSecondary)),
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
                        Text("Mastery ${metricText(dec['mastery_after'])}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Difficulty ${metricText(dec['selected_difficulty'])}", style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if ((dec['scaffold_level'] ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.warmAmber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
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
  Widget _buildAvailabilityBadge(String title, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.gentleGreen.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        border: Border.all(color: isAvailable ? AppColors.gentleGreen : Colors.grey),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isAvailable ? Icons.check_circle : Icons.cancel, size: 14, color: isAvailable ? AppColors.gentleGreen : Colors.grey),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(color: isAvailable ? AppColors.gentleGreen : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _buildHorizontalBar(String label, dynamic rawValue, Color color, {String prefix = ""}) {
    final value = rawValue != null ? (rawValue as num).toDouble() : null;
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
                if (value != null)
                  FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                  ),
              ],
            ),
          ),
          SizedBox(width: 40, child: Text(value != null ? " $prefix${(value * 100).toInt()}%" : "N/A", textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: value != null ? Colors.black : Colors.grey))),
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

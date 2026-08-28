import 'package:flutter/material.dart';
import 'dart:math';
import '../../theme/app_theme.dart';
import '../../services/localization_service.dart';
import '../../services/student_service.dart';
import '../../services/telemetry_service.dart';
import '../../widgets/telemetry_heatmap.dart';
import '../../services/c1_therapist_service.dart';
import '../../models/c1/c1_therapist_state.dart';
import '../../models/c1/c1_session_summary.dart';
import '../../widgets/c1/c1_index_bar_chart.dart';
import '../../widgets/c1/c1_pattern_card.dart';
import '../../widgets/c1/c1_session_table.dart';
import '../../widgets/c1/c1_therapist_metric_card.dart';
import '../../widgets/c1/c1_sparkline.dart';
import 'package:fl_chart/fl_chart.dart';
class TherapistStudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const TherapistStudentDetailScreen({super.key, required this.student});

  @override
  State<TherapistStudentDetailScreen> createState() => _TherapistStudentDetailScreenState();
}

class _TherapistStudentDetailScreenState extends State<TherapistStudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _analyticsFuture;
  late Future<TherapistC1State?> _c1StateFuture;
  late Future<List<C1SessionSummary>> _c1SessionsFuture;
  late Future<List<Object?>> _combinedFuture;

  // Mock weekly scores (8 weeks) for the chart as we don't have historical arrays yet
  final List<double> _weeklyScores = [42, 48, 45, 55, 52, 60, 63, 68];

  // Mock session history
  final List<Map<String, dynamic>> _sessions = [
    {
      'date': 'ජූලි 28, 2026',
      'duration': 'මිනිත්තු 45',
      'type': 'ශ්‍රව ධ්‍වනිමය දැනුවත්භාවය',
      'score': 78,
      'notes': 'අක්ෂර ඛණ්ඩ කිරීමේ විශිෂ්ට ප්‍රගතිය. ශ්‍රව ධ්‍වනිය ඉවත් කිරීමේ කාර්යයන්හිදී දුෂ්කරතා ඇත.',
    },
    {
      'date': 'ජූලි 25, 2026',
      'duration': 'මිනිත්තු 40',
      'type': 'කියවීමේ ප්‍රවාහය',
      'score': 65,
      'notes': 'මිනිත්තුවකට වචන 42 කියවීය (38 සිට ඉහළ). බහු-අකුරු වචනවලදී ඉවකිරීම් ඇති.',
    },
  ];

  String? _selectedLabel;
  bool _isSubmittingLabel = false;
  bool _isDownloadingReport = false;
  bool _isDownloadingAssessment = false;
  final List<String> _labelOptions = ["low risk", "moderate risk", "needs attention"];

  // Maps backend risk strings to Sinhala for display
  String _translateRisk(String risk) {
    final lower = risk.toLowerCase();
    if (lower.contains('low') || lower.contains('on track')) return LocalizationService.instance.t('risk_low');
    if (lower.contains('moderate') || lower.contains('support')) return LocalizationService.instance.t('risk_moderate');
    if (lower.contains('attention') || lower.contains('high')) return LocalizationService.instance.t('risk_high');
    if (lower.contains('pending')) return LocalizationService.instance.t('risk_pending');
    return risk;
  }

  // Maps backend cognitive index keys to localized display names
  String _translateCognitiveName(String key) {
    // key comes in as 'visual processing score' (after replaceAll('_', ' '))
    final normalized = key.toLowerCase().replaceAll(' ', '_');
    final translated = LocalizationService.instance.t(normalized);
    // If no translation found, return a cleaned-up version
    if (translated == normalized) return key;
    return translated;
  }

  String get _studentId => (widget.student['id'] ?? widget.student['_id']).toString();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _analyticsFuture = StudentService().getCognitiveAnalytics(_studentId);
    _c1StateFuture = C1TherapistService().getState(_studentId);
    _c1SessionsFuture = C1TherapistService().getSessions(_studentId);
    _combinedFuture = Future.wait([_analyticsFuture, _c1StateFuture, _c1SessionsFuture]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _submitLabel() async {
    if (_selectedLabel == null) return;
    
    setState(() => _isSubmittingLabel = true);
    
    final error = await StudentService().submitClinicianLabel(
      _studentId, 
      _selectedLabel!
    );
    
    if (!mounted) return;
    
    setState(() => _isSubmittingLabel = false);
    
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.instance.t('gt_label_success')),
          backgroundColor: AppColors.gentleGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.softCoral,
        ),
      );
    }
  }

  Future<void> _downloadReport() async {
    setState(() => _isDownloadingReport = true);
    final error = await StudentService().downloadClinicalReport(_studentId);
    if (!mounted) return;
    setState(() => _isDownloadingReport = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: AppColors.softCoral,
      ));
    }
  }

  Future<void> _downloadAssessmentReport() async {
    setState(() => _isDownloadingAssessment = true);
    final error = await StudentService().downloadAssessmentReport(_studentId);
    if (!mounted) return;
    setState(() => _isDownloadingAssessment = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: AppColors.softCoral,
      ));
    }
  }

  Future<void> _showHeatmapsModal() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.calmBlue)),
    );

    final telemetryData = await StudentService().getTelemetry(_studentId);
    
    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loading

    if (telemetryData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(LocalizationService.instance.t('no_telemetry_data')),
        backgroundColor: AppColors.softCoral,
      ));
      return;
    }

    Map<String, List<TouchPoint>> activityPoints = {};
    for (var session in telemetryData) {
      final events = session['events'] as List<dynamic>? ?? [];
      for (var ev in events) {
        final actName = ev['activity_name'] as String? ?? 'Unknown';
        final path = ev['touch_path'] as List<dynamic>? ?? [];
        
        if (!activityPoints.containsKey(actName)) {
          activityPoints[actName] = [];
        }
        for (var pt in path) {
          activityPoints[actName]!.add(TouchPoint(
            xRatio: pt['x_ratio']?.toDouble() ?? 0.0,
            yRatio: pt['y_ratio']?.toDouble() ?? 0.0,
            timestampMs: pt['timestamp_ms'] ?? 0,
          ));
        }
      }
    }

    if (activityPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(LocalizationService.instance.t('no_touch_paths')),
        backgroundColor: AppColors.softCoral,
      ));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildHeatmapBottomSheet(activityPoints),
    );
  }

  Widget _buildHeatmapBottomSheet(Map<String, List<TouchPoint>> activityPoints) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC), // scaffold background
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(LocalizationService.instance.t('interaction_heatmaps'),
                      style: AppTypography.heading(fontSize: 20, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: activityPoints.keys.length,
                  itemBuilder: (context, index) {
                    final actName = activityPoints.keys.elementAt(index);
                    final points = activityPoints[actName]!;
                    return HeatmapVisualizer(
                      touchPoints: points,
                      title: '${LocalizationService.instance.t('activity')}: ${LocalizationService.instance.t(actName)}',
                      subtitle: LocalizationService.instance.t('touch_precision_tracking'),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    return ListenableBuilder(
      listenable: LocalizationService.instance,
      builder: (context, _) {
        return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: FutureBuilder<List<Object?>>(
          future: _combinedFuture,
          builder: (context, snapshot) {
            
            String risk = student['risk']?.toString() ?? 'pending';
            Map<String, dynamic> analytics = {};
            TherapistC1State? c1State;
            List<C1SessionSummary> c1Sessions = [];
            
            if (snapshot.hasData) {
              analytics = snapshot.data![0] as Map<String, dynamic>;
              c1State = snapshot.data![1] as TherapistC1State?;
              c1Sessions = snapshot.data![2] as List<C1SessionSummary>;
              
              if (analytics.isNotEmpty && analytics['status'] != 'insufficient_data') {
                if (analytics['risk_assessment'] != null && analytics['risk_assessment'] is Map) {
                  risk = analytics['risk_assessment']['overall_risk']?.toString() ?? risk;
                }
              }
            }

            return Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(LocalizationService.instance.t('student_profile_title'),
                          style: AppTypography.heading(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getRiskColor(risk).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _translateRisk(risk),
                          style: AppTypography.caption(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _getRiskColor(risk),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Student Header Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.calmBlueDark.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.slateBg,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(student['avatar'] ?? '👦', style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['name'] ?? student['first_name'] ?? student['student_name'] ?? 'Unknown',
                                style: AppTypography.heading(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${student['age'] ?? student['grade'] ?? 'N/A'} · ${LocalizationService.instance.t('parent_label')}: ${student['parent'] ?? student['parent_name'] ?? 'N/A'}',
                                style: AppTypography.caption(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${LocalizationService.instance.t('connected_since')} ${student['connected'] ?? student['connected_at']?.toString().split('T')[0] ?? 'N/A'}',
                                style: AppTypography.caption(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Overall Progress Circle
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: (student['progress'] ?? 0) / 100,
                                strokeWidth: 5,
                                backgroundColor: AppColors.borderLight,
                                valueColor: AlwaysStoppedAnimation(_getRiskColor(risk)),
                              ),
                              Text(
                                '${student['progress'] ?? 0}%',
                                style: AppTypography.caption(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.calmBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: AppTypography.caption(fontSize: 13, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: AppTypography.caption(fontSize: 13, fontWeight: FontWeight.w500),
                    tabs: [
                      Tab(text: LocalizationService.instance.t('progress_tab')),
                      Tab(text: LocalizationService.instance.t('sessions_tab')),
                      Tab(text: LocalizationService.instance.t('plan_tab')),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Tab Content
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator(color: AppColors.calmBlue))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildProgressTab(analytics, c1State, c1Sessions),
                            _buildSessionsTab(c1Sessions),
                            _buildPlanTab(analytics),
                          ],
                        ),
                ),
              ],
            );
          }
        ),
      ),
    );
      },
    );
  }

  // ─── Progress Tab (C1 Dashboard) ───
  Widget _buildProgressTab(Map<String, dynamic> analytics, TherapistC1State? c1State, List<C1SessionSummary> sessions) {
    if (c1State == null) {
      return Center(
        child: Text(LocalizationService.instance.t('no_telemetry_data') ?? 'No telemetry data available.',
          style: AppTypography.caption(color: AppColors.textHint, fontSize: 14),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Download Report Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isDownloadingReport ? null : _downloadReport,
              icon: _isDownloadingReport
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: Text(
                _isDownloadingReport
                    ? LocalizationService.instance.t('generating_report')
                    : LocalizationService.instance.t('download_clinical_report'),
                style: AppTypography.body(fontSize: 14, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.calmBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'C1 - Behavioral Monitoring Overview',
            style: AppTypography.heading(fontSize: 18, color: AppColors.textPrimary, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),

          // Top Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              C1TherapistMetricCard(
                title: 'Accuracy',
                value: '${c1State.accuracy.round()}%',
                icon: Icons.check_circle_outline,
                color: Colors.green,
                trendText: '↑ 2% vs last week',
                isTrendUp: true,
              ),
              C1TherapistMetricCard(
                title: 'Response Time',
                value: '${(c1State.medianLatencyMs / 1000).toStringAsFixed(1)}s',
                icon: Icons.timer_outlined,
                color: Colors.blue,
                trendText: '↓ 0.2s vs last week',
                isTrendUp: true,
              ),
              C1TherapistMetricCard(
                title: 'Hesitation',
                value: '${c1State.hesitationRate.round()}%',
                icon: Icons.pause_circle_outline,
                color: Colors.orange,
              ),
              C1TherapistMetricCard(
                title: 'Misclick',
                value: '${c1State.misclickRate.round()}%',
                icon: Icons.touch_app_outlined,
                color: Colors.red,
              ),
              C1TherapistMetricCard(
                title: 'Replay',
                value: '${c1State.replayRate.round()}%',
                icon: Icons.replay,
                color: Colors.purple,
              ),
              C1TherapistMetricCard(
                title: 'Fatigue',
                value: c1State.fatigueStateStr,
                icon: Icons.battery_alert_outlined,
                color: c1State.fatigueStateStr == 'HIGH' ? Colors.red : (c1State.fatigueStateStr == 'MODERATE' ? Colors.orange : Colors.green),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Chart Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Behavioral Metrics Over Sessions',
                  style: AppTypography.body(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: _buildFlChart(sessions),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Learner Indices & Session Summary Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learner Indices',
                        style: AppTypography.body(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      _buildIndexBar('Visual', c1State.visualProcessingIndex, Colors.blue),
                      const SizedBox(height: 12),
                      _buildIndexBar('Phonological', c1State.phonologicalTaskIndex, Colors.orange),
                      const SizedBox(height: 12),
                      _buildIndexBar('Motor', c1State.motorInteractionIndex, Colors.green),
                      const SizedBox(height: 12),
                      _buildIndexBar('Attention', c1State.attentionStabilityIndex, Colors.purple),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Summary',
                        style: AppTypography.body(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('Total Questions', '${c1State.totalQuestions}'),
                      _buildSummaryRow('Correct Answers', '${c1State.correctAnswers}'),
                      _buildSummaryRow('Hesitation Count', '${c1State.hesitationCount}'),
                      _buildSummaryRow('Misclick Count', '${c1State.misclickCount}'),
                      _buildSummaryRow('Replay Count', '${c1State.replayCount}'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Performance Trend (Sparklines)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Trend (Last 7 Sessions)',
                  style: AppTypography.body(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSparklineCol('Accuracy', _extractTrend(sessions, (s) => s.accuracy), Colors.green),
                    _buildSparklineCol('Hesitation', _extractTrend(sessions, (s) => s.hesitationRate), Colors.orange),
                    _buildSparklineCol('Misclicks', _extractTrend(sessions, (s) => s.misclickRate), Colors.red),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildC1ClinicalDetails(c1State), // Keep patterns below
        ],
      ),
    );
  }

  Widget _buildFlChart(List<C1SessionSummary> sessions) {
    if (sessions.isEmpty) return const SizedBox();
    
    List<FlSpot> accSpots = [];
    List<FlSpot> hesSpots = [];
    
    final sorted = List<C1SessionSummary>.from(sessions)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final take = sorted.length > 10 ? sorted.sublist(sorted.length - 10) : sorted;
    
    for (int i = 0; i < take.length; i++) {
      accSpots.add(FlSpot(i.toDouble(), take[i].accuracy));
      hesSpots.add(FlSpot(i.toDouble(), take[i].hesitationRate));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                if (val.toInt() >= 0 && val.toInt() < take.length) {
                  return Text('S${val.toInt() + 1}', style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: accSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: FlDotData(show: false),
          ),
          LineChartBarData(
            spots: hesSpots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  List<double> _extractTrend(List<C1SessionSummary> sessions, double Function(C1SessionSummary) extractor) {
    final sorted = List<C1SessionSummary>.from(sessions)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final take = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
    if (take.isEmpty) return [0, 0];
    if (take.length == 1) return [extractor(take[0]), extractor(take[0])];
    return take.map(extractor).toList();
  }

  Widget _buildIndexBar(String label, double value, Color color) {
    // Normalize if > 1
    double barVal = value > 1.0 ? 1.0 : (value < 0 ? 0.0 : value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('${(value * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: barVal,
            minHeight: 6,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  // ─── C1 Clinical Details ───
  Widget _buildC1ClinicalDetails(TherapistC1State? c1State) {
    if (c1State == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocalizationService.instance.t('c1_behavioral_state') ?? 'Behavioral Learner-State (C1)',
          style: AppTypography.body(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (c1State.indices.isNotEmpty) ...[
          C1IndexBarChart(
            visualProcessing: c1State.visualProcessingIndex,
            phonological: c1State.phonologicalTaskIndex,
            motor: c1State.motorInteractionIndex,
            attention: c1State.attentionStabilityIndex,
          ),
          const SizedBox(height: 16),
        ],
        if (c1State.pattern != 'UNKNOWN') ...[
          Text('Detected Patterns',
            style: AppTypography.body(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          C1PatternCard(
            pattern: c1State.pattern,
            probability: c1State.patternProbability,
            confidence: c1State.model['confidence'] ?? 'Medium',
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSparklineCol(String title, List<double> data, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          height: 40,
          child: C1Sparkline(data: data, color: color, lineWidth: 2),
        ),
      ],
    );
  }

  // ─── Sessions Tab ───
  Widget _buildSessionsTab(List<C1SessionSummary> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Text(LocalizationService.instance.t('no_sessions_yet') ?? 'No sessions yet',
          style: AppTypography.caption(color: AppColors.textHint, fontSize: 14),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: C1SessionTable(
        sessions: sessions,
        onSessionTapped: (sessionId) {
          // TODO: Navigate to session detail
        },
      ),
    );
  }

  // ─── Intervention Plan Tab ───
  Widget _buildPlanTab(Map<String, dynamic> analytics) {
    List<dynamic> interventions = analytics['recommendations'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinical Labeling Form for ML Pipeline
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: AppColors.calmBlueDark.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_outlined, color: AppColors.calmBlue, size: 24),
                    const SizedBox(width: 8),
                    Text(LocalizationService.instance.t('provide_clinical_label'),
                      style: AppTypography.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(LocalizationService.instance.t('assessment_feeds_ml'),
                  style: AppTypography.caption(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLabel,
                      hint: Text(LocalizationService.instance.t('select_risk_label'),
                        style: AppTypography.caption(fontSize: 14, color: AppColors.textHint),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                      items: _labelOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            _translateRisk(value),
                            style: AppTypography.body(fontSize: 14, color: AppColors.textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedLabel = newValue;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmittingLabel || _selectedLabel == null ? null : _submitLabel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.calmBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSubmittingLabel
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : Text(LocalizationService.instance.t('submit_gt_label'),
                            style: AppTypography.body(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(LocalizationService.instance.t('recommended_interventions'),
            style: AppTypography.body(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (interventions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(LocalizationService.instance.t('no_interventions'),
                  textAlign: TextAlign.center,
                  style: AppTypography.caption(color: AppColors.textHint, fontSize: 14),
                ),
              ),
            ),

          ...interventions.map((intervention) {
            final type = intervention['type'] ?? 'general';
            final title = intervention['title'] ?? LocalizationService.instance.t('strategy');
            final description = intervention['description'] ?? '';
            
            // Map type to visual
            Color cardColor = AppColors.calmBlue;
            IconData cardIcon = Icons.lightbulb_outline_rounded;
            
            if (type == 'cognitive') {
              cardColor = AppColors.warmAmber;
              cardIcon = Icons.psychology_alt_rounded;
            } else if (type == 'sensory') {
              cardColor = AppColors.softCoral;
              cardIcon = Icons.visibility_rounded;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.calmBlueDark.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cardIcon, color: cardColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            type,
                            style: AppTypography.caption(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cardColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: AppTypography.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: AppTypography.caption(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _getRiskColor(String risk) {
    if (risk.toLowerCase().contains('on track') || risk.toLowerCase().contains('low')) {
      return AppColors.gentleGreen;
    } else if (risk.toLowerCase().contains('moderate') || risk.toLowerCase().contains('support')) {
      return AppColors.warmAmber;
    } else {
      return AppColors.softCoral;
    }
  }

  Color _getSkillColor(double value) {
    if (value >= 0.7) return AppColors.gentleGreen;
    if (value >= 0.55) return AppColors.warmAmber;
    return AppColors.softCoral;
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return AppColors.gentleGreen;
    if (score >= 55) return AppColors.warmAmber;
    return AppColors.softCoral;
  }
}

// ─── Custom Chart Painter ───
class _ChartPainter extends CustomPainter {
  final List<double> scores;

  _ChartPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final maxScore = scores.reduce(max);
    final minScore = scores.reduce(min);
    final range = maxScore - minScore;

    final points = <Offset>[];
    for (int i = 0; i < scores.length; i++) {
      final x = (i / (scores.length - 1)) * size.width;
      final y = size.height - ((scores[i] - minScore) / (range == 0 ? 1 : range)) * (size.height - 20) - 10;
      points.add(Offset(x, y));
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 0.5;

    for (int i = 0; i < 4; i++) {
      final y = (i / 3) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Gradient fill
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x334A90D9), Color(0x004A90D9)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFF4A90D9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    final dotPaint = Paint()..color = const Color(0xFF4A90D9);
    final dotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 4, dotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

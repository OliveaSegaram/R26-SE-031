import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class TelemetryDebugScreen extends StatefulWidget {
  const TelemetryDebugScreen({super.key});

  @override
  State<TelemetryDebugScreen> createState() => _TelemetryDebugScreenState();
}

class _TelemetryDebugScreenState extends State<TelemetryDebugScreen> {
  List<TelemetryEvent> _events = [];

  @override
  void initState() {
    super.initState();
    // Get all events from the current session
    _events = TelemetryService().sessionEvents;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetry Dashboard (Debug)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _events.isEmpty
          ? const Center(child: Text("No telemetry data for this session yet."))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCurrentActivitySection(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Divider(thickness: 2),
                  ),
                  _buildOverallSkillSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentActivitySection() {
    final currentActivityName = _events.last.activityName;
    final currentEvents = _events.where((e) => e.activityName == currentActivityName).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Current Activity: $currentActivityName",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        _buildSummaryCards(currentEvents),
        const SizedBox(height: 24),
        _buildCharts(currentEvents, "Activity"),
        const SizedBox(height: 24),
        _buildDataTable(currentEvents),
      ],
    );
  }

  Widget _buildOverallSkillSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Overall Skill Performance",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        _buildSummaryCards(_events),
        const SizedBox(height: 24),
        _buildCharts(_events, "Overall"),
        const SizedBox(height: 24),
        _buildDataTable(_events),
      ],
    );
  }

  Widget _buildSummaryCards(List<TelemetryEvent> events) {
    final abandonedCount = events.where((e) => e.isAbandoned).length;
    final totalRounds = events.length;
    
    int totalLatency = 0;
    int totalAudioReplays = 0;
    final activityStarts = <String, int>{};
    
    for (var e in events) {
      totalLatency += e.totalRoundLatencyMs;
      totalAudioReplays += e.audioReplayCount;
      if (e.roundNumber == 1) {
        activityStarts[e.activityName] = (activityStarts[e.activityName] ?? 0) + 1;
      }
    }
    final avgLatency = totalRounds > 0 ? (totalLatency / totalRounds / 1000).toStringAsFixed(1) : '0';

    int activityReplays = 0;
    for (var starts in activityStarts.values) {
      if (starts > 1) {
        activityReplays += (starts - 1);
      }
    }

    return Column(
      children: [
        Row(
          children: [
            _summaryCard('Rounds', '$totalRounds', Icons.gamepad),
            const SizedBox(width: 8),
            _summaryCard('Avg Time (s)', avgLatency, Icons.timer),
            const SizedBox(width: 8),
            _summaryCard('Act. Replays', '$activityReplays', Icons.replay_circle_filled, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _summaryCard('Abandonments', '$abandonedCount', Icons.exit_to_app, color: AppColors.softCoral),
            const SizedBox(width: 8),
            _summaryCard('Audio Replays', '$totalAudioReplays', Icons.volume_up, color: AppColors.warmAmber),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox()),
          ],
        )
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? AppColors.calmBlue),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts(List<TelemetryEvent> events, String titlePrefix) {
    if (events.length < 2) {
      return const Text("Need at least 2 rounds to show charts.");
    }

    final scoreSpots = <FlSpot>[];
    final latencySpots = <FlSpot>[];
    
    for (int i = 0; i < events.length; i++) {
      scoreSpots.add(FlSpot(i.toDouble(), events[i].score.toDouble()));
      latencySpots.add(FlSpot(i.toDouble(), events[i].totalRoundLatencyMs / 1000.0));
    }

    return Column(
      children: [
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              Text("$titlePrefix Score", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: scoreSpots,
                        isCurved: false,
                        color: AppColors.gentleGreen,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              Text("$titlePrefix Latency (s)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    lineBarsData: [
                      LineChartBarData(
                        spots: latencySpots,
                        isCurved: false,
                        color: AppColors.warmAmber,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<TelemetryEvent> events) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Activity')),
            DataColumn(label: Text('Round')),
            DataColumn(label: Text('Score')),
            DataColumn(label: Text('Latency (s)')),
            DataColumn(label: Text('Misclicks')),
            DataColumn(label: Text('Hesitations')),
            DataColumn(label: Text('Audio Replays')),
            DataColumn(label: Text('Abandoned')),
          ],
          rows: events.map((e) {
            return DataRow(
              cells: [
                DataCell(Text(e.activityName)),
                DataCell(Text('${e.roundNumber}')),
                DataCell(Text('${e.score}')),
                DataCell(Text((e.totalRoundLatencyMs / 1000).toStringAsFixed(1))),
                DataCell(Text('${e.misclickCount}')),
                DataCell(Text('${e.hesitationCount}')),
                DataCell(Text('${e.audioReplayCount}')),
                DataCell(Text(e.isAbandoned ? 'Yes' : 'No')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

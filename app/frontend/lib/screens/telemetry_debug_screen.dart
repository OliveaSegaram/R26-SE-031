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
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildCharts(),
                  const SizedBox(height: 24),
                  _buildDataTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final now = DateTime.now();
    final abandonedCount = _events.where((e) => e.isAbandoned).length;
    final totalRounds = _events.length;
    
    int totalLatency = 0;
    for (var e in _events) {
      totalLatency += e.totalRoundLatencyMs;
    }
    final avgLatency = totalRounds > 0 ? (totalLatency / totalRounds / 1000).toStringAsFixed(1) : '0';

    return Row(
      children: [
        _summaryCard('Date & Time', DateFormat('yyyy-MM-dd HH:mm').format(now), Icons.calendar_today),
        const SizedBox(width: 8),
        _summaryCard('Rounds Logged', '$totalRounds', Icons.gamepad),
        const SizedBox(width: 8),
        _summaryCard('Avg Time (s)', avgLatency, Icons.timer),
        const SizedBox(width: 8),
        _summaryCard('Abandonments', '$abandonedCount', Icons.exit_to_app, color: AppColors.softCoral),
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

  Widget _buildCharts() {
    if (_events.length < 2) {
      return const Text("Need at least 2 rounds to show charts.");
    }

    final scoreSpots = <FlSpot>[];
    final latencySpots = <FlSpot>[];
    
    for (int i = 0; i < _events.length; i++) {
      scoreSpots.add(FlSpot(i.toDouble(), _events[i].score.toDouble()));
      latencySpots.add(FlSpot(i.toDouble(), _events[i].totalRoundLatencyMs / 1000.0));
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Text("Score vs Time (s)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: scoreSpots,
                    isCurved: true,
                    color: AppColors.gentleGreen,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: latencySpots,
                    isCurved: true,
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
    );
  }

  Widget _buildDataTable() {
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
            DataColumn(label: Text('Max Motion')),
            DataColumn(label: Text('Abandoned')),
          ],
          rows: _events.map((e) {
            return DataRow(
              cells: [
                DataCell(Text(e.activityName)),
                DataCell(Text('${e.roundNumber}')),
                DataCell(Text('${e.score}')),
                DataCell(Text((e.totalRoundLatencyMs / 1000).toStringAsFixed(1))),
                DataCell(Text('${e.misclickCount}')),
                DataCell(Text('${e.hesitationCount}')),
                DataCell(Text('${e.audioReplayCount}')),
                DataCell(Text(e.maxDeviceMotion.toStringAsFixed(2))),
                DataCell(Text(e.isAbandoned ? 'Yes' : 'No')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

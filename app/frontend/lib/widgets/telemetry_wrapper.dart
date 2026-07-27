import 'package:flutter/material.dart';
import '../services/telemetry_service.dart';
import '../services/telemetry/plugins/voice_analysis_plugin.dart';
import '../services/telemetry/plugins/eye_tracking_plugin.dart';
import '../models/curriculum_models.dart';
import '../screens/activity_complete_screen.dart';
import '../screens/games/game_factory.dart';

/// A wrapper widget that tracks all touch events, latency, and coordinates
/// before they reach the underlying game template.
///
/// Enhanced metrics captured per round:
///  - [firstTouchLatencyMs] — time from round start to first tap
///  - [totalRoundLatencyMs] — full time from round start to completion
///  - [misclickCount] — taps outside target areas (game must call [recordMisclick])
///  - [hesitationCount] — pauses > 2s without any touch
///  - [touchPath]       — normalized (x%, y%) coordinates for each touch
class TelemetryWrapper extends StatefulWidget {
  final ActivityNode activityNode;
  final Widget child;
  final Function(int score) onRoundComplete;

  const TelemetryWrapper({
    super.key,
    required this.activityNode,
    required this.child,
    required this.onRoundComplete,
  });

  @override
  State<TelemetryWrapper> createState() => TelemetryWrapperState();
}

class TelemetryWrapperState extends State<TelemetryWrapper> {
  // ---- Timing ----
  late Stopwatch _roundStopwatch;
  late Stopwatch _hesitationStopwatch;

  // ---- Rich metric accumulators ----
  final List<TouchPoint> _currentTouchPath = [];
  int _firstTouchLatencyMs = -1;    // -1 = no touch received yet this round
  int _misclickCount = 0;
  int _hesitationCount = 0;
  bool _firstTouchRecorded = false;

  // ---- Session accumulators ----
  int _totalScore = 0;
  int _roundsCompletedTotal = 0;
  int _currentRound = 1;

  // ---- Hesitation timer ----
  static const int _hesitationThresholdMs = 2000;

  @override
  void initState() {
    super.initState();
    _roundStopwatch = Stopwatch()..start();
    _hesitationStopwatch = Stopwatch()..start();
    _initPluginsOnce();

    TelemetryService().broadcastRoundStart(
      widget.activityNode.templateType,
      _currentRound,
      widget.activityNode.telemetryTags,
    );
  }

  @override
  void dispose() {
    _roundStopwatch.stop();
    _hesitationStopwatch.stop();
    super.dispose();
  }

  void _initPluginsOnce() {
    if (TelemetryService().isPluginRegistered('voice_analysis_v1')) return;

    final voicePlugin = VoiceAnalysisPlugin()..setEnabled(true);
    final eyePlugin = EyeTrackingPlugin()..setEnabled(false);

    TelemetryService().registerPlugin(voicePlugin);
    TelemetryService().registerPlugin(eyePlugin);
  }

  /// Called by the transparent Listener widget on every pointer event.
  void _recordTouch(PointerEvent details, Size screenSize) {
    // Check for hesitation since last touch
    if (_hesitationStopwatch.elapsedMilliseconds > _hesitationThresholdMs) {
      _hesitationCount++;
      debugPrint('TELEMETRY: Hesitation detected (${_hesitationStopwatch.elapsedMilliseconds} ms).');
    }
    _hesitationStopwatch.reset();
    _hesitationStopwatch.start();

    // Capture first-touch latency
    if (!_firstTouchRecorded) {
      _firstTouchLatencyMs = _roundStopwatch.elapsedMilliseconds;
      _firstTouchRecorded = true;
      debugPrint('TELEMETRY: First touch at $_firstTouchLatencyMs ms.');
    }

    // Record normalized touch point
    final xRatio = screenSize.width > 0
        ? (details.position.dx / screenSize.width).clamp(0.0, 1.0)
        : 0.0;
    final yRatio = screenSize.height > 0
        ? (details.position.dy / screenSize.height).clamp(0.0, 1.0)
        : 0.0;

    _currentTouchPath.add(TouchPoint(
      xRatio: double.parse(xRatio.toStringAsFixed(3)),
      yRatio: double.parse(yRatio.toStringAsFixed(3)),
      timestampMs: _roundStopwatch.elapsedMilliseconds,
    ));

    TelemetryService().broadcastPointerEvent(details);
  }

  /// Game activities should call this when the child taps a non-target area.
  void recordMisclick() {
    _misclickCount++;
    debugPrint('TELEMETRY: Misclick recorded (total: $_misclickCount).');
  }

  /// Called by individual game activities when a round is completed.
  void completeRound(int score) {
    _roundStopwatch.stop();
    final totalRoundLatency = _roundStopwatch.elapsedMilliseconds;

    _totalScore += score;
    _roundsCompletedTotal++;

    // Build and log the rich telemetry event
    final event = TelemetryEvent(
      activityName: widget.activityNode.templateType,
      roundNumber: _currentRound,
      isCorrect: score > 0,
      score: score,
      timestamp: DateTime.now(),
      firstTouchLatencyMs: _firstTouchLatencyMs >= 0 ? _firstTouchLatencyMs : 0,
      totalRoundLatencyMs: totalRoundLatency,
      misclickCount: _misclickCount,
      hesitationCount: _hesitationCount,
      touchPath: List.unmodifiable(_currentTouchPath),
    );

    TelemetryService().broadcastRoundComplete(score, totalRoundLatency);
    TelemetryService().logInteraction(event);

    debugPrint(
      'TELEMETRY: Round $_currentRound | '
      'Correct: ${score > 0} | '
      'Score: $score | '
      'First-Touch: ${event.firstTouchLatencyMs}ms | '
      'Total: ${totalRoundLatency}ms | '
      'Misclicks: $_misclickCount | '
      'Hesitations: $_hesitationCount | '
      'Touch points: ${_currentTouchPath.length}',
    );

    // Forward to game loop
    widget.onRoundComplete(score);

    // Reset for next round
    _currentRound++;
    _currentTouchPath.clear();
    _firstTouchLatencyMs = -1;
    _firstTouchRecorded = false;
    _misclickCount = 0;
    _hesitationCount = 0;
    _roundStopwatch.reset();
    _roundStopwatch.start();
    _hesitationStopwatch.reset();
    _hesitationStopwatch.start();

    TelemetryService().broadcastRoundStart(
      widget.activityNode.templateType,
      _currentRound,
      widget.activityNode.telemetryTags,
    );
  }

  /// Called after all rounds are completed to show the completion screen.
  void completeActivity(BuildContext context) {
    int finalScore = 0;
    if (_roundsCompletedTotal > 0) {
      finalScore = (_totalScore / _roundsCompletedTotal).round().clamp(0, 100);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityCompleteScreen(
          activityNode: widget.activityNode,
          skillId: widget.activityNode.id,
          score: finalScore,
          isRevisiting: false,
          onRetake: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GameFactory.buildGame(widget.activityNode),
              ),
            );
          },
          onContinue: () {
            Navigator.pop(context, finalScore);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Listener(
      onPointerDown: (e) => _recordTouch(e, screenSize),
      onPointerMove: (e) => _recordTouch(e, screenSize),
      child: widget.child,
    );
  }
}

import 'package:flutter/material.dart';
import '../services/telemetry_service.dart';
import '../services/telemetry/plugins/voice_analysis_plugin.dart';
import '../services/telemetry/plugins/eye_tracking_plugin.dart';
import '../models/curriculum_models.dart';

/// A wrapper widget that tracks all touch events, latency, and coordinates
/// before they reach the underlying game template.
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
  late Stopwatch _stopwatch;
  final List<Offset> _touches = [];
  int _currentRound = 1;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _initPluginsOnce();
    
    // Broadcast the start of the first round
    TelemetryService().broadcastRoundStart(
      widget.activityNode.templateType, 
      _currentRound, 
      widget.activityNode.telemetryTags,
    );
  }
  
  void _initPluginsOnce() {
    // Check if they are already registered to avoid duplicates
    if (TelemetryService().isPluginRegistered('voice_analysis_v1')) return;

    final voicePlugin = VoiceAnalysisPlugin()..setEnabled(true);
    final eyePlugin = EyeTrackingPlugin()..setEnabled(false); // User requested basic/off for now

    TelemetryService().registerPlugin(voicePlugin);
    TelemetryService().registerPlugin(eyePlugin);
  }

  void _recordTouch(PointerEvent details) {
    _touches.add(details.position);
    TelemetryService().broadcastPointerEvent(details);
  }

  void completeRound(int score) {
    _stopwatch.stop();
    final latency = _stopwatch.elapsedMilliseconds;
    
    // Broadcast the round completion to all plugins (including Voice, Eye Tracking, etc)
    TelemetryService().broadcastRoundComplete(score, latency);
    
    // Log the generic telemetry event to the main service
    TelemetryService().logInteraction(
      activityName: widget.activityNode.templateType,
      roundNumber: _currentRound,
      isCorrect: score > 0,
    );
    
    debugPrint('TELEMETRY: Round $_currentRound Completed in $latency ms with score $score.');
    debugPrint('TELEMETRY: Captured ${_touches.length} distinct touch events.');
    
    // Forward the completion to the game loop
    widget.onRoundComplete(score);
    
    // Reset for next round
    _currentRound++;
    _touches.clear();
    _stopwatch.reset();
    _stopwatch.start();
    
    TelemetryService().broadcastRoundStart(
      widget.activityNode.templateType, 
      _currentRound, 
      widget.activityNode.telemetryTags,
    );
  }

  @override
  Widget build(BuildContext context) {
    // We wrap the child in an Inherited widget or just a Listener 
    // so the child can call `context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(score)`
    return Listener(
      onPointerDown: _recordTouch,
      onPointerMove: _recordTouch,
      child: widget.child,
    );
  }
}

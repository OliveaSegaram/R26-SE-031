import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../telemetry_plugin.dart';

class VoiceAnalysisPlugin implements ITelemetryPlugin {
  @override
  final String pluginId = 'voice_analysis_v1';
  
  bool _isEnabled = false;

  @override
  bool get isEnabled => _isEnabled;

  @override
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    debugPrint('[$pluginId] Plugin enabled: $enabled');
  }

  @override
  Future<void> initialize() async {
    // In the future: initialize Vosk / Speech-to-Text / Audio capture here
    debugPrint('[$pluginId] Initialized.');
  }

  @override
  void onRoundStart(String activityName, int roundNumber, List<String> tags) {
    if (!_isEnabled) return;
    
    // Only capture voice if the activity is explicitly tagged for it
    if (tags.contains('speaking') || tags.contains('reading')) {
      debugPrint('[$pluginId] Started recording audio for $activityName Round $roundNumber');
    }
  }

  @override
  void onPointerEvent(PointerEvent event) {
    // Voice plugin ignores touch events
  }

  @override
  void onRoundComplete(int score, int latencyMs) {
    if (!_isEnabled) return;
    debugPrint('[$pluginId] Stopped recording. Analyzing audio chunk for hesitation/pronunciation...');
    // Future: Send captured audio chunk to Whisper API or local model
  }

  @override
  void dispose() {
    debugPrint('[$pluginId] Disposed.');
  }
}

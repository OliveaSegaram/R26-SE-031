import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../telemetry_plugin.dart';

class EyeTrackingPlugin implements ITelemetryPlugin {
  @override
  final String pluginId = 'eye_tracking_gazecloud';
  
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
    // Future integration with GazeCloud API:
    // https://gazerecorder.com/gazecloudapi/
    // Since GazeCloud is JS-based, we would use js_interop on Flutter Web,
    // or a WebView / Native channel on Mobile.
    debugPrint('[$pluginId] Initialized GazeCloud API stub.');
  }

  @override
  void onRoundStart(String activityName, int roundNumber, List<String> tags) {
    if (!_isEnabled) return;
    debugPrint('[$pluginId] Started gaze tracking for $activityName Round $roundNumber');
    // Call GazeCloudAPI.StartEyeTracking()
  }

  @override
  void onPointerEvent(PointerEvent event) {
    // Eye tracking can run alongside pointer events to correlate gaze vs touch
  }

  @override
  void onRoundComplete(int score, int latencyMs) {
    if (!_isEnabled) return;
    debugPrint('[$pluginId] Stopped gaze tracking. Saving heatmap/fixation data.');
    // Call GazeCloudAPI.StopEyeTracking()
  }

  @override
  void dispose() {
    debugPrint('[$pluginId] Disposed.');
  }
}

import 'package:flutter/material.dart';

/// The base interface for any telemetry plugin (e.g. Eye Tracking, Voice, Touch).
abstract class ITelemetryPlugin {
  /// Unique identifier for the plugin
  String get pluginId;
  
  /// Whether the plugin is currently enabled
  bool get isEnabled;

  /// Enable or disable the plugin dynamically (e.g. for performance)
  void setEnabled(bool enabled);

  /// Called when a new activity/round begins
  void onRoundStart(String activityName, int roundNumber, List<String> tags);

  /// Called when a pointer event (touch/drag) is registered on the screen
  void onPointerEvent(PointerEvent event);

  /// Called when a round completes
  void onRoundComplete(int score, int latencyMs);
  
  /// Initialize the plugin resources (e.g. start camera, load models)
  Future<void> initialize();

  /// Dispose of any resources (e.g. stop recording)
  void dispose();
}

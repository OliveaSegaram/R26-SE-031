import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For PointerEvent
import 'package:shared_preferences/shared_preferences.dart';
import 'telemetry/telemetry_plugin.dart';
import 'student_service.dart';

// ---------------------------------------------------------------------------
// Rich Touch Point — normalized screen-relative coordinates with timestamp
// ---------------------------------------------------------------------------
class TouchPoint {
  final double xRatio;
  final double yRatio;
  final int timestampMs;

  const TouchPoint({
    required this.xRatio,
    required this.yRatio,
    required this.timestampMs,
  });

  Map<String, dynamic> toJson() => {
        'x_ratio': xRatio,
        'y_ratio': yRatio,
        'timestamp_ms': timestampMs,
      };
}

// ---------------------------------------------------------------------------
// TelemetryEvent — enriched with dyslexia/motor diagnostic metrics
// ---------------------------------------------------------------------------
class TelemetryEvent {
  final String activityName;
  final int roundNumber;
  final bool isCorrect;
  final int score;
  final DateTime timestamp;

  /// Time from round display to the FIRST screen touch (cognitive processing speed)
  final int firstTouchLatencyMs;

  /// Total time taken for the full round
  final int totalRoundLatencyMs;

  /// Number of taps outside interactive target boundaries (motor precision)
  final int misclickCount;

  /// Number of >2s pauses with no screen touch (hesitation / reading difficulty)
  final int hesitationCount;

  /// Normalized (x%, y%) touch path captured during the round
  final List<TouchPoint> touchPath;

  const TelemetryEvent({
    required this.activityName,
    required this.roundNumber,
    required this.isCorrect,
    required this.score,
    required this.timestamp,
    required this.firstTouchLatencyMs,
    required this.totalRoundLatencyMs,
    required this.misclickCount,
    required this.hesitationCount,
    required this.touchPath,
  });

  Map<String, dynamic> toJson() => {
        'activity_name': activityName,
        'round_number': roundNumber,
        'is_correct': isCorrect,
        'score': score,
        'timestamp': timestamp.toIso8601String(),
        'first_touch_latency_ms': firstTouchLatencyMs,
        'total_round_latency_ms': totalRoundLatencyMs,
        'misclick_count': misclickCount,
        'hesitation_count': hesitationCount,
        'touch_path': touchPath.map((p) => p.toJson()).toList(),
      };
}

// ---------------------------------------------------------------------------
// TelemetryService — singleton managing session events & cloud submission
// ---------------------------------------------------------------------------
class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  static const String _offlineQueueKey = 'pending_telemetry_queue';

  final List<TelemetryEvent> _sessionEvents = [];
  DateTime? _sessionStartTime;

  // Plugin Management
  final List<ITelemetryPlugin> _plugins = [];

  bool isPluginRegistered(String pluginId) {
    return _plugins.any((p) => p.pluginId == pluginId);
  }

  void registerPlugin(ITelemetryPlugin plugin) {
    if (isPluginRegistered(plugin.pluginId)) return;
    _plugins.add(plugin);
    plugin.initialize();
    debugPrint('Telemetry: Registered plugin ${plugin.pluginId}');
  }

  void startSession() {
    _sessionStartTime = DateTime.now();
    _sessionEvents.clear();
    debugPrint('Telemetry: Session started');
  }

  /// Mark the start of a specific named activity within a session.
  /// Called by [SessionContainerScreen] before each activity is launched.
  void startActivity(String activityName) {
    debugPrint('Telemetry: Activity started — $activityName');
  }

  void broadcastRoundStart(String activityName, int roundNumber, List<String> tags) {
    for (var plugin in _plugins) {
      plugin.onRoundStart(activityName, roundNumber, tags);
    }
  }

  void broadcastPointerEvent(PointerEvent event) {
    for (var plugin in _plugins) {
      plugin.onPointerEvent(event);
    }
  }

  void broadcastRoundComplete(int score, int latencyMs) {
    for (var plugin in _plugins) {
      plugin.onRoundComplete(score, latencyMs);
    }
  }

  /// Log a fully-enriched round interaction event.
  void logInteraction(TelemetryEvent event) {
    _sessionEvents.add(event);
    debugPrint('Telemetry log: ${jsonEncode(event.toJson())}');
  }

  /// Submit current session's telemetry to the backend.
  /// On network failure, payload is saved to an offline queue in SharedPreferences.
  Future<void> endSessionAndSubmit(String studentId) async {
    if (_sessionEvents.isEmpty) return;

    final totalDuration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 0;

    final payload = {
      'student_id': studentId,
      'session_duration_seconds': totalDuration,
      'events': _sessionEvents.map((e) => e.toJson()).toList(),
    };

    debugPrint('Telemetry: Submitting session (${_sessionEvents.length} events)...');

    try {
      final error = await StudentService().submitTelemetry(payload);
      if (error != null) {
        debugPrint('Telemetry network error — queuing for later retry: $error');
        await _enqueueOffline(payload);
      } else {
        debugPrint('Telemetry submitted successfully.');
      }
    } catch (e) {
      debugPrint('Telemetry exception — queuing offline: $e');
      await _enqueueOffline(payload);
    }

    _sessionEvents.clear();

    // Attempt to flush any previously queued offline payloads
    await flushOfflineQueue(studentId);
  }

  /// Save a failed submission payload into the local offline queue.
  Future<void> _enqueueOffline(Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_offlineQueueKey) ?? [];
      existing.add(jsonEncode(payload));
      await prefs.setStringList(_offlineQueueKey, existing);
      debugPrint('Telemetry: Queued offline payload (queue size: ${existing.length}).');
    } catch (e) {
      debugPrint('Telemetry: Failed to save offline queue: $e');
    }
  }

  /// Attempt to flush all offline-queued telemetry payloads to the backend.
  Future<void> flushOfflineQueue(String studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_offlineQueueKey) ?? [];
      if (queue.isEmpty) return;

      debugPrint('Telemetry: Flushing ${queue.length} offline payload(s)...');
      final remaining = <String>[];

      for (final raw in queue) {
        final payload = jsonDecode(raw) as Map<String, dynamic>;
        final error = await StudentService().submitTelemetry(payload);
        if (error != null) {
          remaining.add(raw); // still offline — keep in queue
        } else {
          debugPrint('Telemetry: Offline payload flushed successfully.');
        }
      }

      await prefs.setStringList(_offlineQueueKey, remaining);
    } catch (e) {
      debugPrint('Telemetry: Offline flush error: $e');
    }
  }
}

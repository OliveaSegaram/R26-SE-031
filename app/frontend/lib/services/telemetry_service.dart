import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For PointerEvent
import 'telemetry/telemetry_plugin.dart';
import 'student_service.dart';

class TelemetryEvent {
  final String activityName;
  final int? roundNumber;
  final bool isCorrect;
  final DateTime timestamp;
  final int timeSinceStartMs;

  TelemetryEvent({
    required this.activityName,
    this.roundNumber,
    required this.isCorrect,
    required this.timestamp,
    required this.timeSinceStartMs,
  });

  Map<String, dynamic> toJson() => {
        'activity_name': activityName,
        'round_number': roundNumber,
        'is_correct': isCorrect,
        'timestamp': timestamp.toIso8601String(),
        'time_since_start_ms': timeSinceStartMs,
      };
}

class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  final List<TelemetryEvent> _sessionEvents = [];
  DateTime? _sessionStartTime;
  DateTime? _activityStartTime;

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

  void startActivity(String activityName) {
    _activityStartTime = DateTime.now();
    debugPrint('Telemetry: Activity started - $activityName');
  }

  void broadcastRoundStart(String activityName, int roundNumber, List<String> tags) {
    _activityStartTime = DateTime.now();
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

  void logInteraction({required String activityName, int? roundNumber, required bool isCorrect}) {
    if (_activityStartTime == null) return;
    
    final now = DateTime.now();
    final timeSinceStart = now.difference(_activityStartTime!).inMilliseconds;
    
    final event = TelemetryEvent(
      activityName: activityName,
      roundNumber: roundNumber,
      isCorrect: isCorrect,
      timestamp: now,
      timeSinceStartMs: timeSinceStart,
    );
    
    _sessionEvents.add(event);
    debugPrint('Telemetry log: ${event.toJson()}');
  }

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

    debugPrint('Telemetry: Submitting session data: \n${jsonEncode(payload)}');
    
    try {
      final error = await StudentService().submitTelemetry(payload);
      if (error != null) {
        debugPrint('Telemetry Submission Error: $error');
      } else {
        debugPrint('Telemetry submitted successfully.');
      }
    } catch (e) {
      debugPrint('Telemetry Exception: $e');
    }

    _sessionEvents.clear();
  }
}

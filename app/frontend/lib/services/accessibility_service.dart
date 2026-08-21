import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global service managing Neuroinclusive Accessibility settings.
class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  // ValueNotifiers allow the UI to rebuild instantly when a setting changes
  final ValueNotifier<bool> useDyslexicFont = ValueNotifier(false);
  final ValueNotifier<bool> highContrastMode = ValueNotifier(false);
  final ValueNotifier<bool> relaxedTimeLimits = ValueNotifier(false);

  bool _isInitialized = false;

  /// Loads the saved preferences from disk
  Future<void> init() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    useDyslexicFont.value = prefs.getBool('acc_dyslexic_font') ?? false;
    highContrastMode.value = prefs.getBool('acc_high_contrast') ?? false;
    relaxedTimeLimits.value = prefs.getBool('acc_relaxed_time') ?? false;

    _isInitialized = true;
  }

  /// Toggles the OpenDyslexic font setting
  Future<void> setDyslexicFont(bool value) async {
    useDyslexicFont.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acc_dyslexic_font', value);
  }

  /// Toggles the High Contrast UI setting
  Future<void> setHighContrastMode(bool value) async {
    highContrastMode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acc_high_contrast', value);
  }

  /// Toggles the Relaxed Time Limits setting (disables game countdowns)
  Future<void> setRelaxedTimeLimits(bool value) async {
    relaxedTimeLimits.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acc_relaxed_time', value);
  }
}

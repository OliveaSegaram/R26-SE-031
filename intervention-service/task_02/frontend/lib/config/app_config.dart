import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Backend URL for Task 02 API + TTS.
///
/// Phone / tablet (same Wi‑Fi as PC):
///   flutter run --dart-define=API_BASE=http://192.168.1.10:8000
class AppConfig {
  static const String _fromDefine = String.fromEnvironment('API_BASE');

  static String? manualOverride;

  static String get baseUrl {
    final custom = (manualOverride ?? _fromDefine).trim();
    if (custom.isNotEmpty) {
      return custom.replaceAll(RegExp(r'/+$'), '');
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator → host machine (use --dart-define on a real phone)
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}

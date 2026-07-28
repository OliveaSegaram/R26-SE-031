import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  TtsService._internal() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4); // Slower, clear speech for Grade 1
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.2); // Slightly higher pitch to sound friendly
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await _initTts();
    }
    await _flutterTts.stop(); // Stop any ongoing speech
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

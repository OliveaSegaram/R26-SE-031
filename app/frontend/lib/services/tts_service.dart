import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  // Toggle this to 'true' before building the final APK for deployment
  static const bool _isProduction = false;

  String get _baseUrl {
    if (_isProduction) {
      return 'https://sipsara-speech-api.onrender.com';
    }
    // Local development URL for speech-monitoring-v1
    return 'http://10.0.2.2:8020';
  }
  
  TtsService._internal();

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    try {
      await stop();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/tts/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final filePath = data['file_path'];
        if (filePath != null) {
          final audioUrl = '$_baseUrl$filePath';
          await _audioPlayer.play(UrlSource(audioUrl));
        }
      } else {
        print('TTS Generation failed: ${response.body}');
      }
    } catch (e) {
      print('TTS Service Error: $e');
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }
}

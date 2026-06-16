import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'play_audio_stub.dart'
    if (dart.library.html) 'play_audio_web.dart'
    if (dart.library.io) 'play_audio_io.dart' as platform;

/// Plays Sinhala TTS via intervention-service backend (gTTS cache).
class PlayAudioService {
  PlayAudioService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  final String baseUrl;

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      final uri = Uri.parse('$baseUrl/api/v1/c4/tts').replace(
        queryParameters: {'text': trimmed, 'lang': 'si', 'kind': 'ui'},
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final path = data['url'] as String? ?? '';
      if (path.isEmpty) return;
      final audioUrl = path.startsWith('http') ? path : '$baseUrl$path';
      await platform.playAudioUrl(audioUrl);
    } catch (_) {
      // Backend offline — UI still works without sound.
    }
  }
}

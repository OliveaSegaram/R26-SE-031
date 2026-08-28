import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../config/api_config.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();

  String get _baseUrl {
    return ApiConfig.speechBaseUrl;
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
          // Fix for iOS AVPlayer: Download the audio to a temp file and play locally
          final audioRes = await http.get(Uri.parse(audioUrl));
          if (audioRes.statusCode == 200) {
            final dir = await getTemporaryDirectory();
            final file = File('${dir.path}/temp_tts.wav');
            await file.writeAsBytes(audioRes.bodyBytes);
            await _audioPlayer.play(DeviceFileSource(file.path));
          } else {
            print('TTS Audio download failed: ${audioRes.statusCode}');
          }
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

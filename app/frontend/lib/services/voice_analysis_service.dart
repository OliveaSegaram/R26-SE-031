import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceAnalysisService {
  static final VoiceAnalysisService _instance = VoiceAnalysisService._internal();
  factory VoiceAnalysisService() => _instance;
  VoiceAnalysisService._internal();

  final AudioRecorder _record = AudioRecorder();
  String? _currentRecordingPath;

  static String get _baseUrl {
    // return 'http://127.0.0.1:8015/api/v1/auth/stt';
    return 'https://adaptedmind-auth-api.onrender.com/api/v1/auth/stt';
  }

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Starts recording audio from the device microphone
  Future<void> startRecording() async {
    try {
      // Check and request permissions
      if (await _record.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _currentRecordingPath = '${dir.path}/reading_sample_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _record.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc, // Standard cross-platform format
            sampleRate: 16000,           // Whisper loves 16kHz
            numChannels: 1,              // Mono
          ), 
          path: _currentRecordingPath!
        );
        print('VoiceAnalysisService: Started recording to $_currentRecordingPath');
      }
    } catch (e) {
      print('VoiceAnalysisService Error: Failed to start recording - $e');
    }
  }

  /// Stops recording and returns the raw audio file
  Future<File?> stopRecording() async {
    try {
      final path = await _record.stop();
      if (path != null) {
        print('VoiceAnalysisService: Stopped recording. File saved at $path');
        return File(path);
      }
    } catch (e) {
      print('VoiceAnalysisService Error: Failed to stop recording - $e');
    }
    return null;
  }

  /// Analyzes the audio for pauses, hesitation, and Word Error Rate (WER)
  /// using the backend FastAPI STT service.
  Future<Map<String, dynamic>> analyzeAudio(File audioFile, String expectedText) async {
    print('VoiceAnalysisService: Sending audio to STT API for analysis...');
    
    try {
      final token = await _getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/analyze-reading'));
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['expected_text'] = expectedText;
      request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'transcription': data['transcription'],
          'word_error_rate': data['word_error_rate'],
          'hesitation_ms': 500, // Mock hesitation for now until silence detection is built
        };
      } else {
        print('VoiceAnalysisService API Error: ${response.body}');
        return {
          'transcription': '',
          'word_error_rate': 1.0,
          'hesitation_ms': 0,
        };
      }
    } catch (e) {
      print('VoiceAnalysisService Network Error: $e');
      return {
        'transcription': '',
        'word_error_rate': 1.0,
        'hesitation_ms': 0,
      };
    }
  }
}

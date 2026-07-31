import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../models/curriculum_models.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../services/tts_service.dart';
import 'dart:math';

class DemoSinhalaLetterBuilder extends StatefulWidget {
  final ActivityNode activityNode;

  const DemoSinhalaLetterBuilder({Key? key, required this.activityNode})
      : super(key: key);

  @override
  State<DemoSinhalaLetterBuilder> createState() =>
      _DemoSinhalaLetterBuilderState();
}

class _DemoSinhalaLetterBuilderState extends State<DemoSinhalaLetterBuilder> {
  int _currentRoundIndex = 0;
  String? _selectedAkura;
  String? _selectedPillam;

  List<String> _currentAkuras = [];
  List<String> _currentPillams = [];
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _setupRound();
    // Wait for the build to complete before speaking to prevent state issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakTarget();
    });
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupRound() {
    if (_currentRoundIndex >= widget.activityNode.rounds.length) return;

    final roundData = widget.activityNode.rounds[_currentRoundIndex];
    final correctAkura = roundData['correct_akura'] as String;
    final distractorAkuras = List<String>.from(roundData['distractor_akuras']);
    
    final correctPillam = roundData['correct_pillam'] as String;
    final distractorPillams = List<String>.from(roundData['distractor_pillams']);

    _currentAkuras = [correctAkura, ...distractorAkuras];
    _currentAkuras.shuffle(_random);

    _currentPillams = [correctPillam, ...distractorPillams];
    _currentPillams.shuffle(_random);

    _selectedAkura = null;
    _selectedPillam = null;
  }
  
  Future<void> _speakTarget() async {
    final roundData = widget.activityNode.rounds[_currentRoundIndex];
    final target = roundData['target'] as String;
    await TtsService().speak(target);
  }
  
  Future<void> _playChime(bool success) async {
    try {
      final assetPath = success
          ? 'assets/audio/correct_chime.mp3'
          : 'assets/audio/wrong_buzzer.mp3';
      await _audioPlayer.setAsset(assetPath);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  void _checkAnswer() async {
    if (_selectedAkura == null || _selectedPillam == null) return;

    final roundData = widget.activityNode.rounds[_currentRoundIndex];
    final correctAkura = roundData['correct_akura'] as String;
    final correctPillam = roundData['correct_pillam'] as String;

    final telemetry = TelemetryWrapper.of(context);
    
    if (_selectedAkura == correctAkura && _selectedPillam == correctPillam) {
      await _playChime(true);
      telemetry?.recordAttempt(true);
      
      setState(() {
        if (_currentRoundIndex < widget.activityNode.rounds.length - 1) {
          _currentRoundIndex++;
          _setupRound();
          _speakTarget();
        } else {
          telemetry?.completeActivity();
        }
      });
    } else {
      await _playChime(false);
      telemetry?.recordAttempt(false);
      
      setState(() {
        _selectedAkura = null;
        _selectedPillam = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRoundIndex >= widget.activityNode.rounds.length) {
      return const Center(child: Text('Activity Complete!'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(widget.activityNode.title),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Big Speaker Button
              Center(
                child: GestureDetector(
                  onTap: _speakTarget,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.volume_up,
                      size: 80,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Listen and build the letter!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
              
              // Akura Selection
              const Text(
                '1. Select Base Letter (Akura):',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _currentAkuras.map((akura) => _buildOptionButton(
                  text: akura,
                  isSelected: _selectedAkura == akura,
                  onTap: () {
                    setState(() {
                      _selectedAkura = akura;
                    });
                  },
                )).toList(),
              ),
              
              const SizedBox(height: 30),
              
              // Pillam Selection
              const Text(
                '2. Select Vowel Modifier (Pillam):',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _currentPillams.map((pillam) => _buildOptionButton(
                  text: pillam,
                  isSelected: _selectedPillam == pillam,
                  onTap: () {
                    setState(() {
                      _selectedPillam = pillam;
                    });
                  },
                )).toList(),
              ),
              
              const Spacer(),
              
              // Check Button
              ElevatedButton(
                onPressed: (_selectedAkura != null && _selectedPillam != null)
                    ? _checkAnswer
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Check Answer',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? Colors.orangeAccent : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
            width: 3,
          ),
          boxShadow: [
            if (!isSelected)
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

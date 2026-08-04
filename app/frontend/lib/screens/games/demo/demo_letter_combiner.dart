import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../models/curriculum_models.dart';
import '../../../../services/tts_service.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import 'dart:math';

class DemoLetterCombiner extends StatefulWidget {
  final ActivityNode activityNode;

  const DemoLetterCombiner({Key? key, required this.activityNode})
      : super(key: key);

  @override
  State<DemoLetterCombiner> createState() => _DemoLetterCombinerState();
}

class _DemoLetterCombinerState extends State<DemoLetterCombiner> {
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
  
  Future<void> _playPronunciation() async {
    // Currently uses TTS, but ready for recorded audio if needed
    final roundData = widget.activityNode.rounds[_currentRoundIndex];
    final target = roundData['target'] as String;
    await TtsService().speak(target);
  }
  
  Future<void> _playChime(bool success) async {
    try {
      final assetPath = success ? 'audio/correct.mp3' : 'audio/wrong.mp3';
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  void _checkAnswer() async {
    if (_selectedAkura == null || _selectedPillam == null) return;

    final roundData = widget.activityNode.rounds[_currentRoundIndex];
    final correctAkura = roundData['correct_akura'] as String;
    final correctPillam = roundData['correct_pillam'] as String;

    final telemetry = context.findAncestorStateOfType<TelemetryWrapperState>();
    
    if (_selectedAkura == correctAkura && _selectedPillam == correctPillam) {
      await _playChime(true);
      telemetry?.completeRound(100);
      
      setState(() {
        if (_currentRoundIndex < widget.activityNode.rounds.length - 1) {
          _currentRoundIndex++;
          _setupRound();
        } else {
          telemetry?.completeActivity(context);
        }
      });
    } else {
      await _playChime(false);
      telemetry?.recordMisclick();
      
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
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(widget.activityNode.title),
        backgroundColor: Colors.indigo,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // Big Speaker Button in the center
              Center(
                child: GestureDetector(
                  onTap: _playPronunciation,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      size: 90,
                      color: Colors.indigo,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Tap to hear the sound',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 30),
              
              // Akura Selection
              const Text(
                'Select Akura (Letter):',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
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
              
              const SizedBox(height: 25),
              
              // Pillam Selection
              const Text(
                'Select Pilla (Modifier):',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
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
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Check Match',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
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
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigoAccent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey.shade400,
            width: 3,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

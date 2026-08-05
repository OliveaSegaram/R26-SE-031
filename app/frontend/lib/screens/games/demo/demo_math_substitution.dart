import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';

class DemoMathSubstitution extends StatefulWidget {
  final ActivityNode activityNode;
  const DemoMathSubstitution({super.key, required this.activityNode});

  @override
  State<DemoMathSubstitution> createState() => _DemoMathSubstitutionState();
}

class _DemoMathSubstitutionState extends State<DemoMathSubstitution> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int _currentRoundIndex = 0;
  List<String> _sequence = [];
  Map<String, int> _values = {};
  
  List<int?> _answers = [];
  int? _selectedNumber;

  final Map<String, String> _itemToEmoji = {
    'sandwich': '🥪', 'emoji': '😝',
    'apple': '🍎', 'star': '⭐',
    'car': '🚗', 'bike': '🚲',
    'cat': '🐱', 'dog': '🐶',
    'sun': '☀️', 'moon': '🌙',
    'flower': '🌸', 'tree': '🌳'
  };

  @override
  void initState() {
    super.initState();
    _setupRound();
  }

  void _setupRound() {
    if (_currentRoundIndex < widget.activityNode.rounds.length) {
      final roundData = widget.activityNode.rounds[_currentRoundIndex];
      _sequence = List<String>.from(roundData['sequence'] ?? []);
      final rawValues = roundData['values'] as Map<String, dynamic>? ?? {};
      _values = rawValues.map((k, v) => MapEntry(k, v as int));
    }
    _answers = List.filled(_sequence.length, null);
    _selectedNumber = null;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onSlotTapped(int index) async {
    if (_selectedNumber == null) return;
    
    final expectedAnswer = _values[_sequence[index]];
    
    if (_selectedNumber == expectedAnswer) {
      setState(() {
        _answers[index] = _selectedNumber;
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      if (!_answers.contains(null)) {
        context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(100);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          if (_currentRoundIndex < widget.activityNode.rounds.length - 1) {
            setState(() {
              _currentRoundIndex++;
            });
            _setupRound();
          } else {
            context.findAncestorStateOfType<TelemetryWrapperState>()?.completeActivity(context);
          }
        });
      }
    } else {
      context.findAncestorStateOfType<TelemetryWrapperState>()?.recordMisclick();
      await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.redAccent, width: 4)),
            title: Text('Wrong Answer Think Again!', textAlign: TextAlign.center, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Try Again', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Unique options for the number selectors
    final uniqueValues = _values.values.toSet().toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFF1E4B5E),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F8A8B),
                  borderRadius: BorderRadius.only(topLeft: Radius.elliptical(200, 40), topRight: Radius.elliptical(200, 40)),
                ),
              ),
            ),
            
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.home, color: Colors.amber, size: 32),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: LinearProgressIndicator(
                            value: (_currentRoundIndex + 1) / widget.activityNode.rounds.length,
                            backgroundColor: Colors.white,
                            color: Colors.amber,
                            minHeight: 16,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4F8),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 8)],
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 24,
                            runSpacing: 16,
                            children: _values.entries.map((e) {
                              final emojiStr = _itemToEmoji[e.key] ?? '❓';
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(emojiStr, style: const TextStyle(fontSize: 40)),
                                  Text(' = ${e.value}', style: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.bold)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF5E6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: _sequence.map((item) {
                                  final emojiStr = _itemToEmoji[item] ?? '❓';
                                  return Container(
                                    width: 70, height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300, width: 2),
                                    ),
                                    child: Center(child: Text(emojiStr, style: const TextStyle(fontSize: 40))),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(_sequence.length, (index) {
                                  return GestureDetector(
                                    onTap: () => _onSlotTapped(index),
                                    child: Container(
                                      width: 70, height: 70,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade400, width: 2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _answers[index]?.toString() ?? '', 
                                          style: GoogleFonts.nunito(fontSize: 36, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: uniqueValues.map((num) {
                      bool isSelected = _selectedNumber == num;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedNumber = num;
                          });
                        },
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? Colors.amber : Colors.amber.shade200, width: isSelected ? 6 : 4),
                          ),
                          child: Center(
                            child: Text(num.toString(), style: GoogleFonts.nunito(fontSize: 36, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 100), // Astronaut space
              ],
            ),
            
            Positioned(
              bottom: 10, right: 10,
              child: const Icon(Icons.rocket_launch, color: Colors.white, size: 80),
            ),
          ],
        ),
      ),
    );
  }
}

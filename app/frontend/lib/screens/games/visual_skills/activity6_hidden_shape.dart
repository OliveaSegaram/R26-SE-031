import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/telemetry_wrapper.dart';
import '../../../models/curriculum_models.dart';
import 'dart:math';

class Activity6HiddenShape extends StatefulWidget {
  final ActivityNode activityNode;
  const Activity6HiddenShape({super.key, required this.activityNode});

  @override
  State<Activity6HiddenShape> createState() => _Activity6HiddenShapeState();
}

class HiddenShapeRound {
  final String instruction;
  final List<String> shapes;
  final List<int> targetIndices;
  HiddenShapeRound({required this.instruction, required this.shapes, required this.targetIndices});
}

class _Activity6HiddenShapeState extends State<Activity6HiddenShape> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int _currentRoundIndex = 0;
  late List<HiddenShapeRound> _rounds;

  Set<int> _foundShapes = {};
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
  }

  void _initRounds() {
    final random = Random();
    
    _rounds = widget.activityNode.rounds.map((roundData) {
      String instruction = roundData['raw_text'] ?? 'හැඩය සොයන්න';
      String target = roundData['target'] ?? roundData['correctOption'] ?? '⭐';
      int targetCount = roundData['target_count'] ?? (roundData.containsKey('correctOption') ? 1 : 3);
      List<String> distractors = roundData.containsKey('distractors')
          ? List<String>.from(roundData['distractors'])
          : List<String>.from(roundData['options'] ?? ['○', '□']);
      
      List<String> shapes = [];
      for (int i = 0; i < targetCount; i++) shapes.add(target);
      
      int totalShapes = 12;
      for (int i = shapes.length; i < totalShapes; i++) {
        shapes.add(distractors[random.nextInt(distractors.length)]);
      }
      
      shapes.shuffle();
      
      List<int> targetIndices = [];
      for (int i = 0; i < shapes.length; i++) {
        if (shapes[i] == target) targetIndices.add(i);
      }
      
      return HiddenShapeRound(
        instruction: instruction, 
        shapes: shapes, 
        targetIndices: targetIndices
      );
    }).toList();
  }

  void _checkShape(int index) async {
    if (_isComplete || _foundShapes.contains(index)) return;

    final currentRound = _rounds[_currentRoundIndex];
    bool isCorrect = currentRound.targetIndices.contains(index);

    // Telemetry logged upon completion of the round
    // We only send telemetry when all items are found


    if (isCorrect) {
      setState(() {
        _foundShapes.add(index);
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      if (_foundShapes.length == currentRound.targetIndices.length) {
        setState(() {
          _isComplete = true;
        });
        
        context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(100);

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          if (_currentRoundIndex < _rounds.length - 1) {
            setState(() {
              _currentRoundIndex++;
              _foundShapes.clear();
              _isComplete = false;
            });
          } else {
            if (context.findAncestorStateOfType<TelemetryWrapperState>() != null) { context.findAncestorStateOfType<TelemetryWrapperState>()!.completeActivity(context); } else { Navigator.pop(context, 0); }
          }
        });
      }
    } else {
      await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRound = _rounds[_currentRoundIndex];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          'සැඟවුණු හැඩය සොයන්න',
          style: AppTypography.sinhala(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Progression Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'වටය ${_currentRoundIndex + 1} / ${_rounds.length}',
                    style: AppTypography.sinhala(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentRoundIndex + 1) / _rounds.length,
                backgroundColor: AppColors.borderLight,
                color: AppColors.gentleGreen,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),

              Text(
                currentRound.instruction,
                style: AppTypography.sinhala(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'හමුවූ ගණන: ${_foundShapes.length} / ${currentRound.targetIndices.length}',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: currentRound.shapes.length,
                  itemBuilder: (context, index) {
                    final isFound = _foundShapes.contains(index);
                    
                    return GestureDetector(
                      onTap: () => _checkShape(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isFound ? AppColors.gentleGreen.withValues(alpha: 0.3) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFound ? AppColors.gentleGreen : AppColors.borderLight.withValues(alpha: 0.5),
                            width: isFound ? 4 : 2,
                          ),
                          boxShadow: [
                            if (!isFound)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            currentRound.shapes[index],
                            style: TextStyle(
                              fontSize: 50,
                              color: isFound ? AppColors.gentleGreen : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isComplete)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gentleGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        'විශිෂ්ටයි!',
                        style: AppTypography.sinhala(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

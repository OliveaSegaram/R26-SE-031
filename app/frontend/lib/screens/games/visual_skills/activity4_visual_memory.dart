import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/telemetry_wrapper.dart';
import '../../../models/curriculum_models.dart';
import 'dart:math';

class Activity4VisualMemory extends StatefulWidget {
  final ActivityNode activityNode;
  const Activity4VisualMemory({super.key, required this.activityNode});

  @override
  State<Activity4VisualMemory> createState() => _Activity4VisualMemoryState();
}

class MemoryRound {
  final List<String> targetItems;
  final List<String> allOptions;
  MemoryRound({required this.targetItems, required this.allOptions});
}

class _Activity4VisualMemoryState extends State<Activity4VisualMemory> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _showingMemoryGrid = true;
  int _timeLeft = 10;
  Timer? _timer;

  int _currentRoundIndex = 0;
  late List<MemoryRound> _rounds;

  Set<String> _selectedItems = {};
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
    _startTimer();
  }

  void _initRounds() {
    final random = Random();
    const defaultEmojis = ['🌸', '🚗', '🐟', '🏫', '🍎', '🌳', '🚌', '🐦', '🐕', '🏠', '🦆', '🌲', '⚽', '🏀', '🍎', '🍌'];
    
    _rounds = widget.activityNode.rounds.map((roundData) {
      List<String> targetItems = List<String>.from(roundData['targetItems'] ?? []);
      List<String> allOptions = List<String>.from(roundData['allOptions'] ?? []);
      
      // Fallback if not provided in JSON
      if (targetItems.isEmpty) {
        final shuffled = List<String>.from(defaultEmojis)..shuffle();
        targetItems = shuffled.take(3 + random.nextInt(3)).toList(); // 3 to 5 items
        allOptions = List<String>.from(targetItems);
        allOptions.addAll(shuffled.skip(targetItems.length).take(5)); // add distractors
      }
      
      allOptions.shuffle();
      return MemoryRound(targetItems: targetItems, allOptions: allOptions);
    }).toList();
  }

  void _startTimer() {
    setState(() {
      _showingMemoryGrid = true;
      _timeLeft = 8; // Reset timer for each round
      _selectedItems.clear();
      _isComplete = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 1) {
          _timeLeft--;
        } else {
          _showingMemoryGrid = false;
          _timer?.cancel();
        }
      });
    });
  }

  void _toggleSelection(String item) async {
    if (_isComplete) return;

    final currentRound = _rounds[_currentRoundIndex];
    bool reachedLimit = false;

    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        if (_selectedItems.length < currentRound.targetItems.length) {
          _selectedItems.add(item);
        } else {
          reachedLimit = true;
        }
      }
    });

    if (reachedLimit) {
      await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
    } else {
      _checkCompletion();
    }
  }
  
  void _checkCompletion() async {
    final currentRound = _rounds[_currentRoundIndex];

    if (_selectedItems.length == currentRound.targetItems.length) {
      bool allCorrect = _selectedItems.every((item) => currentRound.targetItems.contains(item));
      
      int score = allCorrect ? 100 : 0;
      context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(score);

      if (allCorrect) {
        setState(() {
          _isComplete = true;
        });
        await _audioPlayer.play(AssetSource('audio/correct.mp3'));
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          if (_currentRoundIndex < _rounds.length - 1) {
            setState(() {
              _currentRoundIndex++;
            });
            _startTimer();
          } else {
            Navigator.pop(context, true);
          }
        });
      } else {
        await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
        
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _selectedItems.removeWhere((item) => !currentRound.targetItems.contains(item));
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
          'මතක තබාගන්න',
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

              if (_showingMemoryGrid) ...[
                Text(
                  'මෙම රූප හොඳින් මතක තබාගන්න',
                  style: AppTypography.sinhala(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_timeLeft',
                    style: GoogleFonts.fredoka(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Center(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: currentRound.targetItems.map((item) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(item, style: const TextStyle(fontSize: 50)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'ඔබට මතක රූප තෝරන්න\n(${_selectedItems.length} / ${currentRound.targetItems.length})',
                  style: AppTypography.sinhala(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: currentRound.allOptions.length,
                    itemBuilder: (context, index) {
                      final item = currentRound.allOptions[index];
                      final isSelected = _selectedItems.contains(item);
                      
                      return GestureDetector(
                        onTap: () => _toggleSelection(item),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.gentleGreen.withValues(alpha: 0.3) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.gentleGreen : AppColors.borderLight,
                              width: isSelected ? 4 : 2,
                            ),
                          ),
                          child: Center(
                            child: Text(item, style: const TextStyle(fontSize: 45)),
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
            ],
          ),
        ),
      ),
    );
  }
}

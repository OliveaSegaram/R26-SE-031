import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/telemetry_wrapper.dart';
import '../../../models/curriculum_models.dart';
import 'dart:math';

class Activity7SizeOrdering extends StatefulWidget {
  final ActivityNode activityNode;
  const Activity7SizeOrdering({super.key, required this.activityNode});

  @override
  State<Activity7SizeOrdering> createState() => _Activity7SizeOrderingState();
}

class SizeRound {
  final List<String> items;
  final List<double> sizes;
  final List<String> targetOrder;
  SizeRound({required this.items, required this.sizes, required this.targetOrder});
}

class _Activity7SizeOrderingState extends State<Activity7SizeOrdering> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int _currentRoundIndex = 0;
  late List<SizeRound> _rounds;

  List<String> _currentOrder = [];
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
  }

  void _initRounds() {
    final random = Random();
    
    _rounds = widget.activityNode.rounds.map((roundData) {
      List<String> items = List<String>.from(roundData['items'] ?? []);
      List<double> sizes = [];
      if (roundData['sizes'] != null) {
        sizes = (roundData['sizes'] as List).map((e) => (e as num).toDouble()).toList();
      }
      List<String> targetOrder = List<String>.from(roundData['targetOrder'] ?? []);
      
      if (items.isEmpty) {
        // Fallback
        items = ['🐘', '🐁', '🐈'];
        sizes = [100.0, 40.0, 70.0];
        targetOrder = ['🐁', '🐈', '🐘'];
      }
      
      return SizeRound(items: items, sizes: sizes, targetOrder: targetOrder);
    }).toList();
  }

  void _onItemTap(String item) async {
    if (_isComplete || _currentOrder.contains(item)) return;

    final currentRound = _rounds[_currentRoundIndex];
    final expectedItem = currentRound.targetOrder[_currentOrder.length];
    
    bool isCorrect = item == expectedItem;
    // telemetry handled when fully complete


    if (isCorrect) {
      setState(() {
        _currentOrder.add(item);
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      if (_currentOrder.length == currentRound.targetOrder.length) {
        setState(() {
          _isComplete = true;
        });
        
        context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(100);

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          if (_currentRoundIndex < _rounds.length - 1) {
            setState(() {
              _currentRoundIndex++;
              _currentOrder.clear();
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
          'ප්‍රමාණය අනුව සකසන්න',
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
                'කුඩාම එකේ සිට විශාලම එක දක්වා පිලිවෙලට තෝරන්න',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Target slots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(currentRound.items.length, (index) {
                  final hasItem = index < _currentOrder.length;
                  
                  // find the size of the item in the currentOrder
                  double itemSize = 40;
                  if (hasItem) {
                    int originalIndex = currentRound.items.indexOf(_currentOrder[index]);
                    itemSize = originalIndex != -1 ? currentRound.sizes[originalIndex] : 40;
                    // scale down size for slots
                    itemSize = itemSize * 0.7; 
                  }
                  
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 2, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: hasItem 
                        ? Text(
                            _currentOrder[index], 
                            style: TextStyle(fontSize: itemSize)
                          )
                        : Text(
                            '${index + 1}',
                            style: GoogleFonts.fredoka(fontSize: 30, color: Colors.grey.shade400),
                          ),
                    ),
                  );
                }),
              ),
              
              const Spacer(),
              
              // Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(currentRound.items.length, (index) {
                  final item = currentRound.items[index];
                  final size = currentRound.sizes[index];
                  final isSelected = _currentOrder.contains(item);
                  
                  return GestureDetector(
                    onTap: () => _onItemTap(item),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isSelected ? 0.0 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(item, style: TextStyle(fontSize: size)),
                      ),
                    ),
                  );
                }),
              ),
              
              const Spacer(),
              
              if (_isComplete)
                Container(
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

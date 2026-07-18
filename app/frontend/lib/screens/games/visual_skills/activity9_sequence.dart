import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';

class Activity9Sequence extends StatefulWidget {
  const Activity9Sequence({super.key});

  @override
  State<Activity9Sequence> createState() => _Activity9SequenceState();
}

class _Activity9SequenceState extends State<Activity9Sequence> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isComplete = false;
  int? _selectedIndex;
  
  final List<String?> _sequence = ['🥚', '🐣', '🐥', null];
  final List<String> _options = ['🍎', '🐔', '🐟'];
  final int _correctOptionIndex = 1; // 🐔

  void _checkAnswer(int index) async {
    if (_isComplete) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == _correctOptionIndex) {
      setState(() {
        _isComplete = true;
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context, true);
      });
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'රටාව සම්පූර්ණ කරන්න',
          style: GoogleFonts.notoSansSinhala(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'මීළඟට එන්නේ කුමක්ද?',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              
              // Sequence
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _sequence.map((item) {
                  if (item == null) {
                    return Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 2, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: _isComplete 
                          ? Text(_options[_correctOptionIndex], style: const TextStyle(fontSize: 50)) 
                          : Text('?', style: GoogleFonts.fredoka(fontSize: 40, color: Colors.grey)),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(item, style: const TextStyle(fontSize: 60)),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 80),
              
              // Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_options.length, (index) {
                  final isSelected = _selectedIndex == index;
                  final isCorrectSelection = isSelected && index == _correctOptionIndex;
                  final isWrongSelection = isSelected && index != _correctOptionIndex;

                  return GestureDetector(
                    onTap: () => _checkAnswer(index),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isCorrectSelection
                            ? AppColors.mint.withValues(alpha: 0.3)
                            : isWrongSelection
                                ? Colors.red.withValues(alpha: 0.3)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCorrectSelection
                              ? AppColors.mint
                              : isWrongSelection
                                  ? Colors.red
                                  : AppColors.primaryLight,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        _options[index],
                        style: const TextStyle(fontSize: 50),
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
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        'විශිෂ්ටයි!',
                        style: GoogleFonts.notoSansSinhala(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/gradient_button.dart';

class Activity1SpotDifference extends StatefulWidget {
  const Activity1SpotDifference({super.key});

  @override
  State<Activity1SpotDifference> createState() => _Activity1SpotDifferenceState();
}

class _Activity1SpotDifferenceState extends State<Activity1SpotDifference> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedIndex;
  bool _isCorrect = false;

  final List<String> _items = ['🐟', '🐟', '🐟', '🦆', '🐟'];
  final int _correctIndex = 3;

  void _checkAnswer(int index) async {
    if (_isCorrect) return; // Prevent multiple clicks after success

    setState(() {
      _selectedIndex = index;
    });

    if (index == _correctIndex) {
      setState(() {
        _isCorrect = true;
      });
      // Play success sound if needed
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
          'වෙනස් රූපය සොයන්න',
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
                'වෙනස් රූපය තෝරන්න',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: List.generate(_items.length, (index) {
                  final isSelected = _selectedIndex == index;
                  final isCorrectSelection = isSelected && index == _correctIndex;
                  final isWrongSelection = isSelected && index != _correctIndex;

                  return GestureDetector(
                    onTap: () => _checkAnswer(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
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
                        _items[index],
                        style: const TextStyle(fontSize: 60),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 48),
              if (_isCorrect)
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

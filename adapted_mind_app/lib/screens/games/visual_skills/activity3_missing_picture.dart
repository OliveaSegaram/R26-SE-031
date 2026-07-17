import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';

class Activity3MissingPicture extends StatefulWidget {
  const Activity3MissingPicture({super.key});

  @override
  State<Activity3MissingPicture> createState() => _Activity3MissingPictureState();
}

class _Activity3MissingPictureState extends State<Activity3MissingPicture> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedIndex;
  bool _isCorrect = false;

  // 🌸 🌳 🐟 ____ 🚌
  final List<String?> _sequence = ['🌸', '🌳', '🐟', null, '🚌'];
  final List<String> _options = ['🏫', '🍎', '🐦']; // '🐦' is just a wrong option
  final int _correctOptionIndex = 1; // Let's say '🍎' is the intended answer for the gap in the prompt

  void _checkAnswer(int index) async {
    if (_isCorrect) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == _correctOptionIndex) {
      setState(() {
        _isCorrect = true;
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
          'අඩු රූපය සොයන්න',
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
                'හිස්තැනට සුදුසු රූපය තෝරන්න',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Sequence
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _sequence.map((item) {
                  if (item == null) {
                    return Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 2, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: _isCorrect 
                          ? Text(_options[_correctOptionIndex], style: const TextStyle(fontSize: 40)) 
                          : Text('?', style: GoogleFonts.fredoka(fontSize: 30, color: Colors.grey)),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(item, style: const TextStyle(fontSize: 45)),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 64),
              
              // Options
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_options.length, (index) {
                  final isSelected = _selectedIndex == index;
                  final isCorrectSelection = isSelected && index == _correctOptionIndex;
                  final isWrongSelection = isSelected && index != _correctOptionIndex;

                  return GestureDetector(
                    onTap: () => _checkAnswer(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
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
                        _options[index],
                        style: const TextStyle(fontSize: 50),
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

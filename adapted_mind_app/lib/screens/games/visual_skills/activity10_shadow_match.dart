import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';

class Activity10ShadowMatch extends StatefulWidget {
  const Activity10ShadowMatch({super.key});

  @override
  State<Activity10ShadowMatch> createState() => _Activity10ShadowMatchState();
}

class _Activity10ShadowMatchState extends State<Activity10ShadowMatch> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  final List<String> _items = ['🌳', '🐟', '🚌', '🏫'];
  // We will shuffle the shadows
  final List<String> _shadows = ['🏫', '🌳', '🐟', '🚌']; 
  
  final Map<String, bool> _matched = {
    '🌳': false,
    '🐟': false,
    '🚌': false,
    '🏫': false,
  };

  bool _isComplete = false;

  void _onAccept(String shadow, String draggedItem) async {
    if (shadow == draggedItem) {
      setState(() {
        _matched[draggedItem] = true;
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      if (_matched.values.every((isMatched) => isMatched)) {
        setState(() {
          _isComplete = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true);
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'සෙවනැල්ල ගලපන්න',
          style: GoogleFonts.notoSansSinhala(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                'නිවැරදි සෙවනැල්ලට ගෙන යන්න',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Draggable Items Column
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _items.map((item) {
                        final isMatched = _matched[item]!;
                        return isMatched
                            ? const SizedBox(width: 80, height: 80)
                            : Draggable<String>(
                                data: item,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Text(item, style: const TextStyle(fontSize: 80)),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: Text(item, style: const TextStyle(fontSize: 70)),
                                ),
                                child: Text(item, style: const TextStyle(fontSize: 70)),
                              );
                      }).toList(),
                    ),
                    
                    // Shadows Column (Targets)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _shadows.map((shadow) {
                        final isMatched = _matched[shadow]!;
                        return DragTarget<String>(
                          onWillAcceptWithDetails: (details) => !isMatched,
                          onAcceptWithDetails: (details) => _onAccept(shadow, details.data),
                          builder: (context, candidateData, rejectedData) {
                            return isMatched
                                ? Text(shadow, style: const TextStyle(fontSize: 70))
                                : ColorFiltered(
                                    colorFilter: const ColorFilter.matrix(<double>[
                                      0, 0, 0, 0, 0,
                                      0, 0, 0, 0, 0,
                                      0, 0, 0, 0, 0,
                                      0, 0, 0, 1, 0,
                                    ]),
                                    child: Opacity(
                                      opacity: 0.3,
                                      child: Text(shadow, style: const TextStyle(fontSize: 70)),
                                    ),
                                  );
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              if (_isComplete)
                Container(
                  margin: const EdgeInsets.only(top: 16),
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

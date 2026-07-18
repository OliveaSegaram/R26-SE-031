import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';

class Activity7SizeOrdering extends StatefulWidget {
  const Activity7SizeOrdering({super.key});

  @override
  State<Activity7SizeOrdering> createState() => _Activity7SizeOrderingState();
}

class _Activity7SizeOrderingState extends State<Activity7SizeOrdering> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  final List<String> _items = ['🐘', '🐁', '🐈'];
  final List<double> _sizes = [100.0, 40.0, 70.0];
  
  // The correct order is smallest to largest: 🐁, 🐈, 🐘
  final List<String> _targetOrder = ['🐁', '🐈', '🐘'];
  final List<String> _currentOrder = [];
  
  bool _isComplete = false;

  void _onItemTap(String item) async {
    if (_isComplete || _currentOrder.contains(item)) return;

    final expectedItem = _targetOrder[_currentOrder.length];
    
    if (item == expectedItem) {
      setState(() {
        _currentOrder.add(item);
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      if (_currentOrder.length == _targetOrder.length) {
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
          'ප්‍රමාණය අනුව සකසන්න',
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
                children: List.generate(3, (index) {
                  final hasItem = index < _currentOrder.length;
                  
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
                            style: TextStyle(
                              fontSize: _currentOrder[index] == '🐁' ? 40 : _currentOrder[index] == '🐈' ? 60 : 70
                            )
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
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final size = _sizes[index];
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

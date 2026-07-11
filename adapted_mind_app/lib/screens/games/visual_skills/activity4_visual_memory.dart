import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';

class Activity4VisualMemory extends StatefulWidget {
  const Activity4VisualMemory({super.key});

  @override
  State<Activity4VisualMemory> createState() => _Activity4VisualMemoryState();
}

class _Activity4VisualMemoryState extends State<Activity4VisualMemory> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _showingMemoryGrid = true;
  int _timeLeft = 10;
  Timer? _timer;

  final List<String> _targetItems = ['🌸', '🐟', '🏫', '🍎', '🌳', '🚌', '🐦'];
  
  // Mix target items with some distractors
  final List<String> _allOptions = ['🌸', '🚗', '🐟', '🏫', '🍎', '🌳', '🚌', '🐦', '🐕', '🏠', '🦆', '🌲'];
  
  Set<String> _selectedItems = {};
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _allOptions.shuffle(); // Randomize positions
    _startTimer();
  }

  void _startTimer() {
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

    bool reachedLimit = false;

    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        if (_selectedItems.length < _targetItems.length) {
          _selectedItems.add(item);
        } else {
          reachedLimit = true;
        }
      }
    });

    if (reachedLimit) {
      // User tried to select an 8th item, play error
      await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
    } else {
      _checkCompletion();
    }
  }
  
  void _checkCompletion() async {
    // Check if selected items exactly match target items
    if (_selectedItems.length == _targetItems.length) {
      bool allCorrect = _selectedItems.every((item) => _targetItems.contains(item));
      if (allCorrect) {
        setState(() {
          _isComplete = true;
        });
        await _audioPlayer.play(AssetSource('audio/correct.mp3'));
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        // Reached 7 items but they are not all correct
        await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
        
        // Auto-deselect incorrect items after a short delay for visual feedback
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _selectedItems.removeWhere((item) => !_targetItems.contains(item));
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'මතක තබාගන්න',
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
              if (_showingMemoryGrid) ...[
                Text(
                  'මෙම රූප හොඳින් මතක තබාගන්න',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
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
                      children: _targetItems.map((item) {
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
                  'ඔබට මතක රූප තෝරන්න\n(${_selectedItems.length} / ${_targetItems.length})',
                  style: GoogleFonts.notoSansSinhala(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
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
                    itemCount: _allOptions.length,
                    itemBuilder: (context, index) {
                      final item = _allOptions[index];
                      final isSelected = _selectedItems.contains(item);
                      
                      return GestureDetector(
                        onTap: () => _toggleSelection(item),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.mint.withValues(alpha: 0.3) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.mint : AppColors.primaryLight,
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
            ],
          ),
        ),
      ),
    );
  }
}

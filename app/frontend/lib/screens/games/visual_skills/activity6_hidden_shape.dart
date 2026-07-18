import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';

class Activity6HiddenShape extends StatefulWidget {
  const Activity6HiddenShape({super.key});

  @override
  State<Activity6HiddenShape> createState() => _Activity6HiddenShapeState();
}

class _Activity6HiddenShapeState extends State<Activity6HiddenShape> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // △ □ ○ ☆
  final List<String> _shapes = ['△', '□', '○', '☆', '△', '□', '○', '△', '☆', '△', '□', '○'];
  final Set<int> _foundTriangles = {};
  
  // Indices of triangles in the list
  final List<int> _targetIndices = [0, 4, 7, 9];
  bool _isComplete = false;

  void _checkShape(int index) async {
    if (_isComplete || _foundTriangles.contains(index)) return;

    if (_targetIndices.contains(index)) {
      setState(() {
        _foundTriangles.add(index);
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      if (_foundTriangles.length == _targetIndices.length) {
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
          'සැඟවුණු හැඩය සොයන්න',
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
                'සියලුම ත්‍රිකෝණ (△) සොයන්න',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'හමුවූ ත්‍රිකෝණ: ${_foundTriangles.length} / ${_targetIndices.length}',
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
                  itemCount: _shapes.length,
                  itemBuilder: (context, index) {
                    final isFound = _foundTriangles.contains(index);
                    
                    return GestureDetector(
                      onTap: () => _checkShape(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isFound ? AppColors.mint.withValues(alpha: 0.3) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFound ? AppColors.mint : AppColors.primaryLight.withValues(alpha: 0.5),
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
                            _shapes[index],
                            style: TextStyle(
                              fontSize: 50,
                              color: isFound ? AppColors.mint : Colors.black87,
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

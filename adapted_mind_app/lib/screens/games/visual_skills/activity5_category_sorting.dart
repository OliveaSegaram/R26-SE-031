import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';

class Activity5CategorySorting extends StatefulWidget {
  const Activity5CategorySorting({super.key});

  @override
  State<Activity5CategorySorting> createState() => _Activity5CategorySortingState();
}

class _Activity5CategorySortingState extends State<Activity5CategorySorting> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Initial items
  final List<String> _draggableItems = ['🐟', '🌸', '🏫', '🍎', '🚌', '🐦'];
  
  final Map<String, List<String>> _categories = {
    'සතුන්\n(Animals)': [],
    'ශාක\n(Plants)': [],
    'ස්ථාන\n(Places)': [],
    'වාහන\n(Vehicles)': [],
  };

  final Map<String, String> _correctMapping = {
    '🐟': 'සතුන්\n(Animals)',
    '🐦': 'සතුන්\n(Animals)',
    '🌸': 'ශාක\n(Plants)',
    '🍎': 'ශාක\n(Plants)',
    '🏫': 'ස්ථාන\n(Places)',
    '🚌': 'වාහන\n(Vehicles)',
  };

  bool _isComplete = false;

  void _onAccept(String category, String item) async {
    if (_correctMapping[item] == category) {
      setState(() {
        _draggableItems.remove(item);
        _categories[category]!.add(item);
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      if (_draggableItems.isEmpty) {
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
          'වර්ග කිරීම',
          style: GoogleFonts.notoSansSinhala(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'රූප අදාල කොටුවට දමන්න',
                style: GoogleFonts.notoSansSinhala(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Draggable Items
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _draggableItems.map((item) {
                      return Draggable<String>(
                        data: item,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Text(item, style: const TextStyle(fontSize: 60)),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: Text(item, style: const TextStyle(fontSize: 50)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(item, style: const TextStyle(fontSize: 50)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Categories Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: _categories.keys.map((category) {
                    return DragTarget<String>(
                      onWillAcceptWithDetails: (details) => true,
                      onAcceptWithDetails: (details) => _onAccept(category, details.data),
                      builder: (context, candidateData, rejectedData) {
                        final isHovered = candidateData.isNotEmpty;
                        return Container(
                          decoration: BoxDecoration(
                            color: isHovered ? AppColors.mint.withValues(alpha: 0.2) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isHovered ? AppColors.mint : AppColors.primaryLight,
                              width: 3,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                ),
                                child: Text(
                                  category,
                                  style: GoogleFonts.notoSansSinhala(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _categories[category]!
                                        .map((item) => Text(item, style: const TextStyle(fontSize: 35)))
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
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

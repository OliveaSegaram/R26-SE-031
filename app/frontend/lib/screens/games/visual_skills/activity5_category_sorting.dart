import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/telemetry_wrapper.dart';
import '../../../models/curriculum_models.dart';

class Activity5CategorySorting extends StatefulWidget {
  final ActivityNode activityNode;
  const Activity5CategorySorting({super.key, required this.activityNode});

  @override
  State<Activity5CategorySorting> createState() => _Activity5CategorySortingState();
}

class CategoryRound {
  final List<String> initialItems;
  final List<String> categoryNames;
  final Map<String, String> correctMapping;
  CategoryRound({required this.initialItems, required this.categoryNames, required this.correctMapping});
}

class _Activity5CategorySortingState extends State<Activity5CategorySorting> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int _currentRoundIndex = 0;
  late List<CategoryRound> _rounds;

  List<String> _draggableItems = [];
  Map<String, List<String>> _categories = {};
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
    _setupCurrentRound();
  }

  void _initRounds() {
    _rounds = widget.activityNode.rounds.map((roundData) {
      List<String> initialItems = List<String>.from(roundData['initialItems'] ?? []);
      List<String> categoryNames = List<String>.from(roundData['categoryNames'] ?? []);
      Map<String, String> correctMapping = {};
      
      if (roundData['correctMapping'] != null) {
        correctMapping = Map<String, String>.from(roundData['correctMapping']);
      }

      // Fallback
      if (initialItems.isEmpty || categoryNames.isEmpty) {
        initialItems = ['🐟', '🌸', '🏫', '🍎', '🚌', '🐦'];
        categoryNames = ['සතුන්\n(Animals)', 'ශාක\n(Plants)', 'ස්ථාන\n(Places)', 'වාහන\n(Vehicles)'];
        correctMapping = {'🐟': 'සතුන්\n(Animals)', '🐦': 'සතුන්\n(Animals)', '🌸': 'ශාක\n(Plants)', '🍎': 'ශාක\n(Plants)', '🏫': 'ස්ථාන\n(Places)', '🚌': 'වාහන\n(Vehicles)'};
      }
      
      return CategoryRound(initialItems: initialItems, categoryNames: categoryNames, correctMapping: correctMapping);
    }).toList();
  }

  void _setupCurrentRound() {
    final currentRound = _rounds[_currentRoundIndex];
    _draggableItems = List.from(currentRound.initialItems);
    _draggableItems.shuffle();
    
    _categories = {};
    for (var name in currentRound.categoryNames) {
      _categories[name] = [];
    }
    _isComplete = false;
  }

  void _onAccept(String category, String item) async {
    final currentRound = _rounds[_currentRoundIndex];
    
    // Telemetry wrapper will handle correct/incorrect reporting at the end of the round.
    // For sorting, the user must get everything right to proceed, so we report when the grid is empty.
    bool isCorrectPlacement = currentRound.correctMapping[item] == category;
    
    if (isCorrectPlacement) {
      setState(() {
        _draggableItems.remove(item);
        _categories[category]!.add(item);
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      if (_draggableItems.isEmpty) {
        setState(() {
          _isComplete = true;
        });
        
        context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(100);

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          if (_currentRoundIndex < _rounds.length - 1) {
            setState(() {
              _currentRoundIndex++;
            });
            _setupCurrentRound();
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
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          'වර්ග කිරීම',
          style: AppTypography.sinhala(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              const SizedBox(height: 16),

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
                            color: isHovered ? AppColors.gentleGreen.withValues(alpha: 0.2) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isHovered ? AppColors.gentleGreen : AppColors.borderLight,
                              width: 3,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.borderLight.withValues(alpha: 0.3),
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

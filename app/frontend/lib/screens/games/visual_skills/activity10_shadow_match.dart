import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/telemetry_wrapper.dart';
import '../../../models/curriculum_models.dart';

class Activity10ShadowMatch extends StatefulWidget {
  final ActivityNode activityNode;
  const Activity10ShadowMatch({super.key, required this.activityNode});

  @override
  State<Activity10ShadowMatch> createState() => _Activity10ShadowMatchState();
}

class ShadowRound {
  final List<String> items;
  final List<String> shadows;
  ShadowRound({required this.items, required this.shadows});
}

class _Activity10ShadowMatchState extends State<Activity10ShadowMatch> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int _currentRoundIndex = 0;
  late List<ShadowRound> _rounds;

  Map<String, bool> _matched = {};
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
    _setupRound();
  }

  void _initRounds() {
    _rounds = widget.activityNode.rounds.map((roundData) {
      List<String> items = List<String>.from(roundData['items'] ?? []);
      List<String> shadows = List<String>.from(roundData['shadows'] ?? []);
      
      if (items.isEmpty) {
        items = ['🌳', '🐟', '🚌', '🏫'];
        shadows = ['🏫', '🌳', '🐟', '🚌'];
      }
      
      return ShadowRound(items: items, shadows: shadows);
    }).toList();
  }

  void _setupRound() {
    final currentRound = _rounds[_currentRoundIndex];
    _matched = { for (var item in currentRound.items) item: false };
    _isComplete = false;
  }

  void _onAccept(String shadow, String draggedItem) async {
    final currentRound = _rounds[_currentRoundIndex];
    bool isCorrect = shadow == draggedItem;
    // Telemetry happens at completion

    if (isCorrect) {
      setState(() {
        _matched[draggedItem] = true;
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      if (_matched.values.every((isMatched) => isMatched)) {
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
            _setupRound();
          } else {
            Navigator.pop(context, true);
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
          'සෙවනැල්ල ගලපන්න',
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
                      children: currentRound.items.map((item) {
                        final isMatched = _matched[item] ?? false;
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
                      children: currentRound.shadows.map((shadow) {
                        final isMatched = _matched[shadow] ?? false;
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

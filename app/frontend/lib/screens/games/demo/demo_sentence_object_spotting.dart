import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../models/curriculum_models.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import 'dart:math';

class DemoSentenceObjectSpotting extends StatefulWidget {
  final ActivityNode activityNode;

  const DemoSentenceObjectSpotting({Key? key, required this.activityNode})
      : super(key: key);

  @override
  State<DemoSentenceObjectSpotting> createState() => _DemoSentenceObjectSpottingState();
}

class IconItem {
  final String iconData;
  final bool isTarget;
  double top;
  double left;
  double size;

  IconItem({
    required this.iconData,
    required this.isTarget,
    this.top = 0,
    this.left = 0,
    this.size = 50,
  });
}

class _DemoSentenceObjectSpottingState extends State<DemoSentenceObjectSpotting> {
  int _currentRoundIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();
  List<IconItem> _icons = [];
  bool _isRoundSetup = false;
  
  String _sentenceStart = '';
  String _highlightedWord = '';
  String _sentenceEnd = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupRound(double maxWidth, double maxHeight) {
    if (_currentRoundIndex >= widget.activityNode.rounds.length) return;

    final roundData = widget.activityNode.rounds[_currentRoundIndex];
    
    _sentenceStart = roundData['sentence_start'] as String? ?? '';
    _highlightedWord = roundData['highlighted_word'] as String? ?? '';
    _sentenceEnd = roundData['sentence_end'] as String? ?? '';
    
    String targetIcon = roundData['target_icon'] as String? ?? '🌸';
    final distractors = List<String>.from(roundData['distractors'] ?? ['🌳', '🍎']);
    final totalCount = (roundData['total_count'] as int?) ?? 5;

    _icons = [];
    
    // Add target
    _icons.add(IconItem(iconData: targetIcon, isTarget: true));

    // Add distractors
    for (int i = 0; i < totalCount - 1; i++) {
      String distractor = distractors[_random.nextInt(distractors.length)];
      _icons.add(IconItem(iconData: distractor, isTarget: false));
    }

    // Randomize position and size
    for (var icon in _icons) {
      icon.size = _random.nextDouble() * 30 + 50; // Size between 50 and 80
      // Ensure icons stay within bounds
      icon.left = _random.nextDouble() * (maxWidth - icon.size - 20) + 10;
      icon.top = _random.nextDouble() * (maxHeight - icon.size - 20) + 10;
    }

    _icons.shuffle(_random);
    _isRoundSetup = true;
  }

  Future<void> _playChime(bool success) async {
    try {
      final assetPath = success ? 'audio/correct.mp3' : 'audio/wrong.mp3';
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  void _handleIconTap(IconItem icon) async {
    final telemetry = context.findAncestorStateOfType<TelemetryWrapperState>();

    if (icon.isTarget) {
      await _playChime(true);
      telemetry?.completeRound(100);

      setState(() {
        _isRoundSetup = false;
        if (_currentRoundIndex < widget.activityNode.rounds.length - 1) {
          _currentRoundIndex++;
        } else {
          telemetry?.completeActivity(context);
        }
      });
    } else {
      await _playChime(false);
      telemetry?.recordMisclick();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRoundIndex >= widget.activityNode.rounds.length) {
      return const Center(child: Text('Activity Complete!'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E6),
      appBar: AppBar(
        title: Text(widget.activityNode.title),
        backgroundColor: Colors.orange,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ]
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.w500, 
                    color: Colors.black87,
                  ),
                  children: [
                    TextSpan(text: _sentenceStart),
                    TextSpan(
                      text: _highlightedWord,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(text: _sentenceEnd),
                  ],
                ),
              ),
            ),
            const Text(
              'Find the matching object!',
              style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (!_isRoundSetup) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _setupRound(constraints.maxWidth, constraints.maxHeight);
                      });
                    });
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Stack(
                    children: _icons.map((icon) {
                      return Positioned(
                        left: icon.left,
                        top: icon.top,
                        child: GestureDetector(
                          onTap: () => _handleIconTap(icon),
                          child: Text(
                            icon.iconData,
                            style: TextStyle(
                              fontSize: icon.size,
                              shadows: const [
                                Shadow(
                                  blurRadius: 4.0,
                                  color: Colors.black26,
                                  offset: Offset(2.0, 2.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

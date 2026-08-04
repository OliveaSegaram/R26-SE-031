import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../models/curriculum_models.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import 'dart:math';

class DemoIconSpotting extends StatefulWidget {
  final ActivityNode activityNode;

  const DemoIconSpotting({Key? key, required this.activityNode})
      : super(key: key);

  @override
  State<DemoIconSpotting> createState() => _DemoIconSpottingState();
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

class _DemoIconSpottingState extends State<DemoIconSpotting> {
  int _currentRoundIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();
  List<IconItem> _icons = [];
  bool _isRoundSetup = false;
  String _targetIcon = '';

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
    _targetIcon = roundData['target'] as String? ?? '🌸';
    final distractors = List<String>.from(roundData['distractors'] ?? ['🌳', '🍎']);
    final totalCount = (roundData['total_count'] as int?) ?? 5;

    _icons = [];
    
    // Add target
    _icons.add(IconItem(iconData: _targetIcon, isTarget: true));

    // Add distractors
    for (int i = 0; i < totalCount - 1; i++) {
      String distractor = distractors[_random.nextInt(distractors.length)];
      _icons.add(IconItem(iconData: distractor, isTarget: false));
    }

    // Randomize position and size
    for (var icon in _icons) {
      icon.size = _random.nextDouble() * 40 + 40; // Size between 40 and 80
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
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(widget.activityNode.title),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Find this: $_targetIcon',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (!_isRoundSetup) {
                    // Schedule setup round after layout pass
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
                            style: TextStyle(fontSize: icon.size),
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

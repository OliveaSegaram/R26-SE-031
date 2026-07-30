import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';

class DemoShadowMatch extends StatefulWidget {
  final ActivityNode activityNode;
  const DemoShadowMatch({super.key, required this.activityNode});

  @override
  State<DemoShadowMatch> createState() => _DemoShadowMatchState();
}

class _DemoShadowMatchState extends State<DemoShadowMatch> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int _currentRoundIndex = 0;
  List<String> _items = [];
  List<String> _shadows = [];
  Map<String, bool> _matched = {};
  bool _isComplete = false;

  final Map<String, String> _itemToEmoji = {
    'goat': '🐐', 'whale': '🐋', 'crown': '👑', 'device': '🤖',
    'dog': '🐶', 'cat': '🐱', 'bird': '🐦', 'fish': '🐟',
    'apple': '🍎', 'banana': '🍌', 'grape': '🍇', 'orange': '🍊',
    'car': '🚗', 'bus': '🚌', 'train': '🚆', 'plane': '✈️',
    'sun': '☀️', 'moon': '🌙', 'star': '⭐', 'cloud': '☁️',
    'book': '📖', 'pencil': '✏️', 'ruler': '📏', 'bag': '🎒'
  };

  @override
  void initState() {
    super.initState();
    _setupRound();
  }

  void _setupRound() {
    if (_currentRoundIndex < widget.activityNode.rounds.length) {
      final roundData = widget.activityNode.rounds[_currentRoundIndex];
      _items = List<String>.from(roundData['items'] ?? []);
      _shadows = List<String>.from(roundData['shadows'] ?? []);
    }
    _matched = { for (var item in _items) item: false };
    _isComplete = false;
  }

  void _onAccept(String shadow, String draggedItem) async {
    bool isCorrect = shadow == draggedItem;

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
          if (_currentRoundIndex < widget.activityNode.rounds.length - 1) {
            setState(() {
              _currentRoundIndex++;
            });
            _setupRound();
          } else {
            final wrapper = context.findAncestorStateOfType<TelemetryWrapperState>();
            if (wrapper != null) {
              wrapper.completeActivity(context);
            } else {
              Navigator.pop(context, 100);
            }
          }
        });
      }
    } else {
      context.findAncestorStateOfType<TelemetryWrapperState>()?.recordMisclick();
      await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Colors.redAccent, width: 4),
            ),
            title: Text(
              'Wrong Answer Think Again!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Try Again', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        );
      }
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
      backgroundColor: const Color(0xFF1E4B5E),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F8A8B),
                  borderRadius: BorderRadius.only(topLeft: Radius.elliptical(200, 40), topRight: Radius.elliptical(200, 40)),
                ),
              ),
            ),
            
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.home, color: Colors.amber, size: 32),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              LinearProgressIndicator(
                                value: (_currentRoundIndex + 1) / widget.activityNode.rounds.length,
                                backgroundColor: Colors.white,
                                color: Colors.amber,
                                minHeight: 16,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber, width: 4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.activityNode.description,
                          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.findAncestorStateOfType<TelemetryWrapperState>()?.logAudioReplay();
                        },
                        child: const CircleAvatar(
                          backgroundColor: Colors.amber,
                          radius: 20,
                          child: Icon(Icons.volume_up, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF5E6),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 10), blurRadius: 10)]
                    ),
                    child: Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: _shadows.map((shadow) {
                          final isMatched = _matched[shadow] ?? false;
                          final emojiStr = _itemToEmoji[shadow] ?? '❓';
                          return DragTarget<String>(
                            onWillAcceptWithDetails: (details) => !isMatched,
                            onAcceptWithDetails: (details) => _onAccept(shadow, details.data),
                            builder: (context, candidateData, rejectedData) {
                              return isMatched
                                  ? Text(emojiStr, style: const TextStyle(fontSize: 60))
                                  : ColorFiltered(
                                      colorFilter: const ColorFilter.matrix(<double>[
                                        0, 0, 0, 0, 0,
                                        0, 0, 0, 0, 0,
                                        0, 0, 0, 0, 0,
                                        0, 0, 0, 0.4, 0,
                                      ]),
                                      child: Text(emojiStr, style: const TextStyle(fontSize: 60)),
                                    );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: _items.map((item) {
                      final isMatched = _matched[item] ?? false;
                      final emojiStr = _itemToEmoji[item] ?? '❓';
                      return isMatched
                          ? const SizedBox(width: 70, height: 70)
                          : Draggable<String>(
                              data: item,
                              feedback: Material(color: Colors.transparent, child: Text(emojiStr, style: const TextStyle(fontSize: 70))),
                              childWhenDragging: Opacity(opacity: 0.3, child: Text(emojiStr, style: const TextStyle(fontSize: 60))),
                              child: Text(emojiStr, style: const TextStyle(fontSize: 60)),
                            );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 100), // Space for astronaut
              ],
            ),
            
            Positioned(
              bottom: 10, right: 10,
              child: const Icon(Icons.rocket_launch, color: Colors.white, size: 80),
            ),
          ],
        ),
      ),
    );
  }
}

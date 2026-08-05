import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';

class DemoShapePattern extends StatefulWidget {
  final ActivityNode activityNode;
  const DemoShapePattern({super.key, required this.activityNode});

  @override
  State<DemoShapePattern> createState() => _DemoShapePatternState();
}

class _DemoShapePatternState extends State<DemoShapePattern> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int _currentRoundIndex = 0;
  List<Map<String, dynamic>> _shapes = [];
  List<Map<String, dynamic>> _palette = [];
  
  int? _selectedPencilIndex;

  final Map<String, Color> _colorMap = {
    'green': Colors.green, 'orange': Colors.orange, 'purple': Colors.purple,
    'blue': Colors.blue, 'red': Colors.red, 'yellow': Colors.amber, 'pink': Colors.pink
  };

  @override
  void initState() {
    super.initState();
    _setupRound();
  }

  Map<String, dynamic> _parsePalette(String key) {
    final parts = key.split('_');
    return {'color': _colorMap[parts[0]] ?? Colors.grey, 'shape': parts[1]};
  }

  void _setupRound() {
    if (_currentRoundIndex < widget.activityNode.rounds.length) {
      final roundData = widget.activityNode.rounds[_currentRoundIndex];
      final rawPalette = List<String>.from(roundData['palette'] ?? []);
      final rawShapes = List<String>.from(roundData['shapes'] ?? []);
      
      _palette = rawPalette.map((p) => _parsePalette(p)).toList();
      _shapes = rawShapes.map((s) => {'shape': s, 'isColored': false, 'color': Colors.transparent}).toList();
    }
    _selectedPencilIndex = null;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onShapeTapped(int index) async {
    if (_selectedPencilIndex == null) return;
    
    final pencil = _palette[_selectedPencilIndex!];
    final targetShape = _shapes[index];

    if (targetShape['isColored']) return; // Already solved

    if (pencil['shape'] == targetShape['shape']) {
      setState(() {
        _shapes[index]['isColored'] = true;
        _shapes[index]['color'] = pencil['color'];
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      // Check if all are colored
      bool allColored = _shapes.every((s) => s['isColored']);
      if (allColored) {
        context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(100);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          if (_currentRoundIndex < widget.activityNode.rounds.length - 1) {
            setState(() {
              _currentRoundIndex++;
            });
            _setupRound();
          } else {
            context.findAncestorStateOfType<TelemetryWrapperState>()?.completeActivity(context);
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.redAccent, width: 4)),
            title: Text('Wrong Answer Think Again!', textAlign: TextAlign.center, style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Try Again', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildShape(String shapeType, Color color, {double size = 60, bool isBorderOnly = false}) {
    if (shapeType == 'square') {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: isBorderOnly ? Colors.white : color,
          border: isBorderOnly ? Border.all(color: Colors.black, width: 3) : null,
        ),
      );
    } else if (shapeType == 'circle') {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: isBorderOnly ? Colors.white : color,
          shape: BoxShape.circle,
          border: isBorderOnly ? Border.all(color: Colors.black, width: 3) : null,
        ),
      );
    } else if (shapeType == 'star') {
      return Icon(Icons.star, color: isBorderOnly ? Colors.grey : color, size: size + 10);
    } else if (shapeType == 'heart') {
      return Icon(Icons.favorite, color: isBorderOnly ? Colors.grey : color, size: size + 10);
    } else if (shapeType == 'moon') {
      return Icon(Icons.nightlight_round, color: isBorderOnly ? Colors.grey : color, size: size + 10);
    } else {
      return Icon(Icons.change_history, color: isBorderOnly ? Colors.grey : color, size: size + 20); // Triangle approx
    }
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
                          child: LinearProgressIndicator(
                            value: (_currentRoundIndex + 1) / widget.activityNode.rounds.length,
                            backgroundColor: Colors.white,
                            color: Colors.amber,
                            minHeight: 16,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDF5E6),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16,
                              runSpacing: 16,
                              children: _shapes.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                return GestureDetector(
                                  onTap: () => _onShapeTapped(index),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: _buildShape(item['shape'], item['color'], size: 80, isBorderOnly: !item['isColored']),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 48),
                          
                          // Pencils Palette
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDF5E6),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 24,
                              runSpacing: 16,
                              children: _palette.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final item = entry.value;
                                final isSelected = _selectedPencilIndex == idx;
                                
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPencilIndex = idx;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: isSelected ? Colors.amber : Colors.transparent, width: 4),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        // Fake pencil background
                                        Container(
                                          margin: const EdgeInsets.only(left: 30),
                                          width: 80, height: 50,
                                          decoration: BoxDecoration(color: item['color'], borderRadius: BorderRadius.circular(4)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black12)),
                                          child: _buildShape(item['shape'], item['color'], size: 30),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
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

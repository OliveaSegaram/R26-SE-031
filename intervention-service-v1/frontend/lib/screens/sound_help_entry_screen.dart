import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/reading_theme.dart';
import '../widgets/cycle_widgets.dart';
import '../widgets/mascot.dart';
import 'cycle_play_screen.dart';

/// Entry hub for the C4 help game — pick a word, play with the owl.
class SoundHelpEntryScreen extends StatefulWidget {
  const SoundHelpEntryScreen({super.key, this.childId = 'child_demo_1'});

  final String childId;

  @override
  State<SoundHelpEntryScreen> createState() => _SoundHelpEntryScreenState();
}

class _SoundHelpEntryScreenState extends State<SoundHelpEntryScreen> {
  final _words = const [
    {'word': 'ටැඹ', 'label': 'ටැඹ', 'hint': 'Look-alike letters'},
    {'word': 'කැමති', 'label': 'කැ', 'hint': 'Short / long pillam'},
    {'word': 'ක්‍රීඩා', 'label': 'ක්‍ර', 'hint': 'Blend train'},
    {'word': 'ගෙදර', 'label': 'ගෙ', 'hint': 'Everyday word'},
  ];

  String _selected = 'ටැඹ';
  bool _tired = false;

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CyclePlayScreen(
          childId: widget.childId,
          word: _selected,
          fatigue: _tired ? 0.85 : 0.15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftPlayBg(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const Mascot(
                  size: 96,
                  message: 'Stuck on a sound? Let’s play and listen!',
                ),
                const SizedBox(height: 10),
                Text('Pick a word', style: ReadingKidTheme.title),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                    children: [
                      for (final w in _words)
                        _WordTile(
                          glyph: w['label']!,
                          hint: w['hint']!,
                          selected: _selected == w['word'],
                          onTap: () => setState(() => _selected = w['word']!),
                        ),
                    ],
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('I’m a bit tired', style: ReadingKidTheme.hint),
                  subtitle: Text(
                    'Shorter game (Listen → Check)',
                    style: ReadingKidTheme.hint.copyWith(fontSize: 12),
                  ),
                  value: _tired,
                  activeThumbColor: const Color(0xFF8C86A8),
                  onChanged: (v) => setState(() => _tired = v),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8C86A8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _start,
                    child: const Text(
                      'Play with helper owl',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.glyph,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String glyph;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF8C86A8) : const Color(0xFFE2DFEB),
            width: selected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8C86A8).withOpacity(.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(glyph, style: ReadingKidTheme.chunk.copyWith(fontSize: 40)),
            const SizedBox(height: 4),
            Text(hint, style: ReadingKidTheme.hint.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

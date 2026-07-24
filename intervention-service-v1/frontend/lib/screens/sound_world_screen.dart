import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/play_theme.dart';
import '../widgets/play_sky.dart';
import '../widgets/sound_buddy.dart';
import 'sound_adventure_screen.dart';

/// Brand-new entry world — island cards, no owl, no old hub chrome.
class SoundWorldScreen extends StatefulWidget {
  const SoundWorldScreen({super.key, this.childId = 'child_demo_1'});

  final String childId;

  @override
  State<SoundWorldScreen> createState() => _SoundWorldScreenState();
}

class _SoundWorldScreenState extends State<SoundWorldScreen> {
  final _islands = const [
    _Island(
      word: 'ටැඹ',
      title: 'Twin Letters',
      emoji: '🔎',
      color: Color(0xFF7B6CF6),
      blurb: 'Spot the look-alike',
    ),
    _Island(
      word: 'කැමති',
      title: 'Pillam Pop',
      emoji: '🎵',
      color: Color(0xFFFF6B6B),
      blurb: 'Short vs long sound',
    ),
    _Island(
      word: 'ක්‍රීඩා',
      title: 'Blend Train',
      emoji: '🚂',
      color: Color(0xFF3DDC97),
      blurb: 'Grow the word',
    ),
    _Island(
      word: 'ගෙදර',
      title: 'Home Sounds',
      emoji: '🏠',
      color: Color(0xFFFFC857),
      blurb: 'Everyday word play',
    ),
  ];

  String _picked = 'ටැඹ';
  bool _sleepy = false;

  Future<void> _go() async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, a, __) => SoundAdventureScreen(
          childId: widget.childId,
          word: _picked,
          fatigue: _sleepy ? 0.85 : 0.12,
        ),
        transitionsBuilder: (_, a, __, child) {
          return FadeTransition(
            opacity: a,
            child: ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(
                CurvedAnimation(parent: a, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PlaySky(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: PlayTheme.ink,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: PlayTheme.foam.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'SOUND WORLD',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: PlayTheme.ink,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SoundBuddy(
                  mood: _sleepy ? BuddyMood.sleep : BuddyMood.hello,
                  size: 118,
                  line: _sleepy
                      ? 'Short adventure today — soft & easy!'
                      : 'Pick an island. Tap. Listen. Play!',
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    itemCount: _islands.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.92,
                    ),
                    itemBuilder: (context, i) {
                      final island = _islands[i];
                      final on = _picked == island.word;
                      return _IslandCard(
                        island: island,
                        selected: on,
                        onTap: () => setState(() => _picked = island.word),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => setState(() => _sleepy = !_sleepy),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _sleepy
                          ? PlayTheme.ice
                          : PlayTheme.foam.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _sleepy ? PlayTheme.grape : Colors.white54,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _sleepy
                              ? Icons.bedtime_rounded
                              : Icons.wb_sunny_rounded,
                          color: PlayTheme.ink,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _sleepy
                                ? 'Sleepy mode ON · shorter game'
                                : 'Full energy mode',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: PlayTheme.ink,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: _sleepy,
                          activeThumbColor: PlayTheme.grape,
                          onChanged: (v) => setState(() => _sleepy = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: PlayTheme.coral,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: _go,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Start Adventure',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.rocket_launch_rounded, size: 26),
                      ],
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

class _Island {
  const _Island({
    required this.word,
    required this.title,
    required this.emoji,
    required this.color,
    required this.blurb,
  });
  final String word;
  final String title;
  final String emoji;
  final Color color;
  final String blurb;
}

class _IslandCard extends StatelessWidget {
  const _IslandCard({
    required this.island,
    required this.selected,
    required this.onTap,
  });

  final _Island island;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.identity()..scale(selected ? 1.03 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              island.color,
              island.color.withValues(alpha: 0.75),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? Colors.white : Colors.white54,
            width: selected ? 4 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: island.color.withValues(alpha: 0.45),
              blurRadius: selected ? 22 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(island.emoji, style: const TextStyle(fontSize: 28)),
            const Spacer(),
            Text(
              island.word,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              island.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              island.blurb,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

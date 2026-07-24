import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/reading_theme.dart';

/// Hal Kirima freezer — slide to clip the vowel sound.
class SoundFreezer extends StatefulWidget {
  const SoundFreezer({
    super.key,
    required this.openGlyph,
    required this.frozenGlyph,
    required this.onPlayOpen,
    required this.onPlayFrozen,
    this.onFrozen,
  });

  final String openGlyph;
  final String frozenGlyph;
  final VoidCallback onPlayOpen;
  final VoidCallback onPlayFrozen;
  final VoidCallback? onFrozen;

  @override
  State<SoundFreezer> createState() => _SoundFreezerState();
}

class _SoundFreezerState extends State<SoundFreezer> {
  double _v = 0;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final frozen = _v > 0.72;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          decoration: BoxDecoration(
            color: frozen ? const Color(0xFFD9EEF7) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: frozen ? const Color(0xFF8C86A8) : const Color(0xFFE2DFEB),
              width: 2.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                frozen ? widget.frozenGlyph : widget.openGlyph,
                style: ReadingKidTheme.chunk.copyWith(fontSize: 64),
              ),
              const SizedBox(width: 10),
              Icon(
                frozen ? Icons.ac_unit_rounded : Icons.wb_sunny_rounded,
                size: 34,
                color: frozen ? const Color(0xFF8C86A8) : const Color(0xFFE8A87C),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          frozen ? 'Frozen! ❄️' : 'Slide to freeze the sound',
          style: ReadingKidTheme.hint,
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 14,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 18),
            activeTrackColor: const Color(0xFF8C86A8),
            inactiveTrackColor: const Color(0xFFE2DFEB),
            thumbColor: const Color(0xFF8C86A8),
          ),
          child: Slider(
            value: _v,
            onChangeStart: (_) => widget.onPlayOpen(),
            onChanged: (v) {
              setState(() => _v = v);
              if (v > 0.72 && !_done) {
                _done = true;
                HapticFeedback.mediumImpact();
                widget.onPlayFrozen();
                widget.onFrozen?.call();
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Progressive blend as a growing train of sounds.
class AksharaTrain extends StatefulWidget {
  const AksharaTrain({
    super.key,
    required this.steps,
    required this.onHear,
    required this.onComplete,
  });

  final List<String> steps;
  final Future<void> Function(String text) onHear;
  final VoidCallback onComplete;

  @override
  State<AksharaTrain> createState() => _AksharaTrainState();
}

class _AksharaTrainState extends State<AksharaTrain> {
  int _n = 0;
  bool _busy = false;

  Future<void> _next() async {
    if (_busy) return;
    if (_n >= widget.steps.length) {
      widget.onComplete();
      return;
    }
    setState(() => _busy = true);
    HapticFeedback.selectionClick();
    await widget.onHear(widget.steps[_n]);
    setState(() {
      _n++;
      _busy = false;
    });
    if (_n >= widget.steps.length) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < widget.steps.length; i++) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: i < _n ? Colors.white : const Color(0xFFE2DFEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: i == _n - 1
                          ? const Color(0xFF8C86A8)
                          : const Color(0xFFD8EDE4),
                      width: i == _n - 1 ? 3 : 2,
                    ),
                  ),
                  child: Text(
                    i < _n ? widget.steps[i] : '?',
                    style: ReadingKidTheme.chunk.copyWith(fontSize: 32),
                  ),
                ),
                if (i < widget.steps.length - 1)
                  const Icon(Icons.arrow_forward_rounded,
                      color: Color(0xFFE2DFEB)),
              ],
              const SizedBox(width: 6),
              const Icon(Icons.train_rounded, color: Color(0xFF8C86A8), size: 34),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF8C86A8),
            minimumSize: const Size(210, 54),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          onPressed: _busy ? null : _next,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(_n >= widget.steps.length ? 'Done!' : 'Next sound'),
        ),
      ],
    );
  }
}

class CelebratePane extends StatefulWidget {
  const CelebratePane({super.key, required this.onDone, this.message = 'Great listening!'});
  final VoidCallback onDone;
  final String message;

  @override
  State<CelebratePane> createState() => _CelebratePaneState();
}

class _CelebratePaneState extends State<CelebratePane> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F7F4).withOpacity(.97),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(widget.message, style: ReadingKidTheme.title),
            const SizedBox(height: 8),
            const Icon(Icons.park_rounded, size: 48, color: Color(0xFF7CB89A)),
          ],
        ),
      ),
    );
  }
}

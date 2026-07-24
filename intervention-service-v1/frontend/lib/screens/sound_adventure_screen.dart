import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/c4_api.dart';
import '../services/reading_audio_service.dart';
import '../theme/play_theme.dart';
import '../widgets/play_sky.dart';
import '../widgets/sound_buddy.dart';

/// Brand-new interactive adventure stages (no owl / no old cards UI).
class SoundAdventureScreen extends StatefulWidget {
  const SoundAdventureScreen({
    super.key,
    required this.childId,
    required this.word,
    this.fatigue = 0.0,
    this.zoneHint = 'start',
  });

  final String childId;
  final String word;
  final double fatigue;
  final String zoneHint;

  @override
  State<SoundAdventureScreen> createState() => _SoundAdventureScreenState();
}

class _SoundAdventureScreenState extends State<SoundAdventureScreen>
    with TickerProviderStateMixin {
  final _api = C4Api();
  final _audio = ReadingAudioService.instance;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _payload;
  bool _playing = false;
  bool _celebrate = false;
  bool _unlocked = false;
  bool _listenHint = false;
  String? _picked;
  double _freeze = 0;
  int _trainIdx = 0;

  late final AnimationController _ring;

  String get _stage => (_payload?['stage'] as String?) ?? 'TEACH';
  String get _cycleId => (_payload?['cycle_id'] as String?) ?? '';
  String get _engine => (_payload?['engine'] as String?) ?? '';
  Map<String, dynamic> get _content =>
      Map<String, dynamic>.from(_payload?['content'] as Map? ?? {});

  int get _step {
    switch (_stage) {
      case 'TEACH':
        return 1;
      case 'GUIDED_PRACTICE':
        return 2;
      case 'INDEPENDENT_ACTIVITY':
        return 3;
      case 'REINFORCEMENT':
        return 4;
      case 'PROGRESS_CHECK':
        return 5;
      default:
        return 5;
    }
  }

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _audio.init();
    _boot();
  }

  @override
  void dispose() {
    _ring.dispose();
    _audio.stop();
    super.dispose();
  }

  Future<void> _boot() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trig = await _api.trigger(
        childId: widget.childId,
        word: widget.word,
        phonologicalStrainIndex: 0.65,
        sessionFatigueIndex: widget.fatigue,
        errorPatternVector: const [1, 0, 1, 0],
        zoneHint: widget.zoneHint,
      );
      if (trig['triggered'] != true) {
        throw Exception(trig['reason'] ?? 'Could not start');
      }
      final start = await _api.startCycle(
        childId: widget.childId,
        tag: trig['tag'] as String,
        specificInstance: trig['specific_instance'],
        word: widget.word,
        cycleMode: trig['cycle_mode'] as String?,
        localizationZone: trig['localization_zone'] as String?,
        localizationConfidence:
            (trig['localization_confidence'] as num?)?.toDouble(),
        errorPatternFlags:
            (trig['error_pattern_flags'] as List?)?.cast<String>(),
      );
      setState(() {
        _payload = start;
        _loading = false;
        _unlocked = false;
        _freeze = 0;
        _trainIdx = 0;
      });
      await Future<void>.delayed(const Duration(milliseconds: 280));
      await _playAudio();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<String> _texts() {
    final seq = _content['play_sequence'] as List? ?? [];
    final fromSeq = seq
        .map((e) => (e as Map)['text']?.toString() ?? '')
        .where((t) => t.isNotEmpty)
        .toList();
    if (fromSeq.isNotEmpty) return fromSeq;
    final glyphs = _content['display_glyphs'] as List? ?? [];
    return glyphs.map((e) => e.toString()).toList();
  }

  Future<void> _say(String text) => _audio.speak(text);

  Future<void> _playAudio() async {
    setState(() => _playing = true);
    try {
      for (final t in _texts()) {
        await _say(t);
        await Future<void>.delayed(const Duration(milliseconds: 280));
      }
      if (mounted) {
        setState(() {
          _unlocked = true;
          _listenHint = false;
        });
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _advance(Map<String, dynamic> response) async {
    final next = await _api.respond(
      cycleId: _cycleId,
      stage: _stage,
      response: response,
    );
    if (next['exit'] == true) {
      setState(() => _celebrate = true);
      return;
    }
    setState(() {
      _payload = next;
      _unlocked = false;
      _picked = null;
      _listenHint = false;
      _freeze = 0;
      _trainIdx = 0;
    });
    if (_stage == 'REINFORCEMENT') {
      setState(() => _celebrate = true);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 220));
    await _playAudio();
  }

  Future<void> _onChoice(Map choice) async {
    if (!_unlocked) {
      setState(() => _listenHint = true);
      await _playAudio();
      return;
    }
    final id = choice['id']?.toString();
    final correct = choice['is_correct'] == true;
    setState(() => _picked = id);
    final glyph = choice['display_glyph']?.toString() ??
        choice['label_si']?.toString() ??
        choice['label_en']?.toString();
    if (glyph != null && glyph.isNotEmpty) await _say(glyph);
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 320));
    await _advance({'correct': correct, 'choice_id': id});
  }

  BuddyMood get _mood {
    if (_celebrate || _stage == 'REINFORCEMENT') return BuddyMood.yay;
    if (_playing) return BuddyMood.listen;
    if (_listenHint) return BuddyMood.think;
    return BuddyMood.hello;
  }

  String get _line {
    if (_listenHint) return 'Ears first! Tap the big speaker.';
    switch (_stage) {
      case 'TEACH':
        return 'Watch the letter dance — then listen!';
      case 'GUIDED_PRACTICE':
        return _content['prompt_en']?.toString() ?? 'Tap the matching sound!';
      case 'INDEPENDENT_ACTIVITY':
        return 'Your turn — you got this!';
      case 'PROGRESS_CHECK':
        return 'Boss round! No hints.';
      case 'REINFORCEMENT':
        return 'You did it!';
      default:
        return 'Let’s play!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sky = _celebrate
        ? SkyVariant.party
        : (_engine == 'EchoEngine' ? SkyVariant.ice : SkyVariant.day);

    return Scaffold(
      body: PlaySky(
        variant: sky,
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: SoundBuddy(
                    mood: BuddyMood.think,
                    line: 'Opening the sound portal…',
                  ),
                )
              : _error != null
                  ? _Err(error: _error!, onRetry: _boot)
                  : Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: Column(
                            children: [
                              _TopBar(
                                step: _step,
                                onClose: () => Navigator.pop(context),
                                label: _stageTitle(_stage),
                              ),
                              SoundBuddy(
                                mood: _mood,
                                size: 96,
                                line: _line,
                              ),
                              const SizedBox(height: 4),
                              Expanded(child: _stageBody()),
                              const SizedBox(height: 8),
                              _SpeakerPad(
                                playing: _playing,
                                onTap: _playAudio,
                                ring: _ring,
                              ),
                              if (_stage == 'TEACH') ...[
                                const SizedBox(height: 10),
                                _PillButton(
                                  label: 'I heard it — next!',
                                  color: PlayTheme.grape,
                                  onTap: () => _advance({}),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_celebrate)
                          _PartyOverlay(
                            onDone: () {
                              if (_payload?['exit'] == true ||
                                  _payload?['summary'] != null) {
                                Navigator.pop(context, true);
                              } else {
                                setState(() => _celebrate = false);
                                _advance({});
                              }
                            },
                          ),
                      ],
                    ),
        ),
      ),
    );
  }

  String _stageTitle(String s) {
    switch (s) {
      case 'TEACH':
        return 'LISTEN';
      case 'GUIDED_PRACTICE':
        return 'TRY';
      case 'INDEPENDENT_ACTIVITY':
        return 'SOLO';
      case 'REINFORCEMENT':
        return 'YAY';
      case 'PROGRESS_CHECK':
        return 'CHECK';
      default:
        return s;
    }
  }

  Widget _stageBody() {
    if (_engine == 'EchoEngine') return _echoBody();
    if (_engine == 'ProgressiveRevealEngine') return _trainBody();
    return _discrimBody();
  }

  Widget _discrimBody() {
    final choices = (_content['choices'] as List?) ?? [];
    final glyphs = (_content['display_glyphs'] as List?) ?? [];

    if (_stage == 'TEACH') {
      final show = glyphs.take(2).toList();
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < show.length; i++)
            _OrbitGlyph(
              glyph: show[i].toString(),
              color: i == 0 ? PlayTheme.grape : PlayTheme.coral,
              controller: _ring,
            ),
        ],
      );
    }

    if (choices.isEmpty) {
      return const Center(child: Text('…', style: PlayTheme.glyph));
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PassivePicture(ref: _content['picture_ref']?.toString()),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            alignment: WrapAlignment.center,
            children: [
              for (final raw in choices)
                _BounceTile(
                  glyph: _glyph(Map<String, dynamic>.from(raw as Map)),
                  selected: _picked == raw['id']?.toString(),
                  color: (raw['is_correct'] == true)
                      ? PlayTheme.leaf
                      : PlayTheme.grape,
                  onTap: () => _onChoice(Map<String, dynamic>.from(raw)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _echoBody() {
    final glyphs = (_content['display_glyphs'] as List?) ?? [];
    final frozen = glyphs.isNotEmpty ? glyphs.first.toString() : 'ක්';
    final open = frozen.replaceAll('\u0DCA', '');
    final show = _freeze > 0.7 ? frozen : (open.isEmpty ? 'ක' : open);

    if (_stage == 'TEACH') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _freeze > 0.7 ? PlayTheme.ice : PlayTheme.foam,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: PlayTheme.grape.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(show, style: PlayTheme.glyph),
                const SizedBox(width: 12),
                Icon(
                  _freeze > 0.7 ? Icons.ac_unit_rounded : Icons.whatshot_rounded,
                  size: 40,
                  color: _freeze > 0.7 ? PlayTheme.grape : PlayTheme.coral,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _freeze > 0.7 ? 'Frozen solid!' : 'Slide to freeze the sound',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 16,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 18),
              activeTrackColor: PlayTheme.grape,
              inactiveTrackColor: Colors.white70,
              thumbColor: PlayTheme.coral,
            ),
            child: Slider(
              value: _freeze,
              onChangeStart: (_) => _say(open.isEmpty ? 'ක' : open),
              onChanged: (v) {
                setState(() => _freeze = v);
                if (v > 0.7) {
                  HapticFeedback.mediumImpact();
                  _say(frozen);
                }
              },
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PassivePicture(ref: _content['picture_ref']?.toString()),
        Text(frozen, style: PlayTheme.glyph.copyWith(fontSize: 72)),
        const SizedBox(height: 12),
        Text('Echo time — say it!',
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        _PillButton(
          label: 'I said it!',
          color: PlayTheme.coral,
          icon: Icons.mic_rounded,
          onTap: () => _advance({'attempted': true}),
        ),
      ],
    );
  }

  Widget _trainBody() {
    final steps = <String>[
      ...((_content['steps'] as List?)
              ?.map((e) => (e as Map)['text']?.toString() ?? '')
              .where((t) => t.isNotEmpty) ??
          const <String>[]),
    ];
    if (steps.isEmpty) steps.addAll(_texts());
    if (steps.isEmpty) steps.add(widget.word);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PassivePicture(ref: _content['picture_ref']?.toString()),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                _TrainCar(
                  text: i < _trainIdx ? steps[i] : '·',
                  lit: i < _trainIdx,
                  active: i == _trainIdx - 1,
                ),
                if (i < steps.length - 1)
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 28),
              ],
              const SizedBox(width: 8),
              const Text('🚂', style: TextStyle(fontSize: 36)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _PillButton(
          label: _trainIdx >= steps.length ? 'All aboard!' : 'Next carriage',
          color: PlayTheme.leaf,
          icon: Icons.play_arrow_rounded,
          onTap: () async {
            if (_trainIdx >= steps.length) {
              await _advance({'attempted': true, 'correct': true});
              return;
            }
            HapticFeedback.selectionClick();
            await _say(steps[_trainIdx]);
            setState(() => _trainIdx++);
            if (_trainIdx >= steps.length) {
              await Future<void>.delayed(const Duration(milliseconds: 400));
              await _advance({'attempted': true, 'correct': true});
            }
          },
        ),
      ],
    );
  }

  String _glyph(Map raw) =>
      raw['display_glyph']?.toString() ??
      raw['label_si']?.toString() ??
      raw['label_en']?.toString() ??
      '?';
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.step,
    required this.onClose,
    required this.label,
  });
  final int step;
  final VoidCallback onClose;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          color: PlayTheme.ink,
        ),
        Expanded(
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: PlayTheme.foam.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    fontSize: 12,
                    color: PlayTheme.ink,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final on = i < step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: on ? 28 : 12,
                    height: 10,
                    decoration: BoxDecoration(
                      color: on ? PlayTheme.coral : Colors.white54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _SpeakerPad extends StatelessWidget {
  const _SpeakerPad({
    required this.playing,
    required this.onTap,
    required this.ring,
  });
  final bool playing;
  final VoidCallback onTap;
  final AnimationController ring;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedBuilder(
        animation: ring,
        builder: (_, __) {
          final pulse = playing ? 1 + sin(ring.value * pi * 2) * 0.08 : 1.0;
          return Transform.scale(
            scale: pulse,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [PlayTheme.grape, Color(0xFF9B8CFF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: PlayTheme.grape.withValues(alpha: 0.45),
                    blurRadius: playing ? 24 : 14,
                    spreadRadius: playing ? 2 : 0,
                  ),
                ],
              ),
              child: Icon(
                playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrbitGlyph extends StatelessWidget {
  const _OrbitGlyph({
    required this.glyph,
    required this.color,
    required this.controller,
  });
  final String glyph;
  final Color color;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final dy = sin(controller.value * 2 * pi) * 8;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: PlayTheme.foam,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color, width: 4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(glyph, style: PlayTheme.glyph.copyWith(fontSize: 52)),
      ),
    );
  }
}

class _BounceTile extends StatefulWidget {
  const _BounceTile({
    required this.glyph,
    required this.onTap,
    required this.color,
    this.selected = false,
  });
  final String glyph;
  final VoidCallback onTap;
  final Color color;
  final bool selected;

  @override
  State<_BounceTile> createState() => _BounceTileState();
}

class _BounceTileState extends State<_BounceTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 90));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 0.9).animate(_c),
      child: GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) {
          _c.reverse();
          widget.onTap();
        },
        onTapCancel: () => _c.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 140,
          height: 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.color,
                widget.color.withValues(alpha: 0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: widget.selected ? Colors.white : Colors.white70,
              width: widget.selected ? 5 : 3,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.glyph,
            style: PlayTheme.glyph.copyWith(color: Colors.white, fontSize: 56),
          ),
        ),
      ),
    );
  }
}

class _TrainCar extends StatelessWidget {
  const _TrainCar({
    required this.text,
    required this.lit,
    required this.active,
  });
  final String text;
  final bool lit;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: lit ? PlayTheme.foam : Colors.white38,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? PlayTheme.coral : Colors.white,
          width: active ? 3 : 2,
        ),
      ),
      child: Text(
        text,
        style: PlayTheme.glyph.copyWith(
          fontSize: 28,
          color: lit ? PlayTheme.ink : PlayTheme.inkSoft,
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onTap,
        icon: Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
      ),
    );
  }
}

class _PartyOverlay extends StatefulWidget {
  const _PartyOverlay({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_PartyOverlay> createState() => _PartyOverlayState();
}

class _PartyOverlayState extends State<_PartyOverlay> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black26,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9A9E), PlayTheme.sun],
            ),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: PlayTheme.coral.withValues(alpha: 0.4),
                blurRadius: 30,
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🌟🎉🌟', style: TextStyle(fontSize: 40)),
              SizedBox(height: 8),
              SoundBuddy(mood: BuddyMood.yay, size: 110, line: null),
              SizedBox(height: 8),
              Text(
                'Awesome listening!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassivePicture extends StatelessWidget {
  /// Passive visual context only — never a tap target for answering.
  const _PassivePicture({this.ref});
  final String? ref;

  @override
  Widget build(BuildContext context) {
    if (ref == null || ref!.isEmpty) return const SizedBox.shrink();
    // Assets not shipped yet — soft placeholder when picture_ref is set.
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: IgnorePointer(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(Icons.image_outlined, size: 40, color: PlayTheme.inkSoft),
        ),
      ),
    );
  }
}

class _Err extends StatelessWidget {
  const _Err({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SoundBuddy(
            mood: BuddyMood.think,
            line: 'Need the helper server on port 8013',
          ),
          const SizedBox(height: 12),
          Text(error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: PlayTheme.inkSoft)),
          const SizedBox(height: 14),
          _PillButton(label: 'Try again', color: PlayTheme.grape, onTap: onRetry),
        ],
      ),
    );
  }
}

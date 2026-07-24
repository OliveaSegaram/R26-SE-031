import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/c4_api.dart';
import '../services/reading_audio_service.dart';
import '../theme/reading_theme.dart';
import '../widgets/cycle_widgets.dart';
import '../widgets/interactive_tasks.dart';
import '../widgets/mascot.dart';

/// Interactive 5-stage C4 cycle UI for Grade-1 kids.
class CyclePlayScreen extends StatefulWidget {
  const CyclePlayScreen({
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
  State<CyclePlayScreen> createState() => _CyclePlayScreenState();
}

class _CyclePlayScreenState extends State<CyclePlayScreen> {
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
    _audio.init();
    // Point TTS audio helper at C4 host if needed for speak endpoints later.
    _boot();
  }

  @override
  void dispose() {
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
      });
      await Future<void>.delayed(const Duration(milliseconds: 300));
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

  Future<void> _say(String text) async {
    await _audio.speak(text);
  }

  Future<void> _playAudio() async {
    setState(() => _playing = true);
    try {
      for (final t in _texts()) {
        await _say(t);
        await Future<void>.delayed(const Duration(milliseconds: 350));
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
    });
    if (_stage == 'REINFORCEMENT') {
      setState(() => _celebrate = true);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
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

    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await _advance({'correct': correct, 'choice_id': id});
  }

  String get _msg {
    if (_listenHint) return 'Listen first — then pick!';
    switch (_stage) {
      case 'TEACH':
        return 'Listen with me…';
      case 'GUIDED_PRACTICE':
        return _content['prompt_en']?.toString() ?? 'Your turn!';
      case 'INDEPENDENT_ACTIVITY':
        return 'You can do this!';
      case 'PROGRESS_CHECK':
        return 'Show what you know!';
      case 'REINFORCEMENT':
        return 'Wonderful listening!';
      default:
        return 'Let’s play!';
    }
  }

  String _stageLabel(String s) {
    switch (s) {
      case 'TEACH':
        return 'Step 1 · Listen';
      case 'GUIDED_PRACTICE':
        return 'Step 2 · Try together';
      case 'INDEPENDENT_ACTIVITY':
        return 'Step 3 · Your turn';
      case 'REINFORCEMENT':
        return 'Step 4 · Yay!';
      case 'PROGRESS_CHECK':
        return 'Step 5 · Check';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftPlayBg(
        mint: _engine == 'EchoEngine' || _stage == 'REINFORCEMENT',
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: Mascot(size: 100, message: 'Getting ready…'),
                )
              : _error != null
                  ? _ErrorView(error: _error!, onRetry: _boot)
                  : Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                  Expanded(
                                      child: StageChip(
                                          label: _stageLabel(_stage))),
                                  const SizedBox(width: 40),
                                ],
                              ),
                              const SizedBox(height: 6),
                              StepDots(current: _step),
                              const SizedBox(height: 8),
                              Mascot(size: 88, message: _msg),
                              const SizedBox(height: 6),
                              Expanded(child: Center(child: _body())),
                              BigPlayOrb(
                                playing: _playing,
                                onTap: _playAudio,
                              ),
                              if (_stage == 'TEACH') ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF8C86A8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    onPressed: () => _advance({}),
                                    child: const Text(
                                      'I heard it!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_celebrate)
                          CelebratePane(
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

  Widget _body() {
    if (_engine == 'EchoEngine') {
      final glyphs = (_content['display_glyphs'] as List?) ?? [];
      final frozen = glyphs.isNotEmpty ? glyphs.first.toString() : 'ක්';
      final open = frozen.replaceAll('\u0DCA', '');
      if (_stage == 'TEACH') {
        return SoundFreezer(
          openGlyph: open.isEmpty ? 'ක' : open,
          frozenGlyph: frozen,
          onPlayOpen: () => _say(open.isEmpty ? 'ක' : open),
          onPlayFrozen: () => _say(frozen),
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(frozen, style: ReadingKidTheme.chunk.copyWith(fontSize: 64)),
          const SizedBox(height: 10),
          Text('Say it like the owl!', style: ReadingKidTheme.hint),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8C86A8),
              minimumSize: const Size(200, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: () => _advance({'attempted': true}),
            icon: const Icon(Icons.mic_rounded),
            label: const Text('I said it!'),
          ),
        ],
      );
    }

    if (_engine == 'ProgressiveRevealEngine') {
      final steps = <String>[
        ...((_content['steps'] as List?)
                ?.map((e) => (e as Map)['text']?.toString() ?? '')
                .where((t) => t.isNotEmpty) ??
            const <String>[]),
      ];
      if (steps.isEmpty) steps.addAll(_texts());
      if (steps.isEmpty) steps.add(widget.word);
      return AksharaTrain(
        steps: steps,
        onHear: _say,
        onComplete: () => _advance({'attempted': true, 'correct': true}),
      );
    }

    // Discrimination
    final choices = (_content['choices'] as List?) ?? [];
    final glyphs = (_content['display_glyphs'] as List?) ?? [];

    if (_stage == 'TEACH') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final g in glyphs.take(2))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 110,
                height: 110,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2DFEB), width: 2),
                ),
                child: Text(
                  g.toString(),
                  style: ReadingKidTheme.chunk.copyWith(fontSize: 52),
                ),
              ),
            ),
        ],
      );
    }

    if (choices.isEmpty) {
      return Text('Listening…', style: ReadingKidTheme.hint);
    }

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: [
        for (final raw in choices)
          GlyphCard(
            glyph: _glyph(raw as Map),
            selected: _picked == raw['id']?.toString(),
            onTap: () => _onChoice(Map<String, dynamic>.from(raw)),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Mascot(
            size: 90,
            message: 'I need the helper server on port 8013',
          ),
          const SizedBox(height: 12),
          Text(
            'Start intervention-service-v1 (python main.py), then try again.',
            textAlign: TextAlign.center,
            style: ReadingKidTheme.hint,
          ),
          const SizedBox(height: 8),
          Text(error,
              textAlign: TextAlign.center,
              style: ReadingKidTheme.hint.copyWith(fontSize: 11)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8C86A8),
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

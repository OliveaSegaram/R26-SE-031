import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/task_models.dart';
import '../services/play_audio_service.dart';
import '../services/task02_api.dart';
import '../theme/play_theme.dart';
import '../widgets/adapted_mind_ui.dart';
import '../widgets/kid_art.dart';

class TaskFlowScreen extends StatefulWidget {
  const TaskFlowScreen({super.key});

  @override
  State<TaskFlowScreen> createState() => _TaskFlowScreenState();
}

class _TaskFlowScreenState extends State<TaskFlowScreen> {
  final _api = Task02Api();
  final _audio = PlayAudioService();

  String? _sessionId;
  TaskQuestion? _question;
  int _answered = 0;
  int _total = 8;
  int _level = 2;
  int _coins = 0;
  bool _loading = true;
  String? _error;
  String? _selectedId;
  bool? _lastCorrect;
  String? _feedback;
  List<String> _slots = [];
  List<String> _tileBag = [];
  String? _matchLeftSelected;
  final Set<String> _matchedWords = {};
  final Map<String, String> _matchAnswers = {};
  List<MatchPair> _leftPairs = [];
  List<MatchPair> _rightPairs = [];
  bool _matchWrongFlash = false;
  SessionSummary? _summary;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.startSession();
      _sessionId = data['session_id'] as String?;
      final q = data['question'] as Map<String, dynamic>?;
      final prog = data['progress'] as Map<String, dynamic>?;
      _applyQuestion(q, prog);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _resetWordBuild() {
    final q = _question;
    _slots = List.filled(q?.correctSequence.length ?? 0, '');
    _tileBag = List<String>.from(q?.tiles ?? []);
  }

  void _resetMatch() {
    final q = _question;
    final pairs = List<MatchPair>.from(q?.pairs ?? []);
    _matchLeftSelected = null;
    _matchedWords.clear();
    _matchAnswers.clear();
    _matchWrongFlash = false;
    _leftPairs = List<MatchPair>.from(pairs)..shuffle();
    _rightPairs = List<MatchPair>.from(pairs)..shuffle();
  }

  void _applyQuestion(Map<String, dynamic>? q, Map<String, dynamic>? prog) {
    setState(() {
      _question = q != null ? TaskQuestion.fromJson(q) : null;
      _answered = prog?['answered'] as int? ?? 0;
      _total = prog?['total'] as int? ?? 8;
      _level = prog?['current_level'] as int? ?? 2;
      _selectedId = null;
      _resetWordBuild();
      if (_question?.taskType == 'picture_word_match') {
        _resetMatch();
      }
      _loading = false;
    });
  }

  Future<void> _speak(String text) async => _audio.speak(text);

  Future<void> _submit(String answer) async {
    if (_sessionId == null || _question == null) return;
    setState(() => _loading = true);
    try {
      final res = await _api.submitAnswer(
        sessionId: _sessionId!,
        answer: answer,
      );
      final correct = res['correct'] as bool? ?? false;
      final completed = res['completed'] as bool? ?? false;
      final action = res['next_action'] as String? ?? '';
      final newLevel = res['new_level'] as int? ?? _level;

      String feedback;
      if (correct) {
        feedback = action == 'level_up' ? 'හොඳයි! අපූක් මට්ටම!' : 'නියමයි!';
        _coins += 10;
      } else if (action == 'level_down') {
        feedback = 'සරල මට්ටමකට යමු!';
      } else {
        feedback = 'ආයෙ උත්සාහ කරමු!';
      }

      if (completed) {
        final sum = res['summary'] as Map<String, dynamic>?;
        setState(() {
          _summary = sum != null ? SessionSummary.fromJson(sum) : null;
          _loading = false;
          _lastCorrect = correct;
          _feedback = feedback;
        });
        return;
      }

      final next = await _api.nextQuestion(_sessionId!);
      setState(() {
        _question = TaskQuestion.fromJson(
          next['question'] as Map<String, dynamic>,
        );
        final prog = next['progress'] as Map<String, dynamic>?;
        _answered = prog?['answered'] as int? ?? _answered;
        _total = prog?['total'] as int? ?? _total;
        _level = newLevel;
        _selectedId = null;
        _resetWordBuild();
        if (_question?.taskType == 'picture_word_match') {
          _resetMatch();
        }
        _lastCorrect = correct;
        _feedback = feedback;
        _loading = false;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _feedback = null);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _feedback = 'සම්බන්ධයේ දෝෂයක්! නැවත උත්සාහ කරන්න.';
        _lastCorrect = false;
      });
    }
  }

  void _tryAnswer(String id) {
    if (_loading || _feedback != null) return;
    setState(() => _selectedId = id);
    _submit(id);
  }

  void _onTileTap(String tile) {
    if (_loading || _question == null) return;
    final idx = _slots.indexWhere((s) => s.isEmpty);
    if (idx < 0) return;
    final bagIdx = _tileBag.indexOf(tile);
    if (bagIdx < 0) return;
    setState(() {
      _tileBag.removeAt(bagIdx);
      _slots[idx] = tile;
      _feedback = null;
    });
  }

  void _onSlotTap(int idx) {
    if (_loading || _question == null || _slots[idx].isEmpty) return;
    setState(() {
      _tileBag.add(_slots[idx]);
      _slots[idx] = '';
      _feedback = null;
    });
  }

  void _tryWordBuildSubmit() {
    if (_loading || _question == null) return;
    if (_slots.any((s) => s.isEmpty)) return;
    final seq = _question!.correctSequence;
    final matches = _slots.length == seq.length &&
        List.generate(seq.length, (i) => _slots[i] == seq[i]).every((x) => x);
    if (matches) {
      _submit(seq.join());
    } else {
      setState(() {
        _feedback = 'ආයෙ උත්සාහ කරමු!';
        _lastCorrect = false;
      });
    }
  }

  void _clearWordBuild() {
    setState(() {
      _resetWordBuild();
      _feedback = null;
    });
  }

  void _onMatchLeftTap(String wordId) {
    if (_loading || _feedback != null || _matchedWords.contains(wordId)) return;
    setState(() {
      _matchLeftSelected = wordId;
      _matchWrongFlash = false;
    });
  }

  void _onMatchRightTap(String wordId) {
    if (_loading || _feedback != null || _matchedWords.contains(wordId)) return;
    final left = _matchLeftSelected;
    if (left == null) return;

    if (left == wordId) {
      setState(() {
        _matchedWords.add(wordId);
        _matchAnswers[wordId] = wordId;
        _matchLeftSelected = null;
        _matchWrongFlash = false;
      });
      if (_matchedWords.length == _question!.pairs.length) {
        _submit(jsonEncode(_matchAnswers));
      }
    } else {
      setState(() {
        _matchLeftSelected = null;
        _matchWrongFlash = true;
        _feedback = 'නැත! ආයෙ උත්සාහ කරමු!';
        _lastCorrect = false;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() {
            _matchWrongFlash = false;
            _feedback = null;
          });
        }
      });
    }
  }

  void _resetMatchRound() {
    setState(_resetMatch);
  }

  @override
  Widget build(BuildContext context) {
    if (_summary != null) return _ResultView(summary: _summary!, coins: _coins);
    if (_loading && _question == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: PlayTheme.purple)),
      );
    }
    if (_error != null && _question == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 48, color: PlayTheme.coral),
                const SizedBox(height: 12),
                const Text('සේවාව සම්බන්ධ කරගත නොහැක',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Backend:', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(AppConfig.baseUrl, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _start, child: const Text('නැවත')),
              ],
            ),
          ),
        ),
      );
    }

    final q = _question!;
    return Scaffold(
      body: AmBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AmProgressBar(
                  answered: _answered,
                  total: _total,
                  coins: _coins,
                  level: _level,
                  onBack: () => Navigator.pop(context),
                ),
                if (_feedback != null) ...[
                  const SizedBox(height: 8),
                  _FeedbackBanner(
                    text: _feedback!,
                    correct: _lastCorrect == true,
                  ),
                ],
                const SizedBox(height: 10),
                Expanded(
                  child: Stack(
                    children: [
                      _bodyFor(q),
                      if (_loading)
                        Container(
                          color: Colors.black26,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF00C853),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bodyFor(TaskQuestion q) {
    return switch (q.taskType) {
      'word_match' => _WordMatchView(
          question: q,
          selectedId: _selectedId,
          showResult: _selectedId != null ? _lastCorrect : null,
          onPick: _tryAnswer,
          onSpeak: _speak,
        ),
      'picture_word' => _PictureWordView(
          question: q,
          selectedId: _selectedId,
          onPick: _tryAnswer,
          onSpeak: _speak,
        ),
      'word_build' => _WordBuildView(
          question: q,
          slots: _slots,
          tileBag: _tileBag,
          feedback: _feedback,
          onTile: _onTileTap,
          onSlotTap: _onSlotTap,
          onSubmit: _tryWordBuildSubmit,
          onSpeak: _speak,
          onClear: _clearWordBuild,
        ),
      'picture_word_match' => _PictureWordMatchView(
          question: q,
          leftPairs: _leftPairs,
          rightPairs: _rightPairs,
          matchedWords: _matchedWords,
          selectedLeft: _matchLeftSelected,
          wrongFlash: _matchWrongFlash,
          onLeftTap: _onMatchLeftTap,
          onRightTap: _onMatchRightTap,
          onReset: _resetMatchRound,
          onSpeak: _speak,
        ),
      _ => const Center(child: Text('Unknown task')),
    };
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.text, required this.correct});
  final String text;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: (correct ? PlayTheme.teal : PlayTheme.sun)
              .withValues(alpha: .2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: correct ? PlayTheme.teal : PlayTheme.coral,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              correct ? Icons.check_circle_rounded : Icons.info_rounded,
              color: correct ? PlayTheme.teal : PlayTheme.coral,
            ),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _WordMatchView extends StatelessWidget {
  const _WordMatchView({
    required this.question,
    required this.onPick,
    required this.onSpeak,
    this.selectedId,
    this.showResult,
  });

  final TaskQuestion question;
  final void Function(String) onPick;
  final Future<void> Function(String) onSpeak;
  final String? selectedId;
  final bool? showResult;

  @override
  Widget build(BuildContext context) {
    final word = question.displayWord ?? question.targetWord ?? '';
    return Column(
      children: [
        AmWordHero(
          word: word,
          hint: question.prompt,
          onSpeak: () => onSpeak(word),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = math.min(
                (constraints.maxWidth - 24) / 3,
                constraints.maxHeight,
              ).clamp(150.0, 260.0);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: question.options.map((o) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: AmBookCard(
                        visual: o.visual,
                        showLabel: false,
                        height: side,
                        bounce: selectedId == null && showResult == null,
                        selected: selectedId == o.id,
                        showResult: selectedId == o.id ? showResult : null,
                        onTap: () => onPick(o.id),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PictureWordView extends StatelessWidget {
  const _PictureWordView({
    required this.question,
    required this.onPick,
    required this.onSpeak,
    this.selectedId,
  });

  final TaskQuestion question;
  final void Function(String) onPick;
  final Future<void> Function(String) onSpeak;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AmPicturePanel(
          visual: question.visual,
          size: 220,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: question.options.map((o) {
              return AmWordChoice(
                label: o.label,
                selected: selectedId == o.id,
                onTap: () => onPick(o.id),
                onSpeak: () => onSpeak(o.label),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _WordBuildView extends StatelessWidget {
  const _WordBuildView({
    required this.question,
    required this.slots,
    required this.tileBag,
    required this.onTile,
    required this.onSlotTap,
    required this.onSubmit,
    required this.onSpeak,
    required this.onClear,
    this.feedback,
  });

  final TaskQuestion question;
  final List<String> slots;
  final List<String> tileBag;
  final String? feedback;
  final void Function(String) onTile;
  final void Function(int) onSlotTap;
  final VoidCallback onSubmit;
  final Future<void> Function(String) onSpeak;
  final VoidCallback onClear;

  bool get _allFilled => !slots.any((s) => s.isEmpty);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AmPicturePanel(
          visual: question.visual,
          size: 200,
          onTap: () => onSpeak(question.targetWord ?? ''),
        ),
        const SizedBox(height: 10),
        Text(
          question.prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        if (feedback != null) ...[
          const SizedBox(height: 6),
          Text(
            feedback!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFF176),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slots.length, (i) {
            final s = slots[i];
            final box = slots.length > 5 ? 52.0 : 64.0;
            final font = slots.length > 5 ? 26.0 : 32.0;
            return GestureDetector(
              onTap: () => onSlotTap(i),
              child: Container(
                width: box,
                height: box + 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: s.isEmpty
                        ? const Color(0xFFBBDEFB)
                        : const Color(0xFF00C853),
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  s.isEmpty ? '?' : s,
                  style: TextStyle(
                    fontSize: font,
                    fontWeight: FontWeight.w900,
                    color: s.isEmpty ? Colors.grey : const Color(0xFF1565C0),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('නැවත', style: TextStyle(color: Colors.white)),
            ),
            AmSpeakerBtn(
              onTap: () => onSpeak(question.targetWord ?? ''),
              size: 44,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: tileBag.map((t) {
              return Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFFFFF176),
                child: InkWell(
                  onTap: () => onTile(t),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    child: Text(t,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w900)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _allFilled ? onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                disabledBackgroundColor: Colors.white38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'හරි! ඊළඟ එක',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PictureWordMatchView extends StatelessWidget {
  const _PictureWordMatchView({
    required this.question,
    required this.leftPairs,
    required this.rightPairs,
    required this.matchedWords,
    required this.onLeftTap,
    required this.onRightTap,
    required this.onReset,
    required this.onSpeak,
    this.selectedLeft,
    this.wrongFlash = false,
  });

  final TaskQuestion question;
  final List<MatchPair> leftPairs;
  final List<MatchPair> rightPairs;
  final Set<String> matchedWords;
  final String? selectedLeft;
  final bool wrongFlash;
  final void Function(String) onLeftTap;
  final void Function(String) onRightTap;
  final VoidCallback onReset;
  final Future<void> Function(String) onSpeak;

  @override
  Widget build(BuildContext context) {
    final total = question.pairs.length;
    final done = matchedWords.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'යුගල $done / $total',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFFF176),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              label: const Text('නැවත', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Balanced width: not full-screen, not too tiny.
              final colWidth = math.min(
                210.0,
                math.max(185.0, constraints.maxWidth * 0.26),
              );
              return Center(
                child: SizedBox(
                  width: colWidth * 2 + 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: colWidth,
                        child: _MatchColumn(
                          title: 'සිංහල වචන',
                          child: Column(
                            children: leftPairs.map((p) {
                              final matched = matchedWords.contains(p.id);
                              final selected = selectedLeft == p.id;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: _MatchWordTile(
                                    word: p.word,
                                    matched: matched,
                                    selected: selected,
                                    wrongFlash: wrongFlash && selected,
                                    onTap: () => onLeftTap(p.id),
                                    onSpeak: () => onSpeak(p.word),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: colWidth,
                        child: _MatchColumn(
                          title: 'පින්තූර',
                          child: Column(
                            children: rightPairs.map((p) {
                              final matched = matchedWords.contains(p.id);
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: _MatchPictureTile(
                                    visual: p.visual,
                                    matched: matched,
                                    onTap: () => onRightTap(p.id),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MatchColumn extends StatelessWidget {
  const _MatchColumn({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: child),
      ],
    );
  }
}

class _MatchWordTile extends StatelessWidget {
  const _MatchWordTile({
    required this.word,
    required this.onTap,
    required this.onSpeak,
    this.matched = false,
    this.selected = false,
    this.wrongFlash = false,
  });

  final String word;
  final bool matched;
  final bool selected;
  final bool wrongFlash;
  final VoidCallback onTap;
  final Future<void> Function() onSpeak;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.white;
    Color border = const Color(0xFFBBDEFB);
    if (matched) {
      bg = const Color(0xFFE8F5E9);
      border = const Color(0xFF00C853);
    } else if (wrongFlash) {
      bg = const Color(0xFFFFEBEE);
      border = PlayTheme.coral;
    } else if (selected) {
      bg = const Color(0xFFE3F2FD);
      border = const Color(0xFF1565C0);
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      elevation: matched ? 0 : 4,
      child: InkWell(
        onTap: matched ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: selected || matched ? 3 : 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (matched)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.check_circle_rounded, color: Color(0xFF00C853), size: 18),
                ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    word,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: matched ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                    ),
                  ),
                ),
              ),
              if (!matched) ...[
                const SizedBox(width: 2),
                GestureDetector(
                  onTap: onSpeak,
                  child: const Icon(Icons.volume_up_rounded, size: 18, color: Color(0xFF7E57C2)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchPictureTile extends StatelessWidget {
  const _MatchPictureTile({
    required this.visual,
    required this.onTap,
    this.matched = false,
  });

  final String visual;
  final bool matched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: matched ? const Color(0xFFE8F5E9) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: matched ? 0 : 4,
      child: InkWell(
        onTap: matched ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: matched ? const Color(0xFF00C853) : const Color(0xFFBBDEFB),
              width: matched ? 3 : 2,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: KidArt(visual: visual),
              ),
              if (matched)
                const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.check_circle_rounded, color: Color(0xFF00C853), size: 24),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.summary, required this.coins});
  final SessionSummary summary;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final color = switch (summary.riskLevel) {
      'low' => PlayTheme.teal,
      'moderate' => PlayTheme.sun,
      _ => PlayTheme.coral,
    };

    return Scaffold(
      body: AmBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    size: 80, color: Color(0xFFFFD600)),
                const SizedBox(height: 12),
                const Text('සුබ පැතුම්!',
                    style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text('+$coins කාසි',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFF176))),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${(summary.accuracy * 100).round()}%',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      const Text('නිවැරදි',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 20)),
                      const SizedBox(height: 12),
                      Text(
                        summary.labelSi,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text('නැවත ක්‍රීඩා කරමු',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
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

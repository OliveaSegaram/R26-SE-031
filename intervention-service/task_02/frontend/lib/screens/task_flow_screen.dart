import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/task_models.dart';
import '../services/play_audio_service.dart';
import '../services/task02_api.dart';
import '../theme/app_theme.dart';
import '../theme/play_theme.dart';
import '../widgets/adapted_mind_ui.dart';
import '../widgets/flip_card_question.dart';
import '../widgets/gradient_button.dart';
import '../widgets/playful_feedback_overlay.dart';
import '../widgets/guided_word_match_view.dart';
import '../widgets/guided_word_build_view.dart';
import '../widgets/guided_picture_word_view.dart';
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
  int _guidanceToken = 0;
  final Set<String> _guidedTaskTypes = {};

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
      _guidedTaskTypes.clear();
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
    _scheduleGuidance();
  }

  void _scheduleGuidance() {
    final token = ++_guidanceToken;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || token != _guidanceToken || _feedback != null) return;
      await _speakTaskPrompt(_question);
    });
  }

  Future<void> _speakTaskPrompt(TaskQuestion? q) async {
    if (q == null) return;
    final taskType = q.taskType;
    if (taskType.isEmpty || _guidedTaskTypes.contains(taskType)) return;
    _guidedTaskTypes.add(taskType);

    final prompt = q.prompt.trim();
    if (prompt.isNotEmpty) await _audio.speak(prompt);
  }

  Future<void> _speakQuestionWord(TaskQuestion q) async {
    final word = switch (q.taskType) {
      'word_match' => (q.displayWord ?? q.targetWord ?? '').trim(),
      'word_build' => (q.targetWord ?? '').trim(),
      _ => '',
    };
    if (word.isNotEmpty) await _audio.speak(word);
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
      await Future.delayed(const Duration(milliseconds: kFeedbackDisplayMs));
      if (mounted) {
        setState(() => _feedback = null);
        _scheduleGuidance();
      }
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
      Future.delayed(const Duration(milliseconds: kFeedbackDisplayMs), () {
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
        backgroundColor: AppColors.darkSlate,
        body: Center(child: CircularProgressIndicator(color: AppColors.mint)),
      );
    }
    if (_error != null && _question == null) {
      return Scaffold(
        backgroundColor: AppColors.darkSlate,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 48, color: AppColors.orange),
                const SizedBox(height: 12),
                Text('සේවාව සම්බන්ධ කරගත නොහැක',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Backend:', style: Theme.of(context).textTheme.bodyLarge),
                Text(AppConfig.baseUrl, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                GradientButton(
                  text: 'නැවත',
                  width: 200,
                  onPressed: _start,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final q = _question!;
    return Scaffold(
      backgroundColor: AppColors.darkSlate,
      body: AmBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width < 420 ? 6 : 12,
              vertical: 10,
            ),
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
                const SizedBox(height: 10),
                Expanded(
                  child: Stack(
                    children: [
                      _bodyFor(q),
                      if (_feedback != null)
                        PlayfulFeedbackOverlay(
                          correct: _lastCorrect == true,
                          message: _feedback,
                        ),
                      if (_loading)
                        Container(
                          color: AppColors.darkSlate.withValues(alpha: 0.6),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.mint,
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
          onSpeakWord: () => _speakQuestionWord(q),
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

class _WordMatchView extends StatelessWidget {
  const _WordMatchView({
    required this.question,
    required this.onPick,
    required this.onSpeakWord,
    this.selectedId,
    this.showResult,
  });

  final TaskQuestion question;
  final void Function(String) onPick;
  final Future<void> Function() onSpeakWord;
  final String? selectedId;
  final bool? showResult;

  @override
  Widget build(BuildContext context) {
    return GuidedWordMatchView(
      question: question,
      selectedId: selectedId,
      showResult: showResult,
      onPick: onPick,
      onSpeakWord: onSpeakWord,
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
    return GuidedPictureWordView(
      question: question,
      selectedId: selectedId,
      onPick: onPick,
      onSpeak: onSpeak,
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

  @override
  Widget build(BuildContext context) {
    return GuidedWordBuildView(
      question: question,
      slots: slots,
      tileBag: tileBag,
      feedback: feedback,
      onTile: onTile,
      onSlotTap: onSlotTap,
      onSubmit: onSubmit,
      onSpeak: onSpeak,
      onClear: onClear,
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
        FlipCardQuestion(text: question.prompt),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'යුගල $done / $total',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    color: AppColors.gold,
                  ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted, size: 20),
              label: Text('නැවත',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      )),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
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
                const SizedBox(width: 8),
                Expanded(
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
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
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
    Color bg = AppColors.darkSlateLight;
    Color border = AppColors.textLight.withValues(alpha: 0.1);
    if (matched) {
      bg = AppColors.mint.withValues(alpha: 0.15);
      border = AppColors.mint;
    } else if (wrongFlash) {
      bg = AppColors.orange.withValues(alpha: 0.12);
      border = AppColors.orange;
    } else if (selected) {
      bg = AppColors.primaryLight.withValues(alpha: 0.35);
      border = AppColors.mint;
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
                  child: Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 18),
                ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    word,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          color: matched ? AppColors.mint : AppColors.textLight,
                        ),
                  ),
                ),
              ),
              if (!matched) ...[
                const SizedBox(width: 2),
                GestureDetector(
                  onTap: onSpeak,
                  child: const Icon(Icons.volume_up_rounded, size: 18, color: AppColors.orange),
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
      color: matched ? AppColors.mint.withValues(alpha: 0.12) : AppColors.darkSlateLight,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: matched ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: matched ? AppColors.mint : AppColors.textLight.withValues(alpha: 0.1),
              width: matched ? 2 : 1,
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
                    child: Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 24),
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
      backgroundColor: AppColors.darkSlate,
      body: AmBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Icon(Icons.emoji_events_rounded, size: 80, color: AppColors.gold),
                const SizedBox(height: 12),
                Text('සුබ පැතුම්!',
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                Text('+$coins කාසි',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.gold,
                        )),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.darkSlateLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.mint.withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${(summary.accuracy * 100).round()}%',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontSize: 56,
                              color: color,
                            ),
                      ),
                      Text('නිවැරදි',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Text(
                        summary.labelSi,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GradientButton(
                  text: 'නැවත ක්‍රීඩා කරමු',
                  height: 58,
                  gradient: AppColors.mintGradient,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

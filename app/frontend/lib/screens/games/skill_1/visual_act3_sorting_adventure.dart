import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sipsara_app/utils/sound_utils.dart';
import '../../../widgets/app_loading_indicator.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../models/curriculum_models.dart';
import '../../../widgets/telemetry_wrapper.dart';
import '../../../theme/app_theme.dart';
import '../../../services/tts_service.dart';
import '../../../services/progress_service.dart';
import '../../../adaptive/controllers/adaptive_task_coordinator.dart';
import '../../../adaptive/models/adaptive_scaffold_models.dart';
import 'logic/sorting_generator.dart';
import 'models/sorting_round.dart';
import 'widgets/pattern_background.dart';
import '../shared_widgets/shared_celebration_popup.dart';

// ──────────────────────────────────────────────────────────────
// Activity 03: Sorting Adventure (Premium Drag & Drop Redesign)
// A polished drag-and-drop sorting game for Grade 1 children
// ──────────────────────────────────────────────────────────────

class VisualAct3SortingAdventure extends StatefulWidget {
  final ActivityNode activityNode;
  final Map<String, dynamic>? studentData;

  const VisualAct3SortingAdventure({
    Key? key,
    required this.activityNode,
    this.studentData,
  }) : super(key: key);

  @override
  _VisualAct3SortingAdventureState createState() =>
      _VisualAct3SortingAdventureState();
}

class _VisualAct3SortingAdventureState extends State<VisualAct3SortingAdventure>
    with TickerProviderStateMixin {
  String _lastSpokenInstruction = '';
  // ── Game state ──
  int _currentRoundIndex = 0;
  late List<SortingRound> _rounds;
  late AdaptiveTaskCoordinator _taskCoordinator;

  // Track items dynamically
  List<String> _objectQueue = [];
  List<String> _visibleObjects = [];
  final int _maxVisible = 3;
  Map<String, List<String>> _sortedObjects = {}; // category -> list of objects

  bool _roundComplete = false;
  bool _activityComplete = false;

  String? _hoveredCategory;
  bool _isDragging = false;

  // Feedback state
  String? _lastCorrectCategory;
  String? _lastWrongCategory;
  String? _lastWrongObject;
  String? _hintedCategory;
  bool _isShowingWorkedExample = false;
  String? _workedExampleObject;
  String? _workedExampleCategory;

  // Worked-example popup controls
  bool _weAnimationComplete = false;
  bool _weIsPlaying = false;
  bool _weDebounceLock = false;
  int _weCurrentStep = 0; // 0=waiting, 1=highlight, 2=move, 3=complete
  Future<bool>? _weNarrationFuture;

  // ── Audio ──
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ── Category accent colors ──
  static const Map<String, Color> _categoryColors = {
    'animals': Color(0xFF82C98B), // Gentle green
    'fruits': Color(0xFFE8A07C), // Warm coral
    'vehicles': Color(0xFF7CB8E8), // Calm blue
    'everyday': Color(0xFFF9C623), // Yellow
    'nature': Color(0xFFDDA0DD), // Plum
  };

  // ── Animation controllers ──
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScale;
  late AnimationController _roundTransitionController;
  late Animation<double> _roundFadeAnimation;

  // Individual float controllers for objects
  final Map<String, AnimationController> _floatControllers = {};
  final Map<String, AnimationController> _entranceControllers = {};

  // Drop feedback controllers
  final Map<String, AnimationController> _categoryGlowControllers = {};
  late AnimationController _wrongShakeController;
  late Animation<double> _wrongShakeAnimation;
  late AnimationController _workedExampleController;
  // Worked-example sub-phase controllers
  late AnimationController _weHighlightController;
  late AnimationController _weMoveController;
  late AnimationController _weGlowController;
  late AnimationController _weOverlayEntryController;
  // Premium WE micro-animation controllers
  late AnimationController _weMascotBreathController;
  late AnimationController _weButtonPulseController;
  late AnimationController _weSparkleController;

  // Authored, non-scored examples. The selected example is always different
  // from every object in the current task, so the demonstration teaches the
  // sorting rule without revealing the learner's current answer.
  static const Map<String, List<String>> _workedExampleAssets = {
    'animals': <String>[
      'animals/turtle.png',
      'animals/snail.png',
      'animals/frog.png',
      'animals/butterfly.png',
    ],
    'fruits': <String>[
      'fruits_food/watermelon.png',
      'fruits_food/grapes.png',
      'fruits_food/orange.png',
      'fruits_food/mango.png',
    ],
    'vehicles': <String>[
      'vehicles/airplane.png',
      'vehicles/boat.png',
      'vehicles/train.png',
      'vehicles/bicycle.png',
    ],
    'flowers': <String>[
      'flowers/wada_mal.png',
      'flowers/araliya.png',
      'flowers/nil_manel.png',
      'flowers/flower_05.png',
    ],
  };

  // ── Mascot ──
  static const List<String> _mascots = [
    'assets/images/characters/human/human_student_1.png',
    'assets/images/characters/mascots/solo_green.png',
    'assets/images/characters/mascots/solo_orange.png',
    'assets/images/characters/mascots/solo_pink.png',
    'assets/images/characters/mascots/solo_yellow.png',
    'assets/images/characters/mascots/solo_teal.png',
  ];
  late String _currentMascot;

  // ── Encouragement messages ──
  static const List<String> _encourageMessages = [
    'හොඳට බලන්න! 👀',
    'ඔයාට පුළුවන්! 💪',
    'හොඳයි, දිගටම! ⭐',
    'මනාව! 🌟',
    'සුපිරියි! 🎉',
  ];
  late String _currentEncouragement;

  // ── Sinhala instructions ──
  static const List<String> _instructions = ['පින්තූර නිවැරදි කූඩයට දමන්න!'];
  late String _currentInstruction;

  // ── Speaker animation ──
  late AnimationController _speakerBounceController;
  late Animation<double> _speakerBounceAnimation;
  @override
  void initState() {
    super.initState();
    _rounds = SortingGenerator.fromCurriculumRounds(widget.activityNode.rounds);
    _currentRoundIndex = ProgressService().getActivityState(
      widget.activityNode.skillId,
      widget.activityNode.id,
    );
    if (_currentRoundIndex >= _rounds.length) _currentRoundIndex = 0;
    _taskCoordinator = AdaptiveTaskCoordinator(
      activity: widget.activityNode,
      initialRoundIndex: _currentRoundIndex,
    );

    final rng = Random();
    _currentMascot = _mascots[rng.nextInt(_mascots.length)];
    _currentEncouragement =
        _encourageMessages[rng.nextInt(_encourageMessages.length)];
    _currentInstruction = _instructions[rng.nextInt(_instructions.length)];

    // Celebration
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _celebrationScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    // Round transition fade
    _roundTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _roundFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _roundTransitionController,
        curve: Curves.easeOut,
      ),
    );

    // Wrong answer shake
    _wrongShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wrongShakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: 8), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _wrongShakeController,
            curve: Curves.easeInOut,
          ),
        );

    _workedExampleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // 3-step demonstration controllers
    _weHighlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _weMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _weGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _weOverlayEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _weMascotBreathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _weButtonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _weSparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );

    // Speaker bounce
    _speakerBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _speakerBounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _speakerBounceController,
        curve: Curves.elasticOut,
      ),
    );

    _initRoundState();
    _roundTransitionController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playInstruction(autoPlay: true);
    });
  }

  void _playInstruction({bool autoPlay = false}) {
    if (autoPlay && _lastSpokenInstruction == _currentInstruction) {
      return;
    }
    _lastSpokenInstruction = _currentInstruction;
    TtsService().speak(_currentInstruction, folder: 'skill_1');
    _speakerBounceController.forward().then((_) {
      _speakerBounceController.reverse();
    });
  }

  void _initRoundState() {
    _hintedCategory = null;
    _objectQueue = List.from(_currentRound.objects);
    _visibleObjects = [];
    _sortedObjects.clear();
    for (var key in _currentRound.categories.keys) {
      _sortedObjects[key] = [];
      _categoryGlowControllers[key] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    }

    // Clear old controllers
    for (var c in _floatControllers.values) {
      c.dispose();
    }
    for (var c in _entranceControllers.values) {
      c.dispose();
    }
    _floatControllers.clear();
    _entranceControllers.clear();

    // Create object controllers
    final rng = Random();
    for (int i = 0; i < _currentRound.objects.length; i++) {
      final obj = _currentRound.objects[i];
      // Randomize float timing slightly
      _floatControllers[obj] = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1800 + rng.nextInt(600)),
      )..repeat(reverse: true);

      _entranceControllers[obj] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    }

    _fillVisibleObjects();
  }

  void _fillVisibleObjects() {
    int delay = 0;
    while (_visibleObjects.length < _maxVisible && _objectQueue.isNotEmpty) {
      final obj = _objectQueue.removeAt(0);
      _visibleObjects.add(obj);

      Future.delayed(Duration(milliseconds: 100 * delay), () {
        if (mounted && _entranceControllers.containsKey(obj)) {
          _entranceControllers[obj]?.forward(from: 0);
        }
      });
      delay++;
    }
  }

  @override
  void dispose() {
    if (_isShowingWorkedExample) {
      unawaited(TtsService().stop());
    }
    _celebrationController.dispose();
    _roundTransitionController.dispose();
    _wrongShakeController.dispose();
    _workedExampleController.dispose();
    _weHighlightController.dispose();
    _weMoveController.dispose();
    _weGlowController.dispose();
    _weOverlayEntryController.dispose();
    _weMascotBreathController.dispose();
    _weButtonPulseController.dispose();
    _weSparkleController.dispose();
    _speakerBounceController.dispose();
    for (var c in _floatControllers.values) {
      c.dispose();
    }
    for (var c in _entranceControllers.values) {
      c.dispose();
    }
    for (var c in _categoryGlowControllers.values) {
      c.dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Game logic ──

  SortingRound get _currentRound =>
      SortingGenerator.fromCurriculum(
        _taskCoordinator.roundData,
        itemId: _taskCoordinator.itemId,
      );

  String? _workedExampleFor(String category, {required String excluding}) {
    final candidates = _workedExampleAssets[category] ?? const <String>[];
    final currentObjects = _currentRound.objects.toSet();
    for (final candidate in candidates) {
      if (candidate != excluding && !currentObjects.contains(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  Future<void> _showWorkedExample({
    required String currentObject,
    required String correctCategory,
  }) async {
    if (_isShowingWorkedExample) return;
    final example = _workedExampleFor(
      correctCategory,
      excluding: currentObject,
    );
    if (example == null) {
      setState(() => _hintedCategory = correctCategory);
      return;
    }
    setState(() {
      _workedExampleObject = example;
      _workedExampleCategory = correctCategory;
      _isShowingWorkedExample = true;
      _weAnimationComplete = false;
      _weIsPlaying = false;
      _weDebounceLock = false;
      _hintedCategory = null;
      _weCurrentStep = 0;
    });
    // Animate the overlay entry + start ambient animations
    _weOverlayEntryController.forward(from: 0);
    _weMascotBreathController.repeat();
    _weSparkleController.repeat();
    // Auto-play the demonstration after a short settle
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isShowingWorkedExample) {
        _playWorkedExampleDemo();
      }
    });
  }

  /// Plays the 3-step demonstration animation sequence.
  Future<void> _playWorkedExampleDemo() async {
    if (_weIsPlaying || !mounted) return;
    _weButtonPulseController
      ..stop()
      ..value = 0;
    setState(() {
      _weIsPlaying = true;
      _weAnimationComplete = false;
    });

    final category = _workedExampleCategory;
    final label =
        (category != null ? _currentRound.categoryLabels[category] : null) ??
        '';

    // Narration is intentionally non-blocking for the visual demonstration,
    // but only one request/playback may exist at a time. This prevents a fast
    // replay tap from creating duplicate downloads or overlapping speech.
    _playWorkedExampleNarration(label);

    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    // Reset sub-controllers
    _weHighlightController.reset();
    _weMoveController.reset();
    _weGlowController.reset();

    if (reduceMotion) {
      // Instant transitions for reduced-motion
      setState(() => _weCurrentStep = 1);
      _weHighlightController.value = 1.0;
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted || !_isShowingWorkedExample) return;
      setState(() => _weCurrentStep = 2);
      _weMoveController.value = 1.0;
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted || !_isShowingWorkedExample) return;
      setState(() => _weCurrentStep = 3);
      _weGlowController.value = 1.0;
    } else {
      // Step 1: Highlight the example image
      if (mounted) setState(() => _weCurrentStep = 1);
      await _weHighlightController.forward(from: 0);
      if (!mounted) return;
      // Small pause between steps
      await Future.delayed(const Duration(milliseconds: 250));
      // Step 2: Move the image toward the category
      if (mounted) setState(() => _weCurrentStep = 2);
      await _weMoveController.forward(from: 0);
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 200));
      // Step 3: Glow the destination + success effect
      if (mounted) setState(() => _weCurrentStep = 3);
      await _weGlowController.forward(from: 0);
    }

    if (!mounted || !_isShowingWorkedExample) return;
    _weButtonPulseController.repeat();
    setState(() {
      _weAnimationComplete = true;
      _weIsPlaying = false;
    });
  }

  void _playWorkedExampleNarration(String label) {
    if (_weNarrationFuture != null) return;
    final narration = TtsService().speak(
      'අපි උදාහරණයක් බලමු. මේ පින්තූරය $label කූඩයට දමමු.',
      folder: 'skill_1',
      waitUntilComplete: true,
    );
    _weNarrationFuture = narration;
    unawaited(
      narration.whenComplete(() {
        if (identical(_weNarrationFuture, narration)) {
          _weNarrationFuture = null;
        }
      }),
    );
  }

  /// Replays the demonstration without duplicate telemetry/callbacks.
  void _replayWorkedExample() {
    if (_weDebounceLock || _weIsPlaying) return;
    _weDebounceLock = true;
    _playWorkedExampleDemo().whenComplete(() {
      _weDebounceLock = false;
    });
  }

  /// Dismisses the worked-example popup and returns to the scored task.
  void _dismissWorkedExample() {
    if (_weIsPlaying) return; // Can't dismiss while playing
    _weNarrationFuture = null;
    unawaited(TtsService().stop());
    setState(() {
      _isShowingWorkedExample = false;
      _workedExampleObject = null;
      _workedExampleCategory = null;
      _weAnimationComplete = false;
      _weIsPlaying = false;
      _weCurrentStep = 0;
    });
    _workedExampleController.reset();
    _weHighlightController.reset();
    _weMoveController.reset();
    _weGlowController.reset();
    _weOverlayEntryController.reset();
    _weMascotBreathController.reset();
    _weButtonPulseController.reset();
    _weSparkleController.reset();
  }

  int get _totalObjects => _currentRound.objects.length;
  int get _sortedCount =>
      _totalObjects - (_objectQueue.length + _visibleObjects.length);

  void _onAcceptDrop(String object, String categoryKey) {
    setState(() {
      _hoveredCategory = null;
      _isDragging = false;
    });

    final correctCategory = _currentRound.objectToCategory[object];

    if (correctCategory == categoryKey) {
      // Correct!
      SoundUtils.playFeedback('audio/correct.mp3');

      setState(() {
        _visibleObjects.remove(object);
        _sortedObjects[categoryKey]!.add(object);
        _lastCorrectCategory = categoryKey;
        _hintedCategory = null;

        // Only refill when the shelf is completely empty, creating a "magical batch" effect
        if (_visibleObjects.isEmpty && _objectQueue.isNotEmpty) {
          _fillVisibleObjects();
        }
      });

      // Flash category glow
      _categoryGlowControllers[categoryKey]?.forward(from: 0).then((_) {
        _categoryGlowControllers[categoryKey]?.reverse();
      });

      // Update encouragement
      final rng = Random();
      _currentEncouragement =
          _encourageMessages[rng.nextInt(_encourageMessages.length)];

      // Check win
      if (_objectQueue.isEmpty && _visibleObjects.isEmpty) {
        _onRoundComplete();
      } else {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _lastCorrectCategory = null;
            });
          }
        });
      }
    } else {
      // Wrong!
      SoundUtils.playFeedback('audio/wrong.mp3');
      final wrapper = context.findAncestorStateOfType<TelemetryWrapperState>();
      final categories = _currentRound.categories.keys.toList();
      if (wrapper != null && correctCategory != null) {
        final itemId = _taskCoordinator.itemId;
        final selectedIndex = categories.indexOf(categoryKey);
        final correctIndex = categories.indexOf(correctCategory);
        unawaited(
          wrapper
              .requestSemanticScaffold(
                itemId: itemId,
                visibleOptionIds: List<String>.generate(
                  categories.length,
                  (index) => '${itemId}_DEST${index + 1}',
                ),
                selectedOptionIds: <String>[
                  '${itemId}_DEST${selectedIndex + 1}',
                ],
                correctOptionIds: <String>['${itemId}_DEST${correctIndex + 1}'],
                incorrectOptionIds: <String>[
                  '${itemId}_DEST${selectedIndex + 1}',
                ],
                supportedActions: <String>[
                  'HIGHLIGHT_DESTINATION',
                  if (_workedExampleFor(correctCategory, excluding: object) !=
                      null)
                    'SHOW_WORKED_EXAMPLE',
                  'REPLAY_INSTRUCTION',
                ],
                struggledTargetUnits: <String>[object],
                errorType: 'categorization_error',
              )
              .then((plan) async {
                if (!mounted || plan == null) return;
                final types = plan.commands
                    .map((command) => command.type)
                    .toSet();
                if (types.contains(ScaffoldActionType.replayInstruction)) {
                  _playInstruction();
                }
                if (types.contains(ScaffoldActionType.showWorkedExample)) {
                  await _showWorkedExample(
                    currentObject: object,
                    correctCategory: correctCategory,
                  );
                } else if (types.contains(
                  ScaffoldActionType.highlightOptions,
                )) {
                  setState(() => _hintedCategory = correctCategory);
                  _categoryGlowControllers[correctCategory]
                      ?.forward(from: 0)
                      .then(
                        (_) => _categoryGlowControllers[correctCategory]
                            ?.reverse(),
                      );
                }
              }),
        );
      }

      setState(() {
        _lastWrongObject = object;
        _lastWrongCategory = categoryKey;
      });
      _wrongShakeController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _lastWrongObject = null;
            _lastWrongCategory = null;
          });
        }
      });
    }
  }

  void _onRoundComplete() {
    setState(() {
      _roundComplete = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _nextRound();
    });
  }

  Future<void> _nextRound() async {
    final result = await context
        .findAncestorStateOfType<TelemetryWrapperState>()
        ?.completeAdaptiveRound(
          100,
          currentRoundIndex: _currentRoundIndex,
          itemId: _taskCoordinator.itemId,
        );
    if (!mounted) return;
    final transition = _taskCoordinator.applyResult(result);

    if (!transition.isComplete) {
      _roundTransitionController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentRoundIndex = transition.roundIndex;
          _roundComplete = false;
          _lastCorrectCategory = null;
          final rng = Random();
          _currentInstruction =
              _instructions[rng.nextInt(_instructions.length)];
        });
        ProgressService().saveActivityState(
          widget.activityNode.skillId,
          widget.activityNode.id,
          _currentRoundIndex,
        );
        ProgressService().saveActivityScore(
          widget.activityNode.skillId,
          widget.activityNode.id,
          ((_currentRoundIndex / _rounds.length) * 100).toInt(),
        );
        _initRoundState();
        _roundTransitionController.forward();
      });
    } else {
      // Activity complete!
      ProgressService().clearActivityState(
        widget.activityNode.skillId,
        widget.activityNode.id,
      );
      ProgressService().saveActivityScore(
        widget.activityNode.skillId,
        widget.activityNode.id,
        100,
      );
      setState(() {
        _activityComplete = true;
        final sId = widget.activityNode?.skillId ?? '';
        final aId = widget.activityNode?.id ?? '';
        if (sId.isNotEmpty && aId.isNotEmpty) {
          ProgressService().saveActivityScore(sId, aId, 100);
          ProgressService().clearActivityState(sId, aId);
        }
      });
      _celebrationController.forward();
    }
  }

  void _finishActivity() {
    final wrapper = context.findAncestorStateOfType<TelemetryWrapperState>();
    if (wrapper != null) {
      wrapper.completeActivity(context);
    } else {
      Navigator.pop(context);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_rounds.isEmpty) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // ── Beautiful Blurred Garden Background ──
          const Positioned.fill(
            child: PatternBackground(
              imagePath: 'assets/images/backgrounds/act3_bg.jpg',
            ),
          ),

          // ── Main Content ──
          SafeArea(
            child: FadeTransition(
              opacity: _roundFadeAnimation,
              child: Column(
                children: [
                  _buildTopHUD(),
                  const SizedBox(height: 8),
                  _buildInstructionCard(),
                  const SizedBox(height: 12),
                  _buildShelfArea(),
                  const SizedBox(height: 16),
                  _buildCategoryZones(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Celebration Overlay ──
          if (_isShowingWorkedExample) _buildWorkedExampleOverlay(),
          if (_activityComplete) _buildCelebrationOverlay(),
        ],
      ),
    );
  }

  // ── Top HUD ──
  Widget _buildTopHUD() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90D9).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF4A90D9),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.activityNode.title,
                      style: AppTypography.heading(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3E3E3E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildProgressDots(),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_currentRoundIndex + 1}/${_rounds.length}',
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A90D9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_rounds.length * 2 - 1, (index) {
        if (index % 2 == 1) {
          final lineIndex = index ~/ 2;
          final isCompleted = lineIndex < _currentRoundIndex;
          return Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isCompleted
                  ? const Color(0xFF6DBE6D)
                  : const Color(0xFFE0E0E0),
            ),
          );
        } else {
          final dotIndex = index ~/ 2;
          final isCompleted = dotIndex < _currentRoundIndex;
          final isCurrent = dotIndex == _currentRoundIndex;
          return Container(
            width: isCurrent ? 14 : 10,
            height: isCurrent ? 14 : 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? const Color(0xFF6DBE6D)
                  : isCurrent
                  ? const Color(0xFFF9C623)
                  : const Color(0xFFE0E0E0),
              border: isCurrent
                  ? Border.all(
                      color: const Color(0xFFF9C623).withValues(alpha: 0.3),
                      width: 2,
                    )
                  : null,
            ),
          );
        }
      }),
    );
  }

  // ── Instruction Card ──
  Widget _buildInstructionCard() {
    return GestureDetector(
      onTap: () {
        context
            .findAncestorStateOfType<TelemetryWrapperState>()
            ?.logAudioReplay();
        _playInstruction();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.warmAmber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.warmAmber, width: 3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _currentInstruction,
                style: AppTypography.sinhala(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            ScaleTransition(
              scale: _speakerBounceAnimation,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warmAmber,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warmAmber.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalProgressBar() {
    final progress = _totalObjects == 0 ? 0.0 : _sortedCount / _totalObjects;
    return Container(
      height: 12,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Track
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
          ),
          // Filled glowing bar
          LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                height: 12,
                width: (progress * constraints.maxWidth).clamp(
                  0.0,
                  constraints.maxWidth,
                ),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF6DBE6D),
                      Color(0xFF86D286),
                    ], // Beautiful soft green
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6DBE6D).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Shelf Area (Conveyor Belt of Draggables) ──
  Widget _buildShelfArea() {
    return Expanded(
      flex: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _roundComplete
                  ? const SizedBox() // Disappear entirely when round is complete
                  : Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildHorizontalProgressBar(),
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 16.0,
                                  ),
                                  child: Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    alignment: WrapAlignment.center,
                                    children: _visibleObjects
                                        .map(
                                          (obj) => _buildDraggableObject(obj),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableObject(String object) {
    final entryController = _entranceControllers[object];
    final floatController = _floatControllers[object];

    if (entryController == null || floatController == null)
      return const SizedBox();

    bool isWrong = _lastWrongObject == object;

    return AnimatedBuilder(
      animation: Listenable.merge([
        entryController,
        floatController,
        _wrongShakeController,
      ]),
      builder: (context, child) {
        final scale = CurvedAnimation(
          parent: entryController,
          curve: Curves.elasticOut,
        ).value;
        final floatY = sin(floatController.value * 2 * pi) * 4.0;

        double shakeX = 0;
        if (isWrong && _wrongShakeController.isAnimating) {
          shakeX = _wrongShakeAnimation.value;
        }

        return Transform.translate(
          offset: Offset(shakeX, floatY),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Draggable<String>(
        data: object,
        maxSimultaneousDrags: 1,
        onDragStarted: () {
          setState(() {
            _isDragging = true;
          });
        },
        onDragEnd: (_) {
          setState(() {
            _isDragging = false;
            _hoveredCategory = null;
          });
        },
        feedback: _buildDragFeedback(object),
        childWhenDragging: _buildDragGhost(),
        child: _buildObjectCard(object, isWrong: isWrong),
      ),
    );
  }

  Widget _buildObjectCard(String object, {bool isWrong = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWrong
            ? const Color(0xFFE87C6D).withValues(alpha: 0.15)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (isWrong)
            BoxShadow(
              color: const Color(0xFFE87C6D).withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: 2,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: isWrong
              ? const Color(0xFFE87C6D)
              : const Color(0xFF4A90D9).withValues(alpha: 0.15),
          width: isWrong ? 4.0 : 2.0,
        ),
      ),
      child: Image.asset(
        'assets/images/activity_icons/$object',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildDragFeedback(String object) {
    return Material(
      color: Colors.transparent,
      child: Transform.rotate(
        angle: 0.1, // Slight rotation while dragging
        child: Container(
          width: 140,
          height: 140,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFF9C623), // Gold highlight when dragging
              width: 3,
            ),
          ),
          child: Image.asset(
            'assets/images/activity_icons/$object',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildDragGhost() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 2,
          style: BorderStyle.none,
        ),
      ),
      child: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.4),
              width: 2,
            ), // A dashed effect would be better, but standard border works
          ),
        ),
      ),
    );
  }

  // ── Category Zones (Drag Targets) ──
  Widget _buildCategoryZones({List<String>? customCategories, int flex = 4}) {
    final categories =
        customCategories ?? _currentRound.categories.keys.toList();
    if (categories.isEmpty) return const SizedBox();
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: categories.map((cat) => _buildCategoryTarget(cat)).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryTarget(String categoryKey) {
    final accentColor = _categoryColors[categoryKey] ?? const Color(0xFF4A90D9);
    final iconPath = _currentRound.categoryIcons[categoryKey]!;
    final label = _currentRound.categoryLabels[categoryKey] ?? categoryKey;
    final totalRequired = _currentRound.categories[categoryKey]!.length;
    final currentSorted = _sortedObjects[categoryKey]!.length;
    final isComplete = currentSorted == totalRequired;

    return Expanded(
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          setState(() {
            _hoveredCategory = categoryKey;
          });
          return true;
        },
        onLeave: (_) {
          setState(() {
            if (_hoveredCategory == categoryKey) _hoveredCategory = null;
          });
        },
        onAcceptWithDetails: (details) {
          _onAcceptDrop(details.data, categoryKey);
        },
        builder: (context, candidateData, rejectedData) {
          final isHovered = _hoveredCategory == categoryKey;
          final isLastCorrect = _lastCorrectCategory == categoryKey;
          final isHinted = _hintedCategory == categoryKey;

          return AnimatedBuilder(
            animation: _categoryGlowControllers[categoryKey]!,
            builder: (context, child) {
              final glowValue = _categoryGlowControllers[categoryKey]!.value;
              double scale = 1.0;
              if (isHovered) scale = 1.05;
              if (isLastCorrect) scale = 1.0 + (sin(glowValue * pi) * 0.1);

              return Transform.scale(
                scale: scale,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Content
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 3D Basket & Pinned Icon
                          Expanded(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glow behind basket if hovered
                                if (isHovered || isLastCorrect || isHinted)
                                  Container(
                                    width: 80,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (isHinted
                                                      ? AppColors.warmAmber
                                                      : accentColor)
                                                  .withValues(alpha: 0.6),
                                          blurRadius: 24,
                                          spreadRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),

                                // The New Custom 3D UI Basket
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: _buildCustomBasket(
                                    categoryKey,
                                    accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Correct Drop Particles (Simple Star burst)
                      if (isLastCorrect)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _StarBurstPainter(glowValue),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCustomBasket(String categoryKey, Color accentColor) {
    IconData categoryIcon;
    Color secondaryColor;
    String decorationPattern = '';

    switch (categoryKey) {
      case 'animals':
        categoryIcon = Icons.pets_rounded;
        secondaryColor = const Color(0xFF5A9E64);
        decorationPattern = '🐾';
        break;
      case 'fruits':
        categoryIcon = Icons.apple_rounded;
        secondaryColor = const Color(0xFFC76D44);
        decorationPattern = '🍎';
        break;
      case 'vehicles':
        categoryIcon = Icons.directions_car_rounded;
        secondaryColor = const Color(0xFF3B7BBF);
        decorationPattern = '🚗';
        break;
      case 'everyday':
        categoryIcon = Icons.lightbulb_rounded;
        secondaryColor = const Color(0xFFD9A000);
        decorationPattern = '⭐';
        break;
      case 'flowers':
        categoryIcon = Icons.local_florist_rounded;
        secondaryColor = const Color(0xFFD81B60);
        decorationPattern = '🌸';
        break;
      default:
        categoryIcon = Icons.category_rounded;
        secondaryColor = accentColor;
        decorationPattern = '✨';
    }

    bool isCorrect = _lastCorrectCategory == categoryKey;
    bool isWrong = _lastWrongCategory == categoryKey;
    bool isHinted = _hintedCategory == categoryKey;

    return SizedBox(
      width: 180,
      height: 150,
      child: AnimatedScale(
        scale: isCorrect ? 1.1 : (isWrong ? 0.9 : 1.0),
        duration: const Duration(milliseconds: 300),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            border: Border.all(
              color: isCorrect
                  ? Colors.green
                  : isWrong
                  ? Colors.red
                  : isHinted
                  ? AppColors.warmAmber
                  : Colors.transparent,
              width: (isCorrect || isWrong || isHinted) ? 4 : 0,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Image.asset(
            'assets/images/activity_icons/basket/basket_$categoryKey.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // ── Mascot Area ──
  Widget _buildMascotArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Image.asset(
            _currentMascot,
            width: 60,
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const SizedBox(width: 60, height: 60),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12), // Lift bubble slightly
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90D9).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF4A90D9).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                _roundComplete
                    ? 'හොඳයි! 🎉'
                    : _lastCorrectCategory != null
                    ? 'සුපිරියි! ✨'
                    : _currentEncouragement,
                style: AppTypography.sinhala(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5D7A9E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Celebration Overlay ──
  Widget _buildCelebrationOverlay() {
    return Positioned.fill(
      child: SharedCelebrationPopup(
        studentData: widget.studentData,
        activityTitle: widget.activityNode.title,
        scaleAnimation: _celebrationScale,
        onFinish: _finishActivity,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WORKED EXAMPLE — Premium Full-Screen Overlay
  // ═══════════════════════════════════════════════════════════

  Widget _buildWorkedExampleOverlay() {
    final object = _workedExampleObject;
    final category = _workedExampleCategory;
    if (object == null || category == null) return const SizedBox.shrink();
    final label = _currentRound.categoryLabels[category] ?? category;
    final accent = _categoryColors[category] ?? AppColors.calmBlue;
    final screenW = MediaQuery.sizeOf(context).width;
    final contentWidth = min(screenW - 40, 380.0);

    return Positioned.fill(
      child: BlockSemantics(
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _weOverlayEntryController,
            curve: Curves.easeOut,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.4),
                    radius: 1.4,
                    colors: <Color>[
                      accent.withValues(alpha: 0.06),
                      const Color(0xFF1A2438).withValues(alpha: 0.72),
                    ],
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    // ── Floating sparkle particles ──
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _weSparkleController,
                        builder: (context, _) => CustomPaint(
                          painter: _WeSparklesPainter(
                            _weSparkleController.value,
                            accent,
                          ),
                        ),
                      ),
                    ),
                    // ── Main content ──
                    SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: SizedBox(
                            width: contentWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                // ── Living mascot ──
                                _buildWeMascot(accent),
                                // ── Speech bubble heading ──
                                _buildWeSpeechBubble(accent),
                                const SizedBox(height: 14),
                                // ── Theater stage card ──
                                _buildWeTheaterCard(
                                  object,
                                  category,
                                  label,
                                  accent,
                                ),
                                const SizedBox(height: 24),
                                // ── Primary action button ──
                                _buildWeDismissButton(accent),
                                const SizedBox(height: 10),
                                // ── Replay secondary control ──
                                _buildWeReplayButton(accent),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Living Mascot with breathing animation ──
  Widget _buildWeMascot(Color accent) {
    return AnimatedBuilder(
      animation: _weMascotBreathController,
      builder: (context, child) {
        final breathScale =
            1.0 + (sin(_weMascotBreathController.value * 2 * pi) * 0.03);
        return Transform.scale(scale: breathScale, child: child);
      },
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Colors.white, accent.withValues(alpha: 0.12)],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: accent.withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 4,
            ),
            const BoxShadow(
              color: Color(0x22FFFFFF),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              _currentMascot,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.auto_awesome_rounded, color: accent, size: 40),
            ),
          ),
        ),
      ),
    );
  }

  // ── Speech Bubble with tail ──
  Widget _buildWeSpeechBubble(Color accent) {
    return Column(
      children: <Widget>[
        // Tail pointing up toward mascot
        CustomPaint(size: const Size(20, 10), painter: _BubbleTailPainter()),
        // Bubble body
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accent.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              Text(
                'අපි උදාහරණයක් බලමු!',
                textAlign: TextAlign.center,
                style: AppTypography.sinhala(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'පින්තූරය හරි තැනට යන හැටි බලන්න.',
                textAlign: TextAlign.center,
                style: AppTypography.sinhala(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Theater-style demonstration card ──
  Widget _buildWeTheaterCard(
    String object,
    String category,
    String label,
    Color accent,
  ) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 44,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // ── Gradient accent strip (theater curtain top) ──
          Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  accent.withValues(alpha: 0.25),
                  accent,
                  accent.withValues(alpha: 0.25),
                ],
              ),
            ),
          ),
          // ── Demo stage area ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: _buildDemoStage(object, category, label, accent),
          ),
          // ── Step indicator dots ──
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildWeStepDots(accent),
          ),
        ],
      ),
    );
  }

  // ── 3-Step Demo Stage (Premium Animation) ──
  Widget _buildDemoStage(
    String object,
    String category,
    String label,
    Color accent,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _weHighlightController,
        _weMoveController,
        _weGlowController,
      ]),
      builder: (context, _) {
        final highlightV = Curves.easeOutCubic.transform(
          _weHighlightController.value,
        );
        final moveV = Curves.easeInOutCubic.transform(_weMoveController.value);
        final glowV = Curves.easeOut.transform(_weGlowController.value);

        // Arc-based movement: slight horizontal sway during vertical travel
        final arcX = sin(moveV * pi) * 20.0;

        return SizedBox(
          height: 255,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: <Widget>[
              // ── Destination basket/category zone ──
              Positioned(
                bottom: 0,
                child: Container(
                  width: 175,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      accent.withValues(alpha: 0.08),
                      AppColors.gentleGreen.withValues(alpha: 0.12),
                      glowV,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Color.lerp(
                        accent.withValues(alpha: 0.25),
                        AppColors.gentleGreen,
                        glowV,
                      )!,
                      width: 2.5 + (glowV * 1.5),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color.lerp(
                          accent.withValues(alpha: 0.06),
                          AppColors.gentleGreen.withValues(alpha: 0.35),
                          glowV,
                        )!,
                        blurRadius: 12 + (glowV * 22),
                        spreadRadius: glowV * 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/activity_icons/basket/basket_$category.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.inventory_2_rounded,
                          color: accent,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          label,
                          style: AppTypography.sinhala(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Demonstration image (arc path movement) ──
              Positioned(
                top: 5 + (moveV * 100),
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(arcX, 0),
                    child: Transform.scale(
                      scale: (0.80 + (highlightV * 0.20)) - (moveV * 0.22),
                      child: Container(
                        width: 108,
                        height: 108,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Color.lerp(
                              accent.withValues(alpha: 0.2),
                              accent,
                              highlightV,
                            )!,
                            width: 2.5 + (highlightV * 1.5),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: accent.withValues(
                                alpha: 0.06 + (highlightV * 0.22),
                              ),
                              blurRadius: 10 + (highlightV * 20),
                              spreadRadius: highlightV * 6,
                              offset: const Offset(0, 4),
                            ),
                            // Warm inner glow when highlighted
                            if (highlightV > 0.3)
                              BoxShadow(
                                color: AppColors.warmAmberLight.withValues(
                                  alpha: highlightV * 0.15,
                                ),
                                blurRadius: 30,
                                spreadRadius: 8,
                              ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/activity_icons/$object',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Success effect: green check badge with bounce ──
              if (glowV > 0.05)
                Positioned(
                  right: 50,
                  bottom: 78,
                  child: Opacity(
                    opacity: glowV,
                    child: Transform.scale(
                      scale: Curves.elasticOut.transform(
                        (glowV * 1.3).clamp(0.0, 1.0),
                      ),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0xFF7DCE7D),
                              Color(0xFF4A9E50),
                            ],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.gentleGreen.withValues(
                                alpha: 0.45,
                              ),
                              blurRadius: 16,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Success particle burst ──
              if (glowV > 0.1)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _WeSuccessBurstPainter(glowV, accent),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Step indicator dots ──
  Widget _buildWeStepDots(Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final stepNum = i + 1;
        final isActive = _weCurrentStep >= stepNum;
        final isCurrent = _weCurrentStep == stepNum && _weIsPlaying;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: isActive ? accent : Colors.grey.withValues(alpha: 0.18),
            boxShadow: isCurrent
                ? <BoxShadow>[
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // ── Premium pulsing dismiss button ──
  Widget _buildWeDismissButton(Color accent) {
    final bool enabled = _weAnimationComplete && !_weIsPlaying;
    return AnimatedBuilder(
      animation: _weButtonPulseController,
      builder: (context, child) {
        final pulseScale = enabled
            ? 1.0 + (sin(_weButtonPulseController.value * 2 * pi) * 0.018)
            : 1.0;
        return Transform.scale(scale: pulseScale, child: child);
      },
      child: Semantics(
        button: true,
        enabled: enabled,
        label: 'දැන් මම උත්සාහ කරන්නම්',
        child: GestureDetector(
          onTap: enabled ? _dismissWorkedExample : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 58, minWidth: 240),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF6EC074), Color(0xFF4A9E50)],
                    )
                  : null,
              color: enabled ? null : const Color(0xFFD5DAE2),
              borderRadius: BorderRadius.circular(29),
              boxShadow: enabled
                  ? <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF4A9E50).withValues(alpha: 0.40),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                      BoxShadow(
                        color: const Color(0xFF6EC074).withValues(alpha: 0.18),
                        blurRadius: 36,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.rocket_launch_rounded,
                  color: enabled ? Colors.white : const Color(0xFFA0A8B4),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'දැන් මම උත්සාහ කරන්නම්',
                      style: AppTypography.sinhala(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: enabled ? Colors.white : const Color(0xFFA0A8B4),
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

  // ── Secondary replay control ──
  Widget _buildWeReplayButton(Color accent) {
    final bool canReplay = _weAnimationComplete && !_weIsPlaying;
    return Semantics(
      button: true,
      enabled: canReplay,
      label: 'උදාහරණය නැවත බලන්න',
      child: GestureDetector(
        onTap: canReplay ? _replayWorkedExample : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: canReplay
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.replay_rounded,
                size: 18,
                color: canReplay
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.30),
              ),
              const SizedBox(width: 6),
              Text(
                'නැවත බලන්න',
                style: AppTypography.sinhala(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: canReplay
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Simple Custom Painter for Star Burst Effect ──
class _StarBurstPainter extends CustomPainter {
  final double progress;

  _StarBurstPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    final maxRadius = size.width * 0.8;

    final int numStars = 6;
    for (int i = 0; i < numStars; i++) {
      final angle = (i * 2 * pi / numStars) + (progress * pi / 4);
      final currentRadius = progress * maxRadius;

      final starCenter = Offset(
        center.dx + cos(angle) * currentRadius,
        center.dy + sin(angle) * currentRadius,
      );

      final alpha = ((1 - progress) * 255).toInt().clamp(0, 255);
      paint.color = const Color(0xFFF9C623).withAlpha(alpha);

      _drawStar(canvas, paint, starCenter, 8 * (1 - progress + 0.5));
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    final int points = 5;
    final double innerRadius = size / 2.5;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? size : innerRadius;
      final angle = (i * pi / points) - pi / 2;
      final point = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ── Floating sparkle particles for the worked-example overlay ──
class _WeSparklesPainter extends CustomPainter {
  final double phase;
  final Color accent;
  _WeSparklesPainter(this.phase, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 14; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final sparkleSize = 1.5 + rng.nextDouble() * 3.5;

      final x = baseX + sin((phase * speed + i) * 2 * pi) * 18;
      final y = (baseY - (phase * 60 * speed)) % size.height;

      final alpha = (0.12 + sin((phase * 2 + i * 0.4) * 2 * pi) * 0.10).clamp(
        0.02,
        0.25,
      );

      final isGold = i % 3 == 0;
      paint.color = (isGold ? const Color(0xFFF9C623) : accent).withValues(
        alpha: alpha,
      );

      canvas.drawCircle(Offset(x, y), sparkleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeSparklesPainter old) => old.phase != phase;
}

// ── Speech bubble tail painter ──
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Success burst particles (gentle star-like expanding dots) ──
class _WeSuccessBurstPainter extends CustomPainter {
  final double progress;
  final Color accent;
  _WeSuccessBurstPainter(this.progress, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.05) return;
    final center = Offset(size.width * 0.65, size.height * 0.72);
    final paint = Paint()..style = PaintingStyle.fill;
    final maxRadius = size.width * 0.35;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * pi / 8) + (progress * pi / 6);
      final dist = progress * maxRadius * (0.5 + (i % 3) * 0.2);
      final pos = Offset(
        center.dx + cos(angle) * dist,
        center.dy + sin(angle) * dist,
      );
      final fade = ((1.0 - progress) * 0.6).clamp(0.0, 0.5);
      final dotSize = 3.0 * (1.0 - progress * 0.5);

      final isGold = i % 2 == 0;
      paint.color = (isGold ? const Color(0xFFF9C623) : AppColors.gentleGreen)
          .withValues(alpha: fade);
      canvas.drawCircle(pos, dotSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeSuccessBurstPainter old) =>
      old.progress != progress;
}

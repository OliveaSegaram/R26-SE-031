import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../models/curriculum_models.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../theme/app_theme.dart';
import 'logic/sorting_generator.dart';
import 'models/sorting_round.dart';
import 'widgets/pattern_background.dart';

// ──────────────────────────────────────────────────────────────
// Activity 03: Sorting Adventure (Premium Drag & Drop Redesign)
// A polished drag-and-drop sorting game for Grade 1 children
// ──────────────────────────────────────────────────────────────

class VisualAct3SortingAdventure extends StatefulWidget {
  final ActivityNode activityNode;

  const VisualAct3SortingAdventure({Key? key, required this.activityNode})
      : super(key: key);

  @override
  _VisualAct3SortingAdventureState createState() =>
      _VisualAct3SortingAdventureState();
}

class _VisualAct3SortingAdventureState extends State<VisualAct3SortingAdventure>
    with TickerProviderStateMixin {
  // ── Game state ──
  int _currentRoundIndex = 0;
  late List<SortingRound> _rounds;
  
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
  String? _lastWrongObject;

  // ── Audio ──
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ── Category accent colors ──
  static const Map<String, Color> _categoryColors = {
    'animals': Color(0xFF82C98B),   // Gentle green
    'fruits': Color(0xFFE8A07C),    // Warm coral
    'vehicles': Color(0xFF7CB8E8),  // Calm blue
    'everyday': Color(0xFFF9C623),  // Yellow
    'nature': Color(0xFFDDA0DD),    // Plum
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

  // ── Mascot ──
  static const List<String> _mascots = [
    'assets/images/mascots/solo_blue.png',
    'assets/images/mascots/solo_green.png',
    'assets/images/mascots/solo_orange.png',
    'assets/images/mascots/solo_pink.png',
    'assets/images/mascots/solo_yellow.png',
    'assets/images/mascots/solo_teal.png',
  ];
  late String _currentMascot;

  // ── Encouragement messages ──
  static const List<String> _encourageMessages = [
    'හොඳට බලන්න! 👀',
    'ඔයාට පුළුවන්! 💪',
    'නියමයි, දිගටම! ⭐',
    'මනාව! 🌟',
    'සුපිරියි! 🎉',
  ];
  late String _currentEncouragement;

  // ── Sinhala instructions ──
  static const List<String> _instructions = [
    'පින්තූර නිවැරදි තැනට අදින්න!',
    'කණ්ඩායම් වලට වෙන් කරමු!',
    'නිවැරදි කොටුවට දමන්න!',
  ];
  late String _currentInstruction;

  @override
  void initState() {
    super.initState();
    _rounds = SortingGenerator.generateRounds();
    
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
      CurvedAnimation(
          parent: _celebrationController, curve: Curves.elasticOut),
    );

    // Round transition fade
    _roundTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _roundFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _roundTransitionController, curve: Curves.easeOut),
    );

    // Wrong answer shake
    _wrongShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wrongShakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _wrongShakeController,
      curve: Curves.easeInOut,
    ));

    _initRoundState();
    _roundTransitionController.forward();
  }

  void _initRoundState() {
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
    for (var c in _floatControllers.values) { c.dispose(); }
    for (var c in _entranceControllers.values) { c.dispose(); }
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
    _celebrationController.dispose();
    _roundTransitionController.dispose();
    _wrongShakeController.dispose();
    for (var c in _floatControllers.values) { c.dispose(); }
    for (var c in _entranceControllers.values) { c.dispose(); }
    for (var c in _categoryGlowControllers.values) { c.dispose(); }
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Game logic ──

  SortingRound get _currentRound => _rounds[_currentRoundIndex];
  int get _totalObjects => _currentRound.objects.length;
  int get _sortedCount => _totalObjects - (_objectQueue.length + _visibleObjects.length);

  void _onAcceptDrop(String object, String categoryKey) {
    setState(() {
      _hoveredCategory = null;
      _isDragging = false;
    });

    final correctCategory = _currentRound.objectToCategory[object];
    
    if (correctCategory == categoryKey) {
      // Correct!
      _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      setState(() {
        _visibleObjects.remove(object);
        _sortedObjects[categoryKey]!.add(object);
        _lastCorrectCategory = categoryKey;
        
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
            setState(() { _lastCorrectCategory = null; });
          }
        });
      }
    } else {
      // Wrong!
      _audioPlayer.play(AssetSource('audio/wrong.mp3'));
      context.findAncestorStateOfType<TelemetryWrapperState>()?.recordMisclick();
      
      setState(() {
        _lastWrongObject = object;
      });
      _wrongShakeController.forward(from: 0).then((_) {
        if (mounted) setState(() { _lastWrongObject = null; });
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

  void _nextRound() {
    context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(100);

    if (_currentRoundIndex < _rounds.length - 1) {
      _roundTransitionController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentRoundIndex++;
          _roundComplete = false;
          _lastCorrectCategory = null;
          final rng = Random();
          _currentInstruction = _instructions[rng.nextInt(_instructions.length)];
        });
        _initRoundState();
        _roundTransitionController.forward();
      });
    } else {
      // Activity complete!
      setState(() {
        _activityComplete = true;
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
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // ── Beautiful Blurred Garden Background ──
          const Positioned.fill(
            child: PatternBackground(
                imagePath: 'assets/images/backgrounds/act3_bg.jpg'),
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
                  _buildMascotArea(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Celebration Overlay ──
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
            color: const Color(0xFF4A90D9).withOpacity(0.12),
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
              child: const Icon(Icons.arrow_back_rounded,
                  color: Color(0xFF4A90D9), size: 24),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90D9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '03',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
              color: isCompleted ? const Color(0xFF6DBE6D) : const Color(0xFFE0E0E0),
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
                  ? Border.all(color: const Color(0xFFF9C623).withOpacity(0.3), width: 2)
                  : null,
            ),
          );
        }
      }),
    );
  }

  // ── Instruction Card ──
  Widget _buildInstructionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _roundComplete ? const Color(0xFF6DBE6D).withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _roundComplete 
            ? const Color(0xFF6DBE6D).withOpacity(0.3)
            : const Color(0xFF4A90D9).withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: _roundComplete ? [] : [
          BoxShadow(
            color: const Color(0xFF4A90D9).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_roundComplete) 
            const Icon(Icons.check_circle_rounded, color: Color(0xFF6DBE6D), size: 28)
          else
            const Icon(Icons.touch_app_rounded, color: Color(0xFF4A90D9), size: 28),
          const SizedBox(width: 10),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _roundComplete ? 'නියමයි! සියල්ල වර්ග කළා! 🎉' : _currentInstruction,
                style: AppTypography.sinhala(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _roundComplete ? const Color(0xFF4E9E4E) : const Color(0xFF3E3E3E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalProgressBar() {
    final progress = _totalObjects == 0 ? 0.0 : _sortedCount / _totalObjects;
    return Container(
      width: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final safeMaxHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0 ? constraints.maxHeight : 100.0;
          final barHeight = safeMaxHeight * 0.8; // Exactly 80% of available height
          return SizedBox(
            height: barHeight,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Track
                Container(
                  width: 16,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
                // Filled glowing bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  width: 16,
                  height: (progress * barHeight).clamp(0.0, double.infinity),
                  decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF38B2AC), Color(0xFF4FD1C5)], // Beautiful teal
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4FD1C5).withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
            _buildVerticalProgressBar(),
            const SizedBox(width: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                ),
                child: _roundComplete 
          ? const Center(
              child: Icon(Icons.celebration_rounded, size: 80, color: Color(0xFFF9C623)),
            )
          : Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: _visibleObjects.map((obj) => _buildDraggableObject(obj)).toList(),
                  ),
                ),
              ),
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
    
    if (entryController == null || floatController == null) return const SizedBox();

    return AnimatedBuilder(
      animation: Listenable.merge([entryController, floatController, _wrongShakeController]),
      builder: (context, child) {
        final scale = CurvedAnimation(parent: entryController, curve: Curves.elasticOut).value;
        final floatY = sin(floatController.value * 2 * pi) * 4.0;
        
        double shakeX = 0;
        if (_lastWrongObject == object && _wrongShakeController.isAnimating) {
          shakeX = _wrongShakeAnimation.value;
        }

        return Transform.translate(
          offset: Offset(shakeX, floatY),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Draggable<String>(
        data: object,
        maxSimultaneousDrags: 1,
        onDragStarted: () {
          setState(() { _isDragging = true; });
        },
        onDragEnd: (_) {
          setState(() { _isDragging = false; _hoveredCategory = null; });
        },
        feedback: _buildDragFeedback(object),
        childWhenDragging: _buildDragGhost(),
        child: _buildObjectCard(object),
      ),
    );
  }

  Widget _buildObjectCard(String object) {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF4A90D9).withOpacity(0.15),
          width: 2,
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
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
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
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
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
              color: Colors.grey.withOpacity(0.4),
              width: 2,
            ), // A dashed effect would be better, but standard border works
          ),
        ),
      ),
    );
  }

  // ── Category Zones (Drag Targets) ──
  Widget _buildCategoryZones() {
    final categories = _currentRound.categories.keys.toList();
    
    return Expanded(
      flex: 4,
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
          setState(() { _hoveredCategory = categoryKey; });
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
                                if (isHovered || isLastCorrect)
                                  Container(
                                    width: 80,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(alpha: 0.6),
                                          blurRadius: 24,
                                          spreadRadius: 8,
                                        )
                                      ],
                                    ),
                                  ),
                                
                                // The 3D Basket Image
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Image.asset(
                                    'assets/images/activity_icons/basket_$categoryKey.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Pill Label below the basket
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentColor, // The vibrant category color
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    label,
                                    style: AppTypography.sinhala(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (isComplete) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                  ]
                                ],
                              ),
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
      case 'nature':
        categoryIcon = Icons.eco_rounded;
        secondaryColor = const Color(0xFF9E639E);
        decorationPattern = '🌿';
        break;
      default:
        categoryIcon = Icons.category_rounded;
        secondaryColor = accentColor;
        decorationPattern = '✨';
    }

    return SizedBox(
      width: 120,
      height: 100,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Back inside of bucket
          Positioned(
            top: 8,
            child: Container(
              width: 100,
              height: 35,
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
          // Deep shadow hole
          Positioned(
            top: 14,
            child: Container(
              width: 86,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
          // Main Body
          Positioned(
            bottom: 5, // Lifted slightly to make room for emblem overflow
            child: Container(
              width: 110,
              height: 75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor,
                    secondaryColor,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: secondaryColor.withOpacity(0.5),
                    offset: const Offset(0, 6),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle Pattern
                  Positioned(
                    left: 15,
                    top: 15,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Text(decorationPattern, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
                    ),
                  ),
                  Positioned(
                    right: 15,
                    bottom: 25,
                    child: Transform.rotate(
                      angle: 0.2,
                      child: Text(decorationPattern, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.5))),
                    ),
                  ),
                  // Shine highlight on left edge
                  Positioned(
                    left: 12,
                    top: 8,
                    bottom: 12,
                    child: Container(
                      width: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Front Rim
          Positioned(
            top: 8,
            child: Container(
              width: 110,
              height: 35,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
                borderRadius: BorderRadius.circular(55),
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
                  width: 3,
                ),
              ),
            ),
          ),
          // Front Emblem (Category Indicator)
          Positioned(
            bottom: -5,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  categoryIcon,
                  color: secondaryColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
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
                    color: const Color(0xFF4A90D9).withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF4A90D9).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                _roundComplete
                    ? 'නියමයි! 🎉'
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
    return AnimatedBuilder(
      animation: _celebrationScale,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.4 * _celebrationScale.value),
          child: Center(
            child: Transform.scale(
              scale: _celebrationScale.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90D9).withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStar(36),
                const SizedBox(width: 10),
                _buildStar(52),
                const SizedBox(width: 10),
                _buildStar(36),
              ],
            ),
            const SizedBox(height: 20),
            Image.asset(
              _currentMascot,
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const SizedBox(width: 80, height: 80),
            ),
            const SizedBox(height: 16),
            Text(
              'නියමයි! 🎉',
              style: AppTypography.sinhala(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3E3E3E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ඔබ සියල්ල වර්ග කළා!',
              style: AppTypography.sinhala(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _finishActivity,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6DBE6D), Color(0xFF4E9E4E)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6DBE6D).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'ඉදිරියට යමු →',
                  style: AppTypography.sinhala(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStar(double size) {
    return Icon(
      Icons.star_rounded,
      size: size,
      color: const Color(0xFFF9C623),
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

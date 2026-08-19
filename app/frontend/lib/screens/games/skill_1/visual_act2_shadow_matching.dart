import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../widgets/app_loading_indicator.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../models/curriculum_models.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../theme/app_theme.dart';
import 'logic/shadow_generator.dart';
import 'models/shadow_round.dart';
import 'widgets/pattern_background.dart';

// ──────────────────────────────────────────────────────────────
// Activity 04: Shadow Matching Adventure
// A polished shadow matching game for Grade 1 children
// ──────────────────────────────────────────────────────────────

class VisualAct2ShadowMatching extends StatefulWidget {
  final ActivityNode activityNode;

  const VisualAct2ShadowMatching({Key? key, required this.activityNode})
      : super(key: key);

  @override
  _VisualAct2ShadowMatchingState createState() =>
      _VisualAct2ShadowMatchingState();
}

class _VisualAct2ShadowMatchingState extends State<VisualAct2ShadowMatching>
    with TickerProviderStateMixin {
  // ── Game state ──
  int _currentRoundIndex = 0;
  late List<ShadowRound> _rounds;

  List<String> _shuffledTrayObjects = [];
  List<String> _shuffledShadows = [];
  Set<String> _matchedObjects = {};

  bool _roundComplete = false;
  bool _activityComplete = false;

  bool _isDragging = false;
  String? _lastWrongObject;

  // ── Audio ──
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ── Animation controllers ──
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScale;
  late AnimationController _roundTransitionController;
  late Animation<double> _roundFadeAnimation;

  // Individual float controllers for objects
  final Map<String, AnimationController> _floatControllers = {};
  
  final ScrollController _trayScrollController = ScrollController();
  
  // Drop feedback controllers
  final Map<String, AnimationController> _shadowGlowControllers = {};
  late AnimationController _wrongShakeController;
  late Animation<double> _wrongShakeAnimation;

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

  // ── Sinhala instructions ──
  static const List<String> _instructions = [
    'සෙවනැල්ලට ගැලපෙන පින්තූරය තෝරන්න!',
    'සෙවනැල්ලට ගැලපෙන රූපය අදින්න!',
    'හරිම සෙවනැල්ල හොයමු!',
  ];
  late String _currentInstruction;

  // ── Encouragement messages ──
  static const List<String> _encourageMessages = [
    'හොඳට බලන්න! 👀',
    'ඔයාට පුළුවන්! 💪',
    'නියමයි, දිගටම! ⭐',
    'මනාව! 🌟',
    'සුපිරියි! 🎉',
  ];
  late String _currentEncouragement;

  @override
  void initState() {
    super.initState();
    _rounds = ShadowGenerator.generateRounds();
    
    final rng = Random();
    _currentMascot = _mascots[rng.nextInt(_mascots.length)];
    _currentInstruction = _instructions[rng.nextInt(_instructions.length)];
    _currentEncouragement = _encourageMessages[rng.nextInt(_encourageMessages.length)];

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
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _wrongShakeController,
      curve: Curves.easeInOut,
    ));

    _initRoundState();
    _roundTransitionController.forward();
  }

  void _initRoundState() {
    _matchedObjects.clear();
    final rng = Random();
    
    // Ensure randomization changes the order for tray and shadows independently
    _shuffledTrayObjects = List.from(_currentRound.targetAssets)..shuffle(rng);
    _shuffledShadows = List.from(_currentRound.targetAssets)..shuffle(rng);
    
    for (var shadow in _shuffledShadows) {
      _shadowGlowControllers[shadow] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
    }
    
    // Clear old controllers
    for (var c in _floatControllers.values) { c.dispose(); }
    _floatControllers.clear();

    // Create float controllers for objects in tray
    for (int i = 0; i < _shuffledTrayObjects.length; i++) {
      final obj = _shuffledTrayObjects[i];
      _floatControllers[obj] = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1800 + rng.nextInt(600)),
      )..repeat(reverse: true);
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playScrollHint();
    });
  }

  void _playScrollHint() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted || !_trayScrollController.hasClients) return;
    
    if (_trayScrollController.position.maxScrollExtent > 0) {
      await _trayScrollController.animateTo(
        min(150.0, _trayScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
      
      if (!mounted || !_trayScrollController.hasClients) return;
      await Future.delayed(const Duration(milliseconds: 300));
      
      await _trayScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _roundTransitionController.dispose();
    _wrongShakeController.dispose();
    _trayScrollController.dispose();
    for (var c in _floatControllers.values) { c.dispose(); }
    for (var c in _shadowGlowControllers.values) { c.dispose(); }
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Game logic ──

  ShadowRound get _currentRound => _rounds[_currentRoundIndex];

  void _onAcceptDrop(String object, String targetShadow) {
    setState(() {
      _isDragging = false;
    });

    if (object == targetShadow) {
      // Correct!
      _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      setState(() {
        _matchedObjects.add(object);
      });
      
      // Flash category glow
      _shadowGlowControllers[targetShadow]?.forward(from: 0).then((_) {
        _shadowGlowControllers[targetShadow]?.reverse();
      });
          
      // Check win
      if (_matchedObjects.length == _currentRound.targetAssets.length) {
        _onRoundComplete();
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
          final rng = Random();
          _currentInstruction = _instructions[rng.nextInt(_instructions.length)];
          _currentEncouragement = _encourageMessages[rng.nextInt(_encourageMessages.length)];
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
          body: Center(child: AppLoadingIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // ── Beautiful Blurred Background ──
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
                  _buildShadowBoard(),
                  const SizedBox(height: 16),
                  _buildObjectTray(),
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
                        '04',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.activityNode.title.isEmpty ? 'Shadow Matching' : widget.activityNode.title,
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
        mainAxisSize: MainAxisSize.max,
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
                _roundComplete ? 'නියමයි! සියල්ල ගැලපුවා! 🎉' : _currentInstruction,
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

  // ── Shadow Board ──
  Widget _buildShadowBoard() {
    return Expanded(
      flex: 3,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalItems = _shuffledShadows.length;
            if (totalItems == 0) return const SizedBox();
            
            double maxCardSize = 0.0;
            const spacing = 24.0;
            
            for (int cols = 1; cols <= totalItems; cols++) {
              int rows = (totalItems / cols).ceil();
              double cardWidth = (constraints.maxWidth - 32 - (cols - 1) * spacing) / cols;
              double cardHeight = (constraints.maxHeight - 32 - (rows - 1) * spacing) / rows;
              double currentCardSize = min(cardWidth, cardHeight);
              if (currentCardSize > maxCardSize) {
                maxCardSize = currentCardSize;
              }
            }
            
            if (maxCardSize > 120.0) maxCardSize = 120.0;

            return Center(
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: _shuffledShadows.map((shadow) {
                  return _buildShadowTarget(shadow, maxCardSize);
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShadowTarget(String object, double size) {
    final isMatched = _matchedObjects.contains(object);
    final glowController = _shadowGlowControllers[object];

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        return !isMatched;
      },
      onAcceptWithDetails: (details) => _onAcceptDrop(details.data, object),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return AnimatedBuilder(
          animation: glowController ?? const AlwaysStoppedAnimation(0),
          builder: (context, child) {
            final glowValue = glowController?.value ?? 0.0;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: isMatched ? Colors.transparent : Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isHovered 
                      ? const Color(0xFFF9C623) 
                      : (glowValue > 0 ? const Color(0xFF6DBE6D) : Colors.white.withOpacity(0.8)),
                  width: isHovered ? 4 : 2,
                ),
                boxShadow: isHovered || glowValue > 0
                    ? [
                        BoxShadow(
                          color: (glowValue > 0 ? const Color(0xFF6DBE6D) : const Color(0xFFF9C623)).withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ]
                    : [
                        if (!isMatched)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            spreadRadius: -2,
                            offset: const Offset(0, 4),
                          )
                      ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      if (isMatched)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Image.asset(
                                'assets/images/activity_icons/$object',
                                fit: BoxFit.contain,
                              ),
                            );
                          },
                        )
                      else
                        ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF1E2A38), // Deep shadow color
                            BlendMode.srcATop,
                          ),
                          child: Opacity(
                            opacity: 0.85,
                            child: Image.asset(
                              'assets/images/activity_icons/$object',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        
                      if (glowValue > 0)
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
              ),
            );
          },
        );
      },
    );
  }

  // ── Object Tray ──
  Widget _buildObjectTray() {
    return Container(
      height: 150, // Slightly taller for premium look
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90D9).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: _roundComplete
          ? const Center(
              child: Icon(Icons.celebration_rounded, size: 80, color: Color(0xFFF9C623)),
            )
          : SingleChildScrollView(
              controller: _trayScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _shuffledTrayObjects.map((object) {
                  return _buildDraggableObject(object);
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildDraggableObject(String object) {
    final isMatched = _matchedObjects.contains(object);
    final floatController = _floatControllers[object];
    
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutBack,
      child: isMatched
          ? const SizedBox(width: 0, height: 120) // Shrinks to 0 width and disappears smoothly
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: AnimatedBuilder(
                animation: Listenable.merge([floatController ?? const AlwaysStoppedAnimation(0), _wrongShakeController]),
                builder: (context, child) {
                  final floatY = floatController != null ? sin(floatController.value * 2 * pi) * 5.0 : 0.0;
                  
                  double shakeX = 0;
                  if (_lastWrongObject == object && _wrongShakeController.isAnimating) {
                    shakeX = _wrongShakeAnimation.value;
                  }

                  return Transform.translate(
                    offset: Offset(shakeX, floatY),
                    child: child,
                  );
                },
                child: Draggable<String>(
                  data: object,
                  maxSimultaneousDrags: 1,
                  onDragStarted: () {
                    _audioPlayer.play(AssetSource('audio/pop.mp3'));
                    setState(() { _isDragging = true; });
                  },
                  onDragEnd: (_) {
                    setState(() { _isDragging = false; });
                  },
                  feedback: _buildDragFeedback(object),
                  childWhenDragging: _buildDragGhost(),
                  child: _buildObjectCard(object),
                ),
              ),
            ),
    );
  }

  Widget _buildObjectCard(String object) {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(28), // Rounded squircle
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90D9).withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 3,
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
        angle: 0.1, 
        child: Transform.scale(
          scale: 1.1,
          child: Container(
            width: 140,
            height: 140,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90D9).withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                  offset: const Offset(0, 12),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFF9C623),
                width: 4,
              ),
            ),
            child: Image.asset(
              'assets/images/activity_icons/$object',
              fit: BoxFit.contain,
            ),
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
        borderRadius: BorderRadius.circular(28),
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
            ),
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
              margin: const EdgeInsets.only(bottom: 12),
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
              'ඔබ සියලුම පින්තූර ගැලපුවා!',
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

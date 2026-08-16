import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../models/curriculum_models.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../theme/app_theme.dart';
import 'widgets/pattern_background.dart';

// ──────────────────────────────────────────────────────────────
// Activity 05: Memory Adventure
// A world-class visual memory game for Grade 1 children
// Magic Hat lifting mechanics and premium UI
// ──────────────────────────────────────────────────────────────

enum MemoryPhase { preparing, memorizing, hiding, recall, success }

class MemoryRound {
  final int itemCount;
  final int memoryDurationMs;
  final List<String> assets;
  final String targetAsset;

  MemoryRound({
    required this.itemCount,
    required this.memoryDurationMs,
    required this.assets,
    required this.targetAsset,
  });
}

class VisualAct5MemoryHats extends StatefulWidget {
  final ActivityNode activityNode;
  const VisualAct5MemoryHats({Key? key, required this.activityNode}) : super(key: key);

  @override
  _VisualAct5MemoryAdventureState createState() => _VisualAct5MemoryAdventureState();
}

class _VisualAct5MemoryAdventureState extends State<VisualAct5MemoryHats> with TickerProviderStateMixin {
  // ── Game state ──
  int _currentRoundIndex = 0;
  late List<MemoryRound> _rounds;
  bool _activityComplete = false;

  MemoryPhase _currentPhase = MemoryPhase.preparing;

  // ── Mistakes & Hints ──
  int _mistakesInRound = 0;
  int _lastMistakeIndex = -1;

  // ── Audio ──
  final AudioPlayer _audioPlayer = AudioPlayer();

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

  // ── Animation controllers ──
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScale;
  late AnimationController _roundTransitionController;
  late Animation<double> _roundFadeAnimation;

  late AnimationController _wrongShakeController;
  late Animation<double> _wrongShakeAnimation;
  late AnimationController _hintGlowController;

  // Track hat drop controllers for each item in the current round
  List<AnimationController> _hatDropControllers = [];

  // ── Available Assets ──
  static const List<String> _poolAssets = [
    'animals/bird.png', 'animals/butterfly.png', 'animals/cat.png', 'animals/cow.png',
    'animals/dog.png', 'animals/elephant.png', 'animals/fish.png', 'animals/frog.png',
    'animals/rabbit.png', 'animals/turtle.png',
    'fruits_food/apple.png', 'fruits_food/banana.png', 'fruits_food/grapes.png',
    'fruits_food/ice_cream.png', 'fruits_food/mango.png', 'fruits_food/orange.png', 'fruits_food/watermelon.png',
    'nature/flower.png', 'nature/leaf.png', 'nature/sun.png',
  ];

  static const List<String> _instructions = [
    'හොඳින් මතක තබා ගන්න!', // Look carefully!
    'රූප තිබෙන තැන් මතක තියාගන්න!', // Remember where the pictures are!
  ];
  late String _currentInstruction;

  @override
  void initState() {
    super.initState();
    _rounds = _generateRounds();
    
    final rng = Random();
    _currentInstruction = _instructions[rng.nextInt(_instructions.length)];
    _currentMascot = _mascots[rng.nextInt(_mascots.length)];
    _currentEncouragement = _encourageMessages[rng.nextInt(_encourageMessages.length)];

    // Celebration
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
      CurvedAnimation(parent: _roundTransitionController, curve: Curves.easeOut),
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

    // Hint glow
    _hintGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _initRoundState();
    _roundTransitionController.forward();
  }

  List<MemoryRound> _generateRounds() {
    // Progressive Difficulty Levels - Tailored for Grade 1
    final config = [
      {'count': 2, 'time': 6000}, // Very easy start
      {'count': 3, 'time': 5000}, // Mild increase
      {'count': 3, 'time': 4000}, // Same items, less time
      {'count': 4, 'time': 4000}, // Introduce 4 items
      {'count': 5, 'time': 4000}, // Max 5 items for this age group
    ];

    List<MemoryRound> rounds = [];
    final rng = Random();

    for (int i = 0; i < config.length; i++) {
      int count = config[i]['count']!;
      int time = config[i]['time']!;

      List<String> pool = List.from(_poolAssets)..shuffle(rng);
      List<String> roundAssets = pool.take(count).toList();
      String target = roundAssets[rng.nextInt(count)];

      rounds.add(MemoryRound(
        itemCount: count,
        memoryDurationMs: time,
        assets: roundAssets,
        targetAsset: target,
      ));
    }
    return rounds;
  }

  void _setupHatControllers() {
    for (var controller in _hatDropControllers) {
      controller.dispose();
    }
    _hatDropControllers = List.generate(
      _currentRound.itemCount,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _initRoundState() {
    _mistakesInRound = 0;
    _lastMistakeIndex = -1;
    _celebrationController.reset();
    _setupHatControllers();
    
    setState(() {
      _currentPhase = MemoryPhase.preparing;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMemorySequence();
    });
  }

  void _startMemorySequence() async {
    // Wait a brief moment before popping in objects
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    setState(() {
      _currentPhase = MemoryPhase.memorizing;
    });

    // Wait the memory duration
    await Future.delayed(Duration(milliseconds: _currentRound.memoryDurationMs));
    if (!mounted) return;

    setState(() {
      _currentPhase = MemoryPhase.hiding;
    });
    
    // Drop all hats down (value -> 1)
    List<Future> dropFutures = [];
    for (int i = 0; i < _hatDropControllers.length; i++) {
      dropFutures.add(
        Future.delayed(Duration(milliseconds: i * 80), () {
          if (mounted) _hatDropControllers[i].forward();
        })
      );
    }
    
    await Future.wait(dropFutures);
    if (!mounted) return;

    setState(() {
      _currentPhase = MemoryPhase.recall;
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _roundTransitionController.dispose();
    _wrongShakeController.dispose();
    _hintGlowController.dispose();
    for (var controller in _hatDropControllers) {
      controller.dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Game logic ──

  MemoryRound get _currentRound => _rounds[_currentRoundIndex];

  void _onHatTapped(int index) {
    if (_currentPhase != MemoryPhase.recall) return;

    String tappedAsset = _currentRound.assets[index];

    if (tappedAsset == _currentRound.targetAsset) {
      // Correct! Lift hat back up (reverse controller)
      _hatDropControllers[index].reverse();
      
      _audioPlayer.play(AssetSource('audio/correct.mp3'));
      final rng = Random();
      _currentEncouragement = _encourageMessages[rng.nextInt(_encourageMessages.length)];
      
      setState(() {
        _currentPhase = MemoryPhase.success;
      });
      _celebrationController.forward();

      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        _nextRound();
      });
    } else {
      // Wrong!
      _audioPlayer.play(AssetSource('audio/wrong.mp3'));
      context.findAncestorStateOfType<TelemetryWrapperState>()?.recordMisclick();
      
      // Briefly lift to show they got it wrong, then drop back
      _hatDropControllers[index].reverse().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _currentPhase == MemoryPhase.recall) {
             _hatDropControllers[index].forward();
          }
        });
      });

      setState(() {
        _lastMistakeIndex = index;
        _mistakesInRound++;
      });
      _wrongShakeController.forward(from: 0).then((_) {
        if (mounted) setState(() { _lastMistakeIndex = -1; });
      });

      if (_mistakesInRound >= 2) {
        _showHint();
      }
    }
  }

  void _showHint() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _hintGlowController.forward().then((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _hintGlowController.reverse();
      });
    });
  }

  void _nextRound() {
    context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(100);

    if (_currentRoundIndex < _rounds.length - 1) {
      _roundTransitionController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentRoundIndex++;
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // ── Beautiful Blurred Background ──
          const Positioned.fill(
            child: PatternBackground(imagePath: 'assets/images/backgrounds/act2_bg.jpg'),
          ),

          // ── Main Content ──
          SafeArea(
            child: FadeTransition(
              opacity: _roundFadeAnimation,
              child: Column(
                children: [
                  _buildTopHUD(),
                  const SizedBox(height: 12),
                  _buildInstructionCard(),
                  const SizedBox(height: 16),
                  _buildGameArea(),
                  const SizedBox(height: 12),
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
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4A90D9), size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90D9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '05',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.activityNode.title.isEmpty ? 'මතක අභියෝගය' : widget.activityNode.title,
                        style: AppTypography.heading(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3E3E3E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(_rounds.length * 2 - 1, (index) {
        if (index % 2 == 1) {
          final lineIndex = index ~/ 2;
          final isCompleted = lineIndex < _currentRoundIndex;
          return Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isCompleted ? const Color(0xFF6DBE6D) : const Color(0xFFE0E0E0),
              ),
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
    final bool isRecall = _currentPhase == MemoryPhase.recall || _currentPhase == MemoryPhase.success;
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: 0.0,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isRecall
          ? Container(
              key: const ValueKey('recall'),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4A90D9).withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90D9).withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4A90D9).withOpacity(0.3), width: 2),
                    ),
                    child: Image.asset('assets/images/activity_icons/${_currentRound.targetAsset}'),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'මේ රූපය තිබුණේ කොහෙද?',
                        style: AppTypography.sinhala(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3E3E3E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              key: const ValueKey('memorize'),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility_rounded, color: Color(0xFF4A90D9), size: 28),
                  const SizedBox(width: 10),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _currentInstruction,
                        style: AppTypography.sinhala(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3E3E3E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Main Game Area (Wrap Layout for Hats) ──
  Widget _buildGameArea() {
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: List.generate(_currentRound.itemCount, (index) {
                final asset = _currentRound.assets[index];
                return _buildHatWidget(index, asset);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHatWidget(int index, String asset) {
    bool isTarget = (asset == _currentRound.targetAsset);
    final dropController = _hatDropControllers[index];

    // Shake effect for wrong tap
    double shakeX = 0;
    if (_lastMistakeIndex == index && _wrongShakeController.isAnimating) {
      shakeX = _wrongShakeAnimation.value;
    }

    // Hint glow
    double hintOpacity = 0.0;
    if (isTarget && _mistakesInRound >= 2 && _hintGlowController.isAnimating) {
      hintOpacity = _hintGlowController.value * 0.6;
    }

    // Determine size based on screen width and item count
    double screenWidth = MediaQuery.of(context).size.width;
    int itemsPerRow = _currentRound.itemCount <= 4 ? 2 : 3;
    double cardWidth = (screenWidth - 32 - (16 * (itemsPerRow + 1))) / itemsPerRow;
    // Limit max size
    cardWidth = cardWidth.clamp(80.0, 140.0);
    double cardHeight = cardWidth * 1.2;

    return AnimatedBuilder(
      animation: Listenable.merge([
        dropController,
        _wrongShakeController,
        _hintGlowController,
        _celebrationController,
      ]),
      builder: (context, child) {
        // Drop value: 0.0 = Hat is high up (hidden / lifted). 1.0 = Hat is down (covering)
        // We use an elastic curve to make it springy
        final curve = dropController.isAnimating && dropController.status == AnimationStatus.forward
            ? Curves.bounceOut // Dropping down
            : Curves.easeOutBack; // Lifting up
            
        final dropCurve = CurvedAnimation(parent: dropController, curve: curve).value;
        
        final hatOffsetY = (1.0 - dropCurve) * -300.0; // Starts way above, moves to 0
        final hatOpacity = dropCurve.clamp(0.0, 1.0); // Fades in as it drops

        double scale = 1.0;
        if (_currentPhase == MemoryPhase.success && isTarget) {
          scale = 1.0 + (_celebrationScale.value * 0.2);
        }

        return Transform.translate(
          offset: Offset(shakeX, 0),
          child: Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: () => _onHatTapped(index),
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // The hidden object (always there, just covered by hat when hat is down)
                    _buildHiddenObject(asset, cardWidth, cardHeight, isTarget),
                    
                    // The Magic Hat dropping over it
                    Transform.translate(
                      offset: Offset(0, hatOffsetY),
                      child: Opacity(
                        opacity: hatOpacity,
                        child: _buildMagicHat(cardWidth, cardHeight, hintOpacity),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHiddenObject(String asset, double width, double height, bool isTarget) {
    return Container(
      width: width * 0.8,
      height: width * 0.8,
      margin: EdgeInsets.only(bottom: height * 0.1), // Offset so hat covers it nicely
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90D9).withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
        border: Border.all(color: const Color(0xFF4A90D9).withOpacity(0.3), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset('assets/images/activity_icons/$asset'),
          ),
          if (_currentPhase == MemoryPhase.success && isTarget)
            Opacity(
              opacity: 1.0 - _celebrationScale.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: _celebrationScale.value * 2.5,
                child: const Icon(Icons.star_rounded, color: Color(0xFFF9C623), size: 60),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMagicHat(double width, double height, double hintOpacity) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Brim (Back part)
          Positioned(
            bottom: height * 0.05 + 5,
            child: Container(
              width: width * 0.9,
              height: height * 0.15,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1D28),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          
          // Hat Body
          Positioned(
            bottom: height * 0.12,
            child: Container(
              width: width * 0.65,
              height: height * 0.75,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF534F75), Color(0xFF28263D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(3, 5),
                  )
                ],
                border: Border.all(
                  color: hintOpacity > 0 ? const Color(0xFFF9C623) : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          ),
          
          // Ribbon
          Positioned(
            bottom: height * 0.12,
            child: Container(
              width: width * 0.65,
              height: height * 0.12,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF4B4B), Color(0xFFC62828)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ]
              ),
            ),
          ),

          // Star on Ribbon
          Positioned(
            bottom: height * 0.12 + 2,
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFFFFD700),
              size: 28,
            ),
          ),
          
          // Brim (Front)
          Positioned(
            bottom: height * 0.05,
            child: Container(
              width: width * 0.9,
              height: height * 0.15,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3E3C56), Color(0xFF1E1D28)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(100), // Ellipse shape
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                  if (hintOpacity > 0)
                    BoxShadow(
                      color: const Color(0xFFF9C623).withOpacity(hintOpacity),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                ],
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
                _activityComplete
                    ? 'නියමයි! 🎉'
                    : _currentPhase == MemoryPhase.success
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
      child: FadeTransition(
        opacity: _celebrationScale,
        child: Container(
          color: Colors.white.withOpacity(0.9),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _celebrationScale,
                  child: const Icon(Icons.star_rounded, color: Color(0xFFF9C623), size: 120),
                ),
                const SizedBox(height: 24),
                Text(
                  'නියමයි! ඔයා හරිම දක්ෂයි!',
                  style: AppTypography.sinhala(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3E3E3E),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _finishActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90D9),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'ඉදිරියට යමු',
                    style: AppTypography.sinhala(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

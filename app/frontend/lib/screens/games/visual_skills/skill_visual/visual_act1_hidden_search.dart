import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../models/curriculum_models.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../theme/app_theme.dart';

// ──────────────────────────────────────────────────────────────
// Activity 01: Picture Hunt
// A polished, card-grid visual-search game for Grade 1 children
// ──────────────────────────────────────────────────────────────

class VisualAct1HiddenSearch extends StatefulWidget {
  final ActivityNode activityNode;

  const VisualAct1HiddenSearch({Key? key, required this.activityNode})
      : super(key: key);

  @override
  _VisualAct1HiddenSearchState createState() =>
      _VisualAct1HiddenSearchState();
}

class _VisualAct1HiddenSearchState extends State<VisualAct1HiddenSearch>
    with TickerProviderStateMixin {
  // ── Game state ──
  int _currentRoundIndex = 0;
  late List<Map<String, dynamic>> _rounds;
  List<_GameItem> _items = [];
  int _foundCount = 0;
  int _targetCount = 0;
  bool _roundComplete = false;
  bool _activityComplete = false;
  bool _showHint = false;

  // ── Audio ──
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ── Animation controllers ──
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScale;
  late AnimationController _roundTransitionController;
  late Animation<double> _roundFadeAnimation;
  late AnimationController _foundCountBounceController;
  late Animation<double> _foundCountBounce;
  Timer? _hintTimer;

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

  @override
  void initState() {
    super.initState();
    _rounds = List<Map<String, dynamic>>.from(widget.activityNode.rounds);

    // Pick a random mascot for this session
    final rng = Random();
    _currentMascot = _mascots[rng.nextInt(_mascots.length)];
    _currentEncouragement = _encourageMessages[rng.nextInt(_encourageMessages.length)];

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _celebrationScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    _roundTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _roundFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _roundTransitionController, curve: Curves.easeOut),
    );

    _foundCountBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _foundCountBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _foundCountBounceController,
      curve: Curves.easeInOut,
    ));

    _initRound();
    _roundTransitionController.forward();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _celebrationController.dispose();
    _roundTransitionController.dispose();
    _foundCountBounceController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Round initialization ──
  void _initRound() {
    if (_currentRoundIndex >= _rounds.length) return;
    final round = _rounds[_currentRoundIndex];

    final List<String> targets = List<String>.from(round['targets'] ?? []);
    final int tCount = round['target_count'] ?? 1;
    final List<String> distractors =
        List<String>.from(round['distractors'] ?? []);
    final int dCount = round['distractor_count'] ?? 2;

    _targetCount = tCount;
    _foundCount = 0;
    _roundComplete = false;
    _showHint = false;
    _items = [];

    // Update encouragement
    final rng = Random();
    _currentEncouragement = _encourageMessages[rng.nextInt(_encourageMessages.length)];

    // Add target items
    for (int i = 0; i < tCount; i++) {
      final path = targets[i % targets.length];
      _items.add(_GameItem(
        path: 'assets/images/activity_icons/$path',
        isTarget: true,
      ));
    }
    // Add distractor items
    for (int i = 0; i < dCount; i++) {
      final path = distractors[i % distractors.length];
      _items.add(_GameItem(
        path: 'assets/images/activity_icons/$path',
        isTarget: false,
      ));
    }
    _items.shuffle(Random());

    _resetHintTimer();
    setState(() {});
  }

  void _resetHintTimer() {
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_roundComplete) {
        setState(() {
          _showHint = true;
        });
      }
    });
  }

  // ── Tap handlers ──
  void _onItemTapped(_GameItem item) {
    if (_roundComplete || item.isFound) return;

    _resetHintTimer();
    setState(() {
      _showHint = false;
    });

    if (item.isTarget) {
      _audioPlayer.play(AssetSource('audio/correct.mp3'));
      setState(() {
        item.isFound = true;
        _foundCount++;
      });
      _foundCountBounceController.forward(from: 0);

      if (_foundCount == _targetCount) {
        _roundComplete = true;
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          _nextRound();
        });
      }
    } else {
      _audioPlayer.play(AssetSource('audio/wrong.mp3'));
      setState(() {
        item.showWrongFeedback = true;
      });
      context
          .findAncestorStateOfType<TelemetryWrapperState>()
          ?.recordMisclick();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          item.showWrongFeedback = false;
        });
      });
    }
  }

  void _nextRound() {
    if (!mounted) return;
    context
        .findAncestorStateOfType<TelemetryWrapperState>()
        ?.completeRound(100);

    if (_currentRoundIndex < _rounds.length - 1) {
      _roundTransitionController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentRoundIndex++;
          _initRound();
        });
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
    final wrapper =
        context.findAncestorStateOfType<TelemetryWrapperState>();
    if (wrapper != null) {
      wrapper.completeActivity(context);
    } else {
      Navigator.pop(context);
    }
  }

  // ── Card Grid ──
  Widget _buildCardGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalItems = _items.length;
          if (totalItems == 0) return const SizedBox();
          
          double maxCardSize = 0.0;
          
          const spacing = 12.0;
          
          // Find the optimal number of columns that maximizes the card size
          // while fitting all items in the available space (no scrolling).
          for (int cols = 1; cols <= totalItems; cols++) {
            int rows = (totalItems / cols).ceil();
            
            double cardWidth = (constraints.maxWidth - (cols - 1) * spacing) / cols;
            double cardHeight = (constraints.maxHeight - (rows - 1) * spacing) / rows;
            
            double currentCardSize = min(cardWidth, cardHeight);
            
            if (currentCardSize > maxCardSize) {
              maxCardSize = currentCardSize;
            }
          }
          
          // Cap the maximum size so cards don't get comically large if there are only 2 items
          if (maxCardSize > 120.0) {
            maxCardSize = 120.0;
          }
          
          return Center(
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              children: List.generate(totalItems, (index) {
                return SizedBox(
                  width: maxCardSize,
                  height: maxCardSize,
                  child: _PictureCard(
                    key: ValueKey('${_currentRoundIndex}_${_items[index].path}_$index'),
                    item: _items[index],
                    onTap: () => _onItemTapped(_items[index]),
                    showHint: _showHint && _items[index].isTarget && !_items[index].isFound,
                    animationDelay: index * 0.06,
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    if (_rounds.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final round = _rounds[_currentRoundIndex];
    final List<String> targets = List<String>.from(round['targets'] ?? []);
    final String targetPath = targets.isNotEmpty
        ? 'assets/images/activity_icons/${targets[0]}'
        : '';
    final String instruction =
        round['instruction']?.toString() ?? 'පින්තූරය සොයන්න!';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F4FF), // Very light blue-white
              Color(0xFFE8F0FE), // Soft sky blue
              Color(0xFFFFF8E7), // Warm cream at bottom
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative Background Elements ──
            _buildDecoBackground(),

            // ── Main Content ──
            SafeArea(
              child: Column(
                children: [
                  _buildTopHUD(),
                  const SizedBox(height: 8),
                  _buildInstructionCard(instruction, targetPath),
                  const SizedBox(height: 6),
                  _buildFoundCounter(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FadeTransition(
                      opacity: _roundFadeAnimation,
                      child: _buildCardGrid(),
                    ),
                  ),
                  _buildMascotArea(),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── Celebration Overlay ──
            if (_activityComplete) _buildCelebrationOverlay(),
          ],
        ),
      ),
    );
  }

  // ── Decorative background ──
  Widget _buildDecoBackground() {
    return Stack(
      children: [
        // Soft floating circles for a playful feel
        Positioned(
          top: -30,
          right: -20,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A90D9).withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          top: 200,
          left: -40,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6DBE6D).withOpacity(0.06),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -30,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8A54B).withOpacity(0.07),
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          left: 30,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE87C6D).withOpacity(0.05),
            ),
          ),
        ),
        // Small decorative dots
        Positioned(
          top: 320,
          right: 40,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF9C623).withOpacity(0.3),
            ),
          ),
        ),
        Positioned(
          top: 450,
          left: 20,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A90D9).withOpacity(0.2),
            ),
          ),
        ),
      ],
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
          // Back button
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

          // Center: Title & Progress
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
                      child: Text(
                        '0${widget.activityNode.rounds.indexOf(_rounds[0]) + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Picture Hunt',
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

          // Right: Round counter
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

  // ── Progress Dots ──
  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_rounds.length * 2 - 1, (index) {
        if (index % 2 == 1) {
          // Line segment
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
          // Dot
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
  Widget _buildInstructionCard(String instruction, String targetPath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4A90D9).withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
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
          // Target image preview (large)
          if (targetPath.isNotEmpty)
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF4A90D9).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Image.asset(
                targetPath,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.image_outlined,
                  color: Color(0xFF4A90D9),
                  size: 32,
                ),
              ),
            ),
          if (targetPath.isNotEmpty) const SizedBox(width: 14),
          // Instruction text
          Flexible(
            child: Text(
              instruction,
              style: AppTypography.sinhala(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3E3E3E),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── Found Counter ──
  Widget _buildFoundCounter() {
    return AnimatedBuilder(
      animation: _foundCountBounce,
      builder: (context, child) {
        return Transform.scale(
          scale: _foundCountBounceController.isAnimating
              ? _foundCountBounce.value
              : 1.0,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _foundCount == _targetCount
              ? const Color(0xFF6DBE6D).withOpacity(0.15)
              : const Color(0xFFF9C623).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _foundCount == _targetCount
                ? const Color(0xFF6DBE6D).withOpacity(0.3)
                : const Color(0xFFF9C623).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _foundCount == _targetCount
                  ? Icons.check_circle_rounded
                  : Icons.search_rounded,
              color: _foundCount == _targetCount
                  ? const Color(0xFF6DBE6D)
                  : const Color(0xFFE8A54B),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '$_foundCount / $_targetCount සොයා ගත්තා',
              style: AppTypography.sinhala(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _foundCount == _targetCount
                    ? const Color(0xFF4E9E4E)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ── Mascot Area ──
  Widget _buildMascotArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Mascot image
          Image.asset(
            _currentMascot,
            width: 50,
            height: 50,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const SizedBox(width: 50, height: 50),
          ),
          const SizedBox(width: 10),
          // Speech bubble
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _roundComplete
                    ? 'නියමයි! 🎉'
                    : _currentEncouragement,
                style: AppTypography.sinhala(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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
            // Stars row
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
            // Mascot
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
              'ඔබ සියල්ල සොයාගත්තා!',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
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

// ═══════════════════════════════════════════════════════════════
// _GameItem — Data model for each object on the game screen
// ═══════════════════════════════════════════════════════════════
class _GameItem {
  final String path;
  final bool isTarget;
  bool isFound = false;
  bool showWrongFeedback = false;

  _GameItem({
    required this.path,
    required this.isTarget,
  });
}

// ═══════════════════════════════════════════════════════════════
// _PictureCard — A tappable card in the grid with animations
// ═══════════════════════════════════════════════════════════════
class _PictureCard extends StatefulWidget {
  final _GameItem item;
  final VoidCallback onTap;
  final bool showHint;
  final double animationDelay;

  const _PictureCard({
    Key? key,
    required this.item,
    required this.onTap,
    this.showHint = false,
    this.animationDelay = 0,
  }) : super(key: key);

  @override
  _PictureCardState createState() => _PictureCardState();
}

class _PictureCardState extends State<_PictureCard>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryScale;
  late Animation<double> _entryOpacity;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  late AnimationController _hintController;
  late Animation<double> _hintAnimation;

  late AnimationController _tapController;
  late Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();

    // Pop-in entry
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );
    _entryOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
    );
    Future.delayed(
      Duration(milliseconds: (widget.animationDelay * 1000).toInt()),
      () {
        if (mounted) _entryController.forward();
      },
    );

    // Shake for wrong
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: -2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -2, end: 0), weight: 1),
    ]).animate(_shakeController);

    // Hint subtle pulse
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _hintAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );

    // Tap scale
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_PictureCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.showWrongFeedback && !oldWidget.item.showWrongFeedback) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shakeController.dispose();
    _hintController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _tapController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _tapController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _tapController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _entryScale,
        _entryOpacity,
        _shakeAnimation,
        _hintAnimation,
        _tapScale,
      ]),
      builder: (context, child) {
        final entryScale = _entryController.isAnimating || _entryController.isCompleted
            ? _entryScale.value
            : 0.0;
        final shakeOffset =
            _shakeController.isAnimating ? _shakeAnimation.value : 0.0;
        final hintScale = widget.showHint ? _hintAnimation.value : 1.0;
        final tapScale = _tapController.isAnimating || _tapController.isCompleted
            ? _tapScale.value
            : 1.0;

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Opacity(
            opacity: _entryOpacity.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: entryScale * hintScale * tapScale,
              child: child,
            ),
          ),
        );
      },
      child: _buildCardContent(),
    );
  }

  Widget _buildCardContent() {
    final isFound = widget.item.isFound;
    final isWrong = widget.item.showWrongFeedback;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isFound
              ? const Color(0xFF6DBE6D).withOpacity(0.12)
              : isWrong
                  ? const Color(0xFFE87C6D).withOpacity(0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isFound
                ? const Color(0xFF6DBE6D).withOpacity(0.4)
                : isWrong
                    ? const Color(0xFFE87C6D).withOpacity(0.4)
                    : const Color(0xFFE5E7EB),
            width: isFound || isWrong ? 2.0 : 1.5,
          ),
          boxShadow: [
            if (!isFound)
              BoxShadow(
                color: isWrong
                    ? const Color(0xFFE87C6D).withOpacity(0.15)
                    : const Color(0xFF4A90D9).withOpacity(0.08),
                blurRadius: isWrong ? 12 : 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── The picture ──
            Padding(
              padding: const EdgeInsets.all(12),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isFound ? 0.45 : 1.0,
                child: Image.asset(
                  widget.item.path,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: Color(0xFFBBBBBB),
                    size: 40,
                  ),
                ),
              ),
            ),

            // ── Found checkmark overlay ──
            if (isFound)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF6DBE6D),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6DBE6D).withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),

            // ── Wrong X overlay (brief) ──
            if (isWrong)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE87C6D).withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

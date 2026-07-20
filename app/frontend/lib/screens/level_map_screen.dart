import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'games/visual_skills/activity1_spot_difference.dart';
import 'games/visual_skills/activity2_pattern.dart';
import 'games/visual_skills/activity3_missing_picture.dart';
import 'games/visual_skills/activity4_visual_memory.dart';
import 'games/visual_skills/activity5_category_sorting.dart';
import 'games/visual_skills/activity6_hidden_shape.dart';
import 'games/visual_skills/activity7_size_ordering.dart';
import 'games/visual_skills/activity8_position.dart';
import 'games/visual_skills/activity9_sequence.dart';
import 'games/visual_skills/activity10_shadow_match.dart';

/// Level Map Screen
/// Dyslexia-accessible: calm blue header, gentle green/warm amber nodes,
/// crème-tinted background, dark grey text.
class LevelMapScreen extends StatefulWidget {
  final Map<String, dynamic>? studentData;

  const LevelMapScreen({super.key, this.studentData});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _unlockController;
  final ScrollController _scrollController = ScrollController();

  late Animation<double> _pathAnim;
  late Animation<double> _nodeScaleAnim;
  late Animation<double> _avatarMoveAnim;

  // Current progress (0-indexed)
  int currentLevel = 0;
  bool _isNavigating = false;
  int _animatingFromLevel = -1; // Tracks the level we are animating from

  // Level data - 10 Visual Skills Tasks
  final List<Map<String, dynamic>> levels = [
    {'label': '1', 'title': 'spot diff', 'type': 'lesson', 'completed': false},
    {'label': '2', 'title': 'pattern', 'type': 'lesson', 'completed': false},
    {'label': '3', 'title': 'missing', 'type': 'lesson', 'completed': false},
    {'label': '4', 'title': 'memory', 'type': 'lesson', 'completed': false},
    {'label': '5', 'title': 'category', 'type': 'lesson', 'completed': false},
    {'label': '6', 'title': 'hidden', 'type': 'lesson', 'completed': false},
    {'label': '7', 'title': 'size', 'type': 'lesson', 'completed': false},
    {'label': '8', 'title': 'position', 'type': 'lesson', 'completed': false},
    {'label': '9', 'title': 'sequence', 'type': 'lesson', 'completed': false},
    {'label': '🏆', 'title': 'complete!', 'type': 'trophy', 'completed': false},
  ];

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the current active node
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    // Master unlock sequence controller
    _unlockController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // 0.0 -> 0.4: Draw the path
    _pathAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _unlockController, curve: const Interval(0.0, 0.4, curve: Curves.easeInOut)),
    );

    // 0.4 -> 0.7: Pop the node
    _nodeScaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 60),
    ]).animate(
      CurvedAnimation(parent: _unlockController, curve: const Interval(0.4, 0.7)),
    );

    // 0.6 -> 1.0: Glide the avatar (starts slightly before node finishes popping)
    _avatarMoveAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _unlockController, curve: const Interval(0.6, 1.0, curve: Curves.easeInOutCubic)),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
      _autoStartFirstLevel();
    });
  }

  void _autoStartFirstLevel() {
    if (currentLevel == 0 && !(levels[0]['completed'] as bool)) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && currentLevel == 0 && !_isNavigating) {
          _navigateToLevel(0);
        }
      });
    }
  }

  void _scrollToCurrentLevel() {
    final targetScroll = currentLevel * 120.0 - 200;
    if (_scrollController.hasClients && targetScroll > 0) {
      final clampedScroll = targetScroll.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        clampedScroll,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _unlockController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Zigzag X offset (Duolingo-style)
  double _getNodeX(int index, double screenWidth) {
    final centerX = screenWidth / 2;
    final amplitude = screenWidth * 0.2;
    return centerX + sin(index * 0.8) * amplitude;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // Scrollable Map Path
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: screenWidth,
              height: levels.length * 120.0 + 160,
              child: Stack(
                children: [
                  // Full Background Image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/backgrounds/map_bg.png',
                      fit: BoxFit.cover,
                      width: screenWidth,
                      height: levels.length * 120.0 + 160,
                    ),
                  ),

                  // Map content overlay
                  Padding(
                    padding: const EdgeInsets.only(top: 120, bottom: 40),
                    child: Stack(
                      children: [
                        // Animated Path
                        AnimatedBuilder(
                          animation: _unlockController,
                          builder: (context, child) {
                            return CustomPaint(
                              size: Size(screenWidth, levels.length * 120.0),
                              painter: PathPainter(
                                levels: levels,
                                currentLevel: currentLevel,
                                getNodeX: (i) => _getNodeX(i, screenWidth),
                                nodeSpacing: 120.0,
                                animatingFromLevel: _animatingFromLevel,
                                pathAnimationProgress: _pathAnim.value,
                              ),
                            );
                          }
                        ),

                        // Level nodes
                        ...List.generate(levels.length, (index) {
                          return _buildAnimatedNodePositioned(index, screenWidth);
                        }),

                        // Player character avatar
                        _buildAnimatedPlayerCharacter(screenWidth),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Header Bar
          _buildTopHeader(),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        14,
      ),
      decoration: BoxDecoration(
        color: AppColors.calmBlue,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.calmBlueDark.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title
          Expanded(
            child: Text(
              'හැඩ හඳුනාගැනීම',
              style: AppTypography.sinhala(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warmAmber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$currentLevel/${levels.length}',
                  style: AppTypography.button(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedNodePositioned(int index, double screenWidth) {
    return AnimatedBuilder(
      animation: _unlockController,
      builder: (context, child) {
        final level = levels[index];
        final nodeX = _getNodeX(index, screenWidth);
        final nodeY = index * 120.0 + 20;

        bool isCompleted = level['completed'] as bool;
        bool isCurrent = index == currentLevel;
        bool isLocked = index > currentLevel;
        double additionalScale = 1.0;

        // If this is the node currently being unlocked
        if (_animatingFromLevel != -1 && index == currentLevel) {
          if (_unlockController.value < 0.4) {
            // Keep it looking locked while path draws
            isCompleted = false;
            isCurrent = false;
            isLocked = true;
          } else {
            // Path reached it, trigger scale pop
            isCompleted = false;
            isCurrent = true;
            isLocked = false;
            additionalScale = _nodeScaleAnim.value;
          }
        }

        return Positioned(
          left: nodeX - 32,
          top: nodeY,
          child: Transform.scale(
            scale: additionalScale,
            child: _buildNodeCore(
              level: level,
              index: index,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isLocked: isLocked,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNodeCore({
    required Map<String, dynamic> level,
    required int index,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLocked,
  }) {
    final type = level['type'] as String;
    final label = level['label'] as String;

    Color bgColor;
    Color borderColor;
    Color contentColor = Colors.white;
    double size = 64;
    double borderWidth = 3;

    if (isCompleted) {
      bgColor = AppColors.gentleGreen;
      borderColor = AppColors.gentleGreenDark;
    } else if (isCurrent) {
      bgColor = AppColors.warmAmber;
      borderColor = AppColors.orangeDark;
    } else {
      bgColor = Colors.white;
      borderColor = AppColors.borderLight;
      contentColor = AppColors.textSecondary;
      borderWidth = 2;
    }

    if (type == 'star') {
      size = 56;
    } else if (type == 'trophy') {
      size = 72;
    }

    return GestureDetector(
      onTap: () {
        if (!isLocked && _animatingFromLevel == -1) {
          _navigateToLevel(index);
        }
      },
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulse animation for current level
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                // Only pulse if it's current and we aren't in the middle of unlocking it
                final scale = (isCurrent && _animatingFromLevel == -1)
                    ? 1.0 + (_pulseController.value * 0.08)
                    : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: borderWidth),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      offset: const Offset(0, 6),
                      blurRadius: 8,
                    ),
                    if (isCurrent)
                      BoxShadow(
                        color: AppColors.warmAmber.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                  ],
                ),
                child: Center(
                  child: isLocked
                      ? Icon(Icons.lock_rounded, color: AppColors.borderLight, size: 24)
                      : (isCompleted && type != 'trophy'
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
                          : Text(
                              type == 'trophy' ? '🏆' : label,
                              style: AppTypography.button(
                                fontSize: type == 'star' || type == 'trophy' ? 22 : 24,
                                color: contentColor,
                                fontWeight: FontWeight.w800,
                              ),
                            )),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedPlayerCharacter(double screenWidth) {
    return AnimatedBuilder(
      animation: _unlockController,
      builder: (context, child) {
        final targetX = _getNodeX(currentLevel, screenWidth);
        final targetY = currentLevel * 120.0 + 20;

        double x = targetX;
        double y = targetY;

        if (_animatingFromLevel != -1) {
          final startX = _getNodeX(_animatingFromLevel, screenWidth);
          final startY = _animatingFromLevel * 120.0 + 20;

          x = startX + (targetX - startX) * _avatarMoveAnim.value;
          y = startY + (targetY - startY) * _avatarMoveAnim.value;
        }

        return Positioned(
          left: x - 30,
          top: y + 2,
          child: IgnorePointer(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(widget.studentData?['avatar_url'] ?? 'assets/images/solo_blue.png'),
                  fit: BoxFit.contain,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 8),
                    blurRadius: 10,
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToLevel(int index) async {
    if (_isNavigating || _animatingFromLevel != -1) return;
    _isNavigating = true;

    try {
      Widget nextScreen;
      switch (index) {
        case 0:
          nextScreen = const Activity1SpotDifference();
          break;
        case 1:
          nextScreen = const Activity2Pattern();
          break;
        case 2:
          nextScreen = const Activity3MissingPicture();
          break;
        case 3:
          nextScreen = const Activity4VisualMemory();
          break;
        case 4:
          nextScreen = const Activity5CategorySorting();
          break;
        case 5:
          nextScreen = const Activity6HiddenShape();
          break;
        case 6:
          nextScreen = const Activity7SizeOrdering();
          break;
        case 7:
          nextScreen = const Activity8Position();
          break;
        case 8:
          nextScreen = const Activity9Sequence();
          break;
        case 9:
          nextScreen = const Activity10ShadowMatch();
          break;
        default:
          nextScreen = const Activity1SpotDifference();
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );

      if (result == true && index == currentLevel) {
        if (currentLevel < levels.length - 1) {
          setState(() {
            _animatingFromLevel = currentLevel;
            currentLevel++;
            levels[_animatingFromLevel]['completed'] = true;
          });
          
          // Start sequence
          _unlockController.forward(from: 0.0).then((_) {
            if (mounted) {
              setState(() {
                _animatingFromLevel = -1;
              });
              
              // Delay before auto-starting next level if needed
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted && !_isNavigating && _animatingFromLevel == -1) {
                  _navigateToLevel(currentLevel);
                }
              });
            }
          });
          
          _scrollToCurrentLevel();
        } else {
          setState(() {
            levels[currentLevel]['completed'] = true;
          });
        }
      }
    } finally {
      _isNavigating = false;
    }
  }
}


// Path Painter (solid dirt trail)
class PathPainter extends CustomPainter {
  final List<Map<String, dynamic>> levels;
  final int currentLevel;
  final double Function(int) getNodeX;
  final double nodeSpacing;
  
  // Animation props
  final int animatingFromLevel;
  final double pathAnimationProgress;

  PathPainter({
    required this.levels,
    required this.currentLevel,
    required this.getNodeX,
    required this.nodeSpacing,
    required this.animatingFromLevel,
    required this.pathAnimationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // We draw a solid thick path, with a darker outline/shadow underneath for depth
    final pathOutlinePaint = Paint()
      ..color = AppColors.textBrown.withValues(alpha: 0.15)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    final completedPaint = Paint()
      ..color = AppColors.warmAmberLight
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final lockedPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw the continuous path shadows and backgrounds first
    final mainPath = Path();
    for (int i = 0; i < levels.length - 1; i++) {
      final fromX = getNodeX(i);
      final fromY = i * nodeSpacing + 20 + 32;
      final toX = getNodeX(i + 1);
      final toY = (i + 1) * nodeSpacing + 20 + 32;

      if (i == 0) {
        mainPath.moveTo(fromX, fromY);
      }
      
      final controlX1 = fromX;
      final controlY1 = fromY + (nodeSpacing * 0.5);
      final controlX2 = toX;
      final controlY2 = toY - (nodeSpacing * 0.5);
      
      mainPath.cubicTo(controlX1, controlY1, controlX2, controlY2, toX, toY);
    }

    // 1. Draw the outline/shadow
    canvas.drawPath(mainPath, pathOutlinePaint);

    // 2. Draw the path segments
    for (int i = 0; i < levels.length - 1; i++) {
      final fromX = getNodeX(i);
      final fromY = i * nodeSpacing + 20 + 32;
      final toX = getNodeX(i + 1);
      final toY = (i + 1) * nodeSpacing + 20 + 32;

      final isAnimatingSegment = (animatingFromLevel != -1 && i == animatingFromLevel);
      final isCompletedPath = !isAnimatingSegment && ((i + 1) <= currentLevel);
      
      final segmentPath = Path();
      segmentPath.moveTo(fromX, fromY);
      
      final controlX1 = fromX;
      final controlY1 = fromY + (nodeSpacing * 0.5);
      final controlX2 = toX;
      final controlY2 = toY - (nodeSpacing * 0.5);
      
      segmentPath.cubicTo(controlX1, controlY1, controlX2, controlY2, toX, toY);

      if (isAnimatingSegment) {
        // Draw the locked background layer
        canvas.drawPath(segmentPath, lockedPaint);

        // Draw the animating amber layer on top
        if (pathAnimationProgress > 0) {
          for (ui.PathMetric metric in segmentPath.computeMetrics()) {
            final extractLen = metric.length * pathAnimationProgress;
            final partialPath = metric.extractPath(0.0, extractLen);
            canvas.drawPath(partialPath, completedPaint);
            
            final dashPaint = Paint()
              ..color = AppColors.warmAmber
              ..strokeWidth = 6
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round;
            _drawDashedCurve(canvas, partialPath, dashPaint);
          }
        }
      } else {
        final paint = isCompletedPath ? completedPaint : lockedPaint;
        canvas.drawPath(segmentPath, paint);
        
        if (isCompletedPath) {
          final dashPaint = Paint()
            ..color = AppColors.warmAmber
            ..strokeWidth = 6
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          _drawDashedCurve(canvas, segmentPath, dashPaint);
        }
      }
    }
  }

  void _drawDashedCurve(Canvas canvas, Path path, Paint paint) {
    for (ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? 15.0 : 20.0;
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    return oldDelegate.currentLevel != currentLevel ||
           oldDelegate.animatingFromLevel != animatingFromLevel ||
           oldDelegate.pathAnimationProgress != pathAnimationProgress;
  }
}

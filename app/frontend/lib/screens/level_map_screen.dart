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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();

  // Current progress (0-indexed)
  int currentLevel = 0;
  bool _isNavigating = false;

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
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

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
                        // Path
                        CustomPaint(
                          size: Size(screenWidth, levels.length * 120.0),
                          painter: PathPainter(
                            levels: levels,
                            currentLevel: currentLevel,
                            getNodeX: (i) => _getNodeX(i, screenWidth),
                            nodeSpacing: 120.0,
                          ),
                        ),

                        // Level nodes
                        ...List.generate(levels.length, (index) {
                          final level = levels[index];
                          final nodeX = _getNodeX(index, screenWidth);
                          final nodeY = index * 120.0 + 20;
                          final isCompleted = level['completed'] as bool;
                          final isCurrent = index == currentLevel;
                          final isLocked = index > currentLevel;

                          return Positioned(
                            left: nodeX - 32,
                            top: nodeY,
                            child: _buildNode(
                              level: level,
                              index: index,
                              isCompleted: isCompleted,
                              isCurrent: isCurrent,
                              isLocked: isLocked,
                            ),
                          );
                        }),

                        // Player character avatar
                        _buildPlayerCharacter(screenWidth),
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

  Widget _buildNode({
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
        if (!isLocked) {
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
                final scale = isCurrent
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

  Widget _buildPlayerCharacter(double screenWidth) {
    final nodeX = _getNodeX(currentLevel, screenWidth);
    final nodeY = currentLevel * 120.0 + 20;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      left: nodeX - 30,
      top: nodeY + 2,
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
  }

  Future<void> _navigateToLevel(int index) async {
    if (_isNavigating) return;
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
        setState(() {
          levels[currentLevel]['completed'] = true;
          if (currentLevel < levels.length - 1) {
            currentLevel++;
          }
        });
        _scrollToCurrentLevel();
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && currentLevel == index + 1 && !_isNavigating) {
            _navigateToLevel(currentLevel);
          }
        });
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

  PathPainter({
    required this.levels,
    required this.currentLevel,
    required this.getNodeX,
    required this.nodeSpacing,
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
      
      // Control points for a natural curve
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

      final isCompletedPath = (i + 1) <= currentLevel;
      final paint = isCompletedPath ? completedPaint : lockedPaint;

      final segmentPath = Path();
      segmentPath.moveTo(fromX, fromY);
      
      final controlX1 = fromX;
      final controlY1 = fromY + (nodeSpacing * 0.5);
      final controlX2 = toX;
      final controlY2 = toY - (nodeSpacing * 0.5);
      
      segmentPath.cubicTo(controlX1, controlY1, controlX2, controlY2, toX, toY);
      
      canvas.drawPath(segmentPath, paint);
      
      // Draw internal dash lines for a textured road effect
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

  void _drawDashedCurve(Canvas canvas, Path path, Paint paint) {
    // A simplified approach for dashed curves using PathMetrics
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

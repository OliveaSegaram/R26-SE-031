import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'math_game_screen.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();

  // Current progress (0-indexed)
  int currentLevel = 2; // Player has completed levels 0,1 and is on level 2

  // Level data
  final List<Map<String, dynamic>> levels = [
    {'label': '1', 'title': 'අ', 'type': 'lesson', 'completed': true},
    {'label': '2', 'title': 'ආ', 'type': 'lesson', 'completed': true},
    {'label': '3', 'title': 'ඇ', 'type': 'lesson', 'completed': false},
    {'label': '⭐', 'title': 'Review', 'type': 'star', 'completed': false},
    {'label': '4', 'title': 'ඈ', 'type': 'lesson', 'completed': false},
    {'label': '5', 'title': 'ඉ', 'type': 'lesson', 'completed': false},
    {'label': '6', 'title': 'ඊ', 'type': 'lesson', 'completed': false},
    {'label': '⭐', 'title': 'Review', 'type': 'star', 'completed': false},
    {'label': '7', 'title': 'උ', 'type': 'lesson', 'completed': false},
    {'label': '8', 'title': 'ඌ', 'type': 'lesson', 'completed': false},
    {'label': '🏆', 'title': 'Complete!', 'type': 'trophy', 'completed': false},
  ];

  // Characters are now integrated into the background image

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    // Scroll to current level after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  void _scrollToCurrentLevel() {
    // Each node is roughly 120px apart, scroll to show current level centered
    final targetScroll = currentLevel * 120.0 - 200;
    if (_scrollController.hasClients && targetScroll > 0) {
      _scrollController.animateTo(
        targetScroll,
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

  // Zigzag X offset for node positioning (Duolingo-style)
  double _getNodeX(int index, double screenWidth) {
    final centerX = screenWidth / 2;
    final amplitude = screenWidth * 0.2;
    // Sine wave for smooth zigzag
    return centerX + sin(index * 0.8) * amplitude;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // ── Scrollable Map Path ──
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Container(
              width: screenWidth,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/backgrounds/story_map_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 120, bottom: 40),
                child: Stack(
                  children: [
                    // Dotted path connecting nodes
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

                    // Character avatar on current level
                    _buildPlayerCharacter(screenWidth),
                  ],
                ),
              ),
            ),
          ),

          // ── Top Header Bar ──
          _buildTopHeader(),

          // ── Dev Tools (Temporary Navigation) ──
          Positioned(
            bottom: 30,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'prev',
                  onPressed: () {
                    if (currentLevel > 0) {
                      setState(() {
                        levels[currentLevel]['completed'] = false;
                        currentLevel--;
                      });
                      _scrollToCurrentLevel();
                    }
                  },
                  backgroundColor: Colors.white,
                  elevation: 4,
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.extended(
                  heroTag: 'next',
                  onPressed: () {
                    if (currentLevel < levels.length - 1) {
                      setState(() {
                        levels[currentLevel]['completed'] = true;
                        currentLevel++;
                      });
                      _scrollToCurrentLevel();
                    }
                  },
                  backgroundColor: AppColors.mint,
                  elevation: 4,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text(
                    'Complete Task',
                    style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // TOP HEADER
  // ═══════════════════════════════════════
  Widget _buildTopHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        14,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.4),
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
                color: AppColors.primaryLight,
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
              'Sinhala Letters',
              style: GoogleFonts.fredoka(
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
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$currentLevel/${levels.length}',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // LEVEL NODE
  // ═══════════════════════════════════════
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
    double size = 64;

    if (isCompleted) {
      bgColor = AppColors.mint;
      borderColor = AppColors.mintDark;
    } else if (isCurrent) {
      bgColor = AppColors.orange;
      borderColor = AppColors.orangeDark;
    } else {
      bgColor = Colors.grey.shade300;
      borderColor = Colors.grey.shade400;
    }

    if (type == 'star') {
      size = 56;
    } else if (type == 'trophy') {
      size = 72;
    }

    return GestureDetector(
      onTap: () {
        if (!isLocked) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MathGameScreen()),
          );
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
                  border: Border.all(color: borderColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.4),
                      offset: const Offset(0, 4),
                      blurRadius: 0,
                    ),
                    if (isCurrent)
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                  ],
                ),
                child: Center(
                  child: isLocked
                      ? Icon(Icons.lock_rounded,
                          color: Colors.grey.shade500, size: 24)
                      : Text(
                          type == 'trophy' ? '🏆' : label,
                          style: GoogleFonts.fredoka(
                            fontSize: type == 'star' || type == 'trophy'
                                ? 22
                                : 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // PLAYER CHARACTER
  // ═══════════════════════════════════════
  Widget _buildPlayerCharacter(double screenWidth) {
    final nodeX = _getNodeX(currentLevel, screenWidth);
    final visualIndex = currentLevel;
    final nodeY = visualIndex * 120.0 + 20;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      left: nodeX - 30,
      top: nodeY + 2,
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/solo_blue.png'),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }


}

// ═══════════════════════════════════════
// PATH PAINTER (dotted trail between nodes)
// ═══════════════════════════════════════
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
    final completedPaint = Paint()
      ..color = const Color(0xFF2DD4A8) // AppColors.mint
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final lockedPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < levels.length - 1; i++) {
      final fromIndex = i;
      final toIndex = i + 1;

      final fromX = getNodeX(fromIndex);
      final fromY = fromIndex * nodeSpacing + 20 + 32; // center of node
      final toX = getNodeX(toIndex);
      final toY = toIndex * nodeSpacing + 20 + 32;

      final isCompletedPath = toIndex <= currentLevel;
      final paint = isCompletedPath ? completedPaint : lockedPaint;

      // Draw dashed line
      _drawDashedLine(canvas, Offset(fromX, fromY), Offset(toX, toY), paint);
    }
  }

  void _drawDashedLine(
      Canvas canvas, Offset start, Offset end, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final dashLength = 8.0;
    final gapLength = 6.0;
    final steps = distance / (dashLength + gapLength);

    for (int i = 0; i < steps; i++) {
      final t1 = i * (dashLength + gapLength) / distance;
      final t2 = (i * (dashLength + gapLength) + dashLength) / distance;
      if (t2 > 1) break;

      canvas.drawLine(
        Offset(start.dx + dx * t1, start.dy + dy * t1),
        Offset(start.dx + dx * t2, start.dy + dy * t2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

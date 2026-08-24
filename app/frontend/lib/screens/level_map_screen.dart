import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../utils/avatar_utils.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';
import '../models/curriculum_models.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import 'games/game_factory.dart';
import 'activity_complete_screen.dart';
import '../services/telemetry_service.dart';

/// Level Map Screen
/// Dyslexia-accessible: calm blue header, gentle green/warm amber nodes,
/// crème-tinted background, dark grey text.
class LevelMapScreen extends StatefulWidget {
  final SkillDetail skillMap;
  final Map<String, dynamic>? studentData;

  const LevelMapScreen({super.key, required this.skillMap, this.studentData});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _unlockController;
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late Animation<double> _pathAnim;
  late Animation<double> _nodeScaleAnim;
  late Animation<double> _avatarMoveAnim;

  // Current progress (0-indexed)
  int currentLevel = 0;
  bool _isNavigating = false;
  bool _isBottomSheetOpen = false;
  int _animatingFromLevel = -1; // Tracks the level we are animating from

  List<ActivityNode> get levels => widget.skillMap.activities;

  @override
  void initState() {
    super.initState();
    
    // Calculate currentLevel from persistent storage
    _refreshCurrentLevel();
    
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

  void _refreshCurrentLevel() async {
    await ProgressService().init();
    final progress = ProgressService();
    int unlockedLevel = 0;
    for (int i = 0; i < levels.length; i++) {
      if (progress.isActivityCompleted(widget.skillMap.id, levels[i].id)) {
        unlockedLevel = i + 1; // Unlocks the next one
      }
    }
    if (unlockedLevel >= levels.length) unlockedLevel = levels.length - 1;
    if (mounted) {
      setState(() {
        currentLevel = unlockedLevel;
      });
    }
  }

  void _autoStartFirstLevel() {
    bool firstCompleted = ProgressService().isActivityCompleted(widget.skillMap.id, levels[0].id);
    if (currentLevel == 0 && !firstCompleted) {
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
    _audioPlayer.dispose();
    _pulseController.dispose();
    _unlockController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _playActivityAudio(ActivityNode level) async {
    final url = level.audioUrl;
    final text = level.introText.isNotEmpty
        ? level.introText
        : '${level.title}. ${level.description}';

    if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
      } catch (e) {
        debugPrint('Error playing activity audio: $e');
        await TtsService().speak(text);
      }
    } else {
      await TtsService().speak(text);
    }
  }

  // Zigzag X offset (Duolingo-style)
  double _getNodeX(int index, double screenWidth) {
    final centerX = screenWidth / 2;
    final amplitude = screenWidth * 0.2;
    return centerX + sin(index * 0.8) * amplitude;
  }

  double _getNodeSize(int index) {
    return index == levels.length - 1 ? 96.0 : 76.0;
  }

  double _getNodeCenterY(int index, double nodeSpacing) {
    double top = index * nodeSpacing + 20;
    return top + _getNodeSize(index) / 2;
  }

  // View Toggle: Map View vs Dashboard List View
  bool _isMapView = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Use a fixed, consistent premium spacing for all skills
    double nodeSpacing = 130.0;

    // Determine map height
    double contentHeight = levels.length * nodeSpacing + 160;
    double mapHeight = max(screenHeight, contentHeight);
    bool shouldScroll = contentHeight > screenHeight;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // Content View: Map View vs Dashboard List View
          if (_isMapView)
            SingleChildScrollView(
              controller: _scrollController,
              physics: shouldScroll ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: screenWidth,
                height: mapHeight,
                child: Stack(
                  children: [
                    // Full Background Image
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/backgrounds/map_bg.png',
                        fit: BoxFit.cover,
                        width: screenWidth,
                        height: mapHeight,
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
                                size: Size(screenWidth, levels.length * nodeSpacing),
                                painter: PathPainter(
                                  levels: levels,
                                  currentLevel: currentLevel,
                                  getNodeX: (i) => _getNodeX(i, screenWidth),
                                  getNodeCenterY: (i) => _getNodeCenterY(i, nodeSpacing),
                                  nodeSpacing: nodeSpacing,
                                  animatingFromLevel: _animatingFromLevel,
                                  pathAnimationProgress: _pathAnim.value,
                                ),
                              );
                            }
                          ),

                          // Level nodes
                          ...List.generate(levels.length, (index) {
                            return _buildAnimatedNodePositioned(index, screenWidth, nodeSpacing);
                          }),

                          // Player character avatar
                          _buildAnimatedPlayerCharacter(screenWidth, nodeSpacing),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildDashboardListView(),

          // Top Header Bar
          _buildTopHeader(),
        ],
      ),
    );
  }

  Widget _buildDashboardListView() {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 72,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: levels.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final level = levels[index];
          final isCompleted = ProgressService().isActivityCompleted(widget.skillMap.id, level.id);
          final score = ProgressService().getActivityScore(widget.skillMap.id, level.id);
          final isCurrent = (index == currentLevel);
          final isLocked = (index > currentLevel);

          return GestureDetector(
            onTap: () {
              if (!isLocked && _animatingFromLevel == -1 && !_isBottomSheetOpen) {
                _showActivityPreviewSheet(index);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.warmAmber.withValues(alpha: 0.12)
                    : isCompleted
                        ? AppColors.gentleGreen.withValues(alpha: 0.08)
                        : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isCurrent
                      ? AppColors.warmAmber
                      : isCompleted
                          ? AppColors.gentleGreen
                          : AppColors.borderLight,
                  width: isCurrent ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Activity Index Badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.gentleGreen
                          : isCurrent
                              ? AppColors.warmAmber
                              : AppColors.borderLight.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 26)
                          : isLocked
                              ? const Icon(Icons.lock_rounded, color: AppColors.textSecondary, size: 22)
                              : Text(
                                  '${index + 1}',
                                  style: AppTypography.button(fontSize: 20, color: Colors.white),
                                ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title & Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(
                              'ක්‍රියාකාරකම ${index + 1}',
                              style: AppTypography.sinhala(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isCurrent ? AppColors.warmAmber : AppColors.textSecondary,
                              ),
                            ),
                            if (isCompleted)
                              _buildStarBadge(score, AppColors.gentleGreen),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          level.title,
                          style: AppTypography.sinhala(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (level.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            level.description,
                            style: AppTypography.sinhala(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Speaker Icon Button
                  GestureDetector(
                    onTap: () => _playActivityAudio(level),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warmAmber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.warmAmber,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Play Icon Action
                  if (!isLocked)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.warmAmber : AppColors.gentleGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    )
                  else
                    const Icon(Icons.lock_outline_rounded, color: AppColors.borderLight, size: 22),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showActivityPreviewSheet(int index) {
    if (_isBottomSheetOpen) return;
    _isBottomSheetOpen = true;
    final level = levels[index];
    final isCompleted = ProgressService().isActivityCompleted(widget.skillMap.id, level.id);
    final score = ProgressService().getActivityScore(widget.skillMap.id, level.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warmAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'ක්‍රියාකාරකම ${index + 1}',
                    style: AppTypography.sinhala(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.warmAmber),
                  ),
                ),
                if (isCompleted) ...[
                  const SizedBox(width: 8),
                  _buildStarBadge(score, AppColors.gentleGreen),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              level.title,
              textAlign: TextAlign.center,
              style: AppTypography.sinhala(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
            if (level.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                level.description,
                textAlign: TextAlign.center,
                style: AppTypography.sinhala(fontSize: 15, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 16),

            // Speaker Audio Instruction Button
            GestureDetector(
              onTap: () => _playActivityAudio(level),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warmAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warmAmber, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.volume_up_rounded, color: AppColors.warmAmber, size: 22),
                    const SizedBox(width: 6),
                    Text(
                      'උපදෙස් වලට සවන් දෙන්න',
                      style: AppTypography.sinhala(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.warmAmber),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToLevel(index);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gentleGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text('ක්‍රීඩා කරමු', style: AppTypography.button(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Clear flag when sheet is closed (by swipe down, tap outside, or programmatic pop)
      if (mounted) {
        _isBottomSheetOpen = false;
      }
    });
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
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Text(
              widget.skillMap.title,
              style: AppTypography.sinhala(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // View Switcher Segmented Button (Map View vs List View)
          Container(
            height: 36,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isMapView = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isMapView ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.map_rounded,
                      size: 18,
                      color: _isMapView ? AppColors.calmBlue : Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isMapView = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: !_isMapView ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.view_list_rounded,
                      size: 18,
                      color: !_isMapView ? AppColors.calmBlue : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedNodePositioned(int index, double screenWidth, double nodeSpacing) {
    return AnimatedBuilder(
      animation: _unlockController,
      builder: (context, child) {
        final level = levels[index];
        final nodeX = _getNodeX(index, screenWidth);
        final nodeY = index * nodeSpacing + 20;

        bool isCompleted = ProgressService().isActivityCompleted(widget.skillMap.id, level.id);
        int score = ProgressService().getActivityScore(widget.skillMap.id, level.id);
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

        final double nodeSize = _getNodeSize(index);
        final double wrapperWidth = 100;
        final double offset = wrapperWidth / 2;

        return Positioned(
          left: nodeX - offset,
          top: nodeY,
          child: Transform.scale(
            scale: additionalScale,
            child: _buildNodeCore(
              level: level,
              index: index,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isLocked: isLocked,
              score: score,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNodeCore({
    required ActivityNode level,
    required int index,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLocked,
    required int score,
  }) {
    final type = index == levels.length - 1 ? 'trophy' : 'star';
    final label = (index + 1).toString();

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

    final int fails = ProgressService().getFailureCount(widget.skillMap.id, level.id);
    final bool isRemedial = fails >= 2 && (isCurrent || isCompleted);
    
    if (isRemedial) {
      borderColor = AppColors.softCoral;
      borderWidth = 4;
    }

    double fontSize = 24;
    double iconSize = 28;

    if (type == 'star') {
      size = 76;
      fontSize = 34;
      iconSize = 36;
    } else if (type == 'trophy') {
      size = 96;
      fontSize = 46;
    }

    return GestureDetector(
      onTap: () {
        if (!isLocked && _animatingFromLevel == -1 && !_isBottomSheetOpen) {
          _showActivityPreviewSheet(index);
        }
      },
      child: SizedBox(
        width: 100,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
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
                          ? Icon(Icons.lock_rounded, color: AppColors.borderLight, size: 32)
                          : (isCompleted && type != 'trophy'
                              ? Icon(Icons.check_rounded, color: Colors.white, size: iconSize)
                              : (type == 'trophy'
                                  ? ((isCurrent && _animatingFromLevel == -1)
                                      ? const SizedBox.shrink()
                                      : Text(
                                          '🏆',
                                          style: AppTypography.button(
                                            fontSize: fontSize,
                                            color: contentColor,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ))
                                  : const SizedBox.shrink())),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
            if (isCompleted || (isCurrent && score > 0))
              Positioned(
                bottom: -4,
                child: _buildStarBadge(score, isCompleted ? AppColors.gentleGreen : AppColors.warmAmber),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarBadge(int score, Color baseColor) {
    int starCount = 1;
    if (score >= 80) {
      starCount = 3;
    } else if (score >= 50) {
      starCount = 2;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warmAmber,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orangeDark, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          starCount,
          (i) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.0),
            child: Icon(Icons.star_rounded, color: Colors.white, size: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedPlayerCharacter(double screenWidth, double nodeSpacing) {
    return AnimatedBuilder(
      animation: _unlockController,
      builder: (context, child) {
        final targetX = _getNodeX(currentLevel, screenWidth);
        final targetY = _getNodeCenterY(currentLevel, nodeSpacing);

        double x = targetX;
        double y = targetY;

        if (_animatingFromLevel != -1) {
          final startX = _getNodeX(_animatingFromLevel, screenWidth);
          final startY = _getNodeCenterY(_animatingFromLevel, nodeSpacing);

          x = startX + (targetX - startX) * _avatarMoveAnim.value;
          y = startY + (targetY - startY) * _avatarMoveAnim.value;
        }

        final avatarUrl = AvatarUtils.getCorrectedAvatarPath(widget.studentData?['avatar_url'] as String?, 'assets/images/characters/mascots/solo_blue.png');
        final double scaleFactor = 1.05;
        final double containerSize = 76;
        final double halfSize = containerSize / 2;

        return Positioned(
          left: x - halfSize,
          top: y - halfSize,
          child: IgnorePointer(
            child: Transform.scale(
              scale: scaleFactor,
              alignment: Alignment.center,
              child: Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(avatarUrl),
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
          ),
        );
      },
    );
  }

  Future<void> _navigateToLevel(int index, {bool forceGame = false}) async {
    if (_isNavigating || _animatingFromLevel != -1) return;
    _isNavigating = true;

    try {
      final level = levels[index];
      final bool isCompleted = ProgressService().isActivityCompleted(widget.skillMap.id, level.id);
      final int savedScore = ProgressService().getActivityScore(widget.skillMap.id, level.id);

      // If already completed and not force-playing, show ActivityCompleteScreen directly (revisiting mode)
      if (isCompleted && !forceGame) {
        _isNavigating = false;
        final action = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityCompleteScreen(
              activityNode: level,
              skillId: widget.skillMap.id,
              score: savedScore,
              isRevisiting: true,
              onRetake: () => Navigator.pop(context, 'retake'),
              onContinue: () => Navigator.pop(context, 'continue'),
            ),
          ),
        );

        if (action == 'retake') {
          await _navigateToLevel(index, forceGame: true);
        }
        return;
      }

      // DDA: Check if this is a remedial attempt
      final fails = ProgressService().getFailureCount(widget.skillMap.id, level.id);
      final bool isRemedial = fails >= 2;

      Widget nextScreen = GameFactory.buildGame(level, isRemedial: isRemedial);
      
      // Start a new telemetry session for this activity
      TelemetryService().startSession();
      TelemetryService().startActivity(level.title);

      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );

      // Extract score result if provided as int or default to 100 on continue
      int scoreToSave = 100;
      if (result != null && result is int) {
        scoreToSave = result;
      }
      
      // Submit the telemetry session that was recorded during this activity
      final studentId = ProgressService().currentStudentId;
      await TelemetryService().endSessionAndSubmit(studentId);

      // DDA: Update failure count
      if (scoreToSave < 40) {
        await ProgressService().incrementFailureCount(widget.skillMap.id, level.id);
      } else if (scoreToSave >= 40 && fails > 0) {
        await ProgressService().resetFailureCount(widget.skillMap.id, level.id);
      }

      // Mark level as completed persistently
      final currentScore = ProgressService().getActivityScore(widget.skillMap.id, level.id);
      if (scoreToSave > currentScore || !isCompleted) {
        await ProgressService().saveActivityScore(widget.skillMap.id, level.id, scoreToSave);
      }
      await ProgressService().markActivityCompleted(widget.skillMap.id, level.id);

      final nextLevelIndex = index + 1;
      if (nextLevelIndex > currentLevel && nextLevelIndex < levels.length) {
        if (!mounted) return;
        setState(() {
          _animatingFromLevel = currentLevel;
          currentLevel = nextLevelIndex;
        });

        // Trigger smooth avatar glide animation to the newly unlocked activity
        _unlockController.forward(from: 0.0).then((_) {
          if (mounted) {
            setState(() {
              _animatingFromLevel = -1;
            });
          }
        });

        _scrollToCurrentLevel();
      } else {
        _refreshCurrentLevel();
      }
    } finally {
      _isNavigating = false;
    }
  }
}


// Path Painter (solid dirt trail)
class PathPainter extends CustomPainter {
  final List<ActivityNode> levels;
  final int currentLevel;
  final double Function(int) getNodeX;
  final double Function(int) getNodeCenterY;
  final double nodeSpacing;
  
  // Animation props
  final int animatingFromLevel;
  final double pathAnimationProgress;

  PathPainter({
    required this.levels,
    required this.currentLevel,
    required this.getNodeX,
    required this.getNodeCenterY,
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
      final fromY = getNodeCenterY(i);
      final toX = getNodeX(i + 1);
      final toY = getNodeCenterY(i + 1);

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
      final fromY = getNodeCenterY(i);
      final toX = getNodeX(i + 1);
      final toY = getNodeCenterY(i + 1);

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

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'level_map_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? studentData;

  const DashboardScreen({super.key, this.studentData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int _selectedCategory = 0;
  late AnimationController _animationController;

  final List<Map<String, String>> _categories = [
    {'label': 'Top Picks', 'icon': 'assets/images/icons/icon-star.png'},
    {'label': 'Health', 'icon': 'assets/images/icons/icon-health.png'},
    {'label': 'ABC', 'icon': 'assets/images/icons/icon-abc.png'},
    {'label': 'World', 'icon': 'assets/images/icons/icon-globe.png'},
  ];

  final List<Map<String, dynamic>> _skillCards = [
    {'image': 'assets/images/cards/card_shape.png', 'title': 'හැඩ හඳුනාගැනීම', 'progress': 0.35},
    {'image': 'assets/images/cards/card_sound.png', 'title': 'ශබ්ද වෙනස හඳුනාගැනීම', 'progress': null},
    {'image': 'assets/images/cards/card_letter.png', 'title': 'අකුරු හඳුනාගැනීම', 'progress': 0.70},
    {'image': 'assets/images/cards/card_initial.png', 'title': 'මුල් ශබ්දය', 'progress': null},
    {'image': 'assets/images/cards/card_ending.png', 'title': 'අවසන් ශබ්දය', 'progress': 0.15},
    {'image': 'assets/images/cards/card_diacritics.png', 'title': 'පිල්ලම් හඳුනාගැනීම', 'progress': null},
    {'image': 'assets/images/cards/card_rhyme.png', 'title': 'එළිසමය සහිත වචන', 'progress': 0.50},
    {'image': 'assets/images/cards/card_blend.png', 'title': 'අකුරු ගැලපීම', 'progress': 0.85},
    {'image': 'assets/images/cards/card_word.png', 'title': 'වචන සෑදීම', 'progress': null},
    {'image': 'assets/images/cards/card_sentence.png', 'title': 'වාක්‍ය කියවීම', 'progress': 0.05},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background utilizing the AppTheme Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.splashGradient,
            ),
          ),
          // A subtle pattern or glow to make it more advanced
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mint.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mint.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Bar: Profile + Greeting ──
                _buildTopBar(),

                const SizedBox(height: 16),

                // ── Top Navigation Icons ──
                _buildTopNavBar(),

                const SizedBox(height: 32),

                // ── Skills Grid ──
                Expanded(
                  child: FadeTransition(
                    opacity: _animationController,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOutCubic,
                      )),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: _skillCards.length,
                        itemBuilder: (context, index) {
                          final card = _skillCards[index];
                          return _buildSkillCard(
                            imagePath: card['image'] as String,
                            title: card['title'] as String,
                            progress: card['progress'] as double?,
                          );
                        },
                      ),
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

  // ═══════════════════════════════════════
  // TOP BAR (Profile)
  // ═══════════════════════════════════════
  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar (No orange border, no white background)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset(
              widget.studentData?['avatar_url'] ?? 'assets/images/solo_blue.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${widget.studentData?['first_name'] ?? 'Ace'}! 👋',
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Let's play and learn!",
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
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
  // TOP NAVIGATION ICONS (Original 6 icons, full width, NO background)
  // ═══════════════════════════════════════
  Widget _buildTopNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_categories.length, (index) {
          final isActive = _selectedCategory == index;
          final cat = _categories[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              transform: Matrix4.identity()..scale(isActive ? 1.15 : 1.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon purely displayed without any background Container
                  Image.asset(
                    cat['icon']!,
                    width: 60,
                    height: 60,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cat['label']!,
                    style: GoogleFonts.fredoka(
                      fontSize: isActive ? 13 : 11,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive ? AppColors.gold : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════
  // SKILL CARD (Premium 3D Look, Fill Image, Progress Bar)
  // ═══════════════════════════════════════
  Widget _buildSkillCard({
    required String imagePath,
    required String title,
    double? progress,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LevelMapScreen(studentData: widget.studentData)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSlateLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section (Fills the entire space)
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: Hero(
                  tag: imagePath,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover, // Ensures the image fills the space completely
                  ),
                ),
              ),
            ),

            // Text & Progress Section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.notoSansSinhala(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (progress != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mint),
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '✨ NEW',
                        style: GoogleFonts.fredoka(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

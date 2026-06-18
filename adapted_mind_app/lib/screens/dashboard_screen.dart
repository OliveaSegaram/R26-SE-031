import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'level_map_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred Background
          Image.asset(
            'assets/images/backgrounds/new-map.png',
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Category Bar
                _buildCategoryBar(context),
                
                // Story Cards
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      children: [
                        // Top Row: 2 large cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStoryCard(
                                context: context,
                                imagePath: 'assets/images/cards/card-shark.png',
                                title: 'Clark the Shark',
                                progress: 0.35,
                                aspectRatio: 16/10,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStoryCard(
                                context: context,
                                imagePath: 'assets/images/cards/card-pyramid.png',
                                title: 'Pyramid',
                                aspectRatio: 16/10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Bottom Row: 3 smaller cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStoryCard(
                                context: context,
                                imagePath: 'assets/images/cards/card-monster.png',
                                title: 'Monster School',
                                aspectRatio: 1,
                                smallText: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStoryCard(
                                context: context,
                                imagePath: 'assets/images/cards/card-animals.png',
                                title: 'Safari Animals',
                                aspectRatio: 1,
                                smallText: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStoryCard(
                                context: context,
                                imagePath: 'assets/images/cards/card-wish.png',
                                title: 'I Wish You More',
                                aspectRatio: 1,
                                smallText: true,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildCategoryBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildCategoryItem('Top Picks', 'assets/images/icons/icon-star.png', isActive: true),
                  _buildCategoryItem('Friends', 'assets/images/icons/icon-friends.png'),
                  _buildCategoryItem('Health', 'assets/images/icons/icon-health.png'),
                  _buildCategoryItem('ABC', 'assets/images/icons/icon-abc.png'),
                  _buildCategoryItem('Science', 'assets/images/icons/icon-science.png'),
                  _buildCategoryItem('World', 'assets/images/icons/icon-globe.png'),
                ],
              ),
            ),
          ),
          
          // User Greeting
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.only(left: 12, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Text(
                    'Hi, Ace',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/characters/character.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, String imagePath, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath,
            width: 48,
            height: 48,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 12,
              color: Colors.white,
              shadows: const [
                Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black45),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard({
    required BuildContext context,
    required String imagePath,
    required String title,
    double? progress,
    required double aspectRatio,
    bool smallText = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LevelMapScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (progress != null)
                    Positioned(
                      bottom: 8,
                      left: 12,
                      right: 12,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF5CDD3C),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: smallText ? 14 : 18,
                  color: const Color(0xFF1A237E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:math';
import '../../theme/app_theme.dart';

enum MoveType {
  bounce,
  spin,
  float,
  zoom,
  heartbeat,
  shake,
  pendulum,
  flipFlop,
  squish,
  peekaboo,
}

class CharacterConfig {
  final String name;
  final String assetPath;
  final MoveType moveType;
  final Color color;

  const CharacterConfig({
    required this.name,
    required this.assetPath,
    required this.moveType,
    required this.color,
  });
}

class CharacterShopScreen extends StatefulWidget {
  const CharacterShopScreen({super.key});

  @override
  State<CharacterShopScreen> createState() => _CharacterShopScreenState();
}

class _CharacterShopScreenState extends State<CharacterShopScreen> with TickerProviderStateMixin {
  static const List<CharacterConfig> _characters = [
    CharacterConfig(name: 'Blue Blob', assetPath: 'assets/images/solo_blue.png', moveType: MoveType.bounce, color: AppColors.calmBlue),
    CharacterConfig(name: 'Pink Berry', assetPath: 'assets/images/solo_pink.png', moveType: MoveType.spin, color: AppColors.softCoral),
    CharacterConfig(name: 'Yellow Star', assetPath: 'assets/images/solo_yellow.png', moveType: MoveType.float, color: AppColors.warmAmber),
    CharacterConfig(name: 'Green Slime', assetPath: 'assets/images/solo_green.png', moveType: MoveType.zoom, color: AppColors.gentleGreen),
    CharacterConfig(name: 'Teal Drop', assetPath: 'assets/images/solo_teal.png', moveType: MoveType.heartbeat, color: Colors.teal),
    CharacterConfig(name: 'Orange Flame', assetPath: 'assets/images/solo_orange.png', moveType: MoveType.shake, color: Colors.orangeAccent),
    CharacterConfig(name: 'Furry Blue', assetPath: 'assets/images/blue_monster.png', moveType: MoveType.pendulum, color: Colors.blueAccent),
    CharacterConfig(name: 'Furry Green', assetPath: 'assets/images/green_monster.png', moveType: MoveType.flipFlop, color: Colors.lightGreen),
    CharacterConfig(name: 'Furry Pink', assetPath: 'assets/images/pink_monster.png', moveType: MoveType.squish, color: Colors.pinkAccent),
    CharacterConfig(name: 'Furry Yellow', assetPath: 'assets/images/yellow_monster.png', moveType: MoveType.peekaboo, color: Colors.amber),
  ];

  late AnimationController _moveController;
  late AnimationController _gridController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _moveController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  void _selectCharacter(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Restart move animation from beginning to ensure it plays immediately
    _moveController.forward(from: 0.0);
    _moveController.repeat();
  }

  Widget _buildAnimatedCharacter(CharacterConfig character, Animation<double> animation) {
    final Widget image = Image.asset(character.assetPath, width: 180, height: 180, fit: BoxFit.contain);
    
    switch (character.moveType) {
      case MoveType.bounce:
        final double dy = sin(animation.value * pi) * -80; // Bounces up 80px
        return Transform.translate(offset: Offset(0, dy), child: image);
      case MoveType.spin:
        return Transform.rotate(angle: animation.value * 2 * pi, child: image);
      case MoveType.float:
        final double dy = sin(animation.value * 2 * pi) * -30;
        return Transform.translate(offset: Offset(0, dy), child: image);
      case MoveType.zoom:
        final double dx = sin(animation.value * 2 * pi) * 100;
        return Transform.translate(offset: Offset(dx, 0), child: image);
      case MoveType.heartbeat:
        final double scale = 1.0 + (sin(animation.value * pi * 4).abs() * 0.3);
        return Transform.scale(scale: scale, child: image);
      case MoveType.shake:
        final double dx = sin(animation.value * pi * 16) * 12;
        final double r = sin(animation.value * pi * 16) * 0.15;
        return Transform.translate(offset: Offset(dx, 0), child: Transform.rotate(angle: r, child: image));
      case MoveType.pendulum:
        final double angle = sin(animation.value * 2 * pi) * 0.5;
        return Transform(
          transform: Matrix4.rotationZ(angle),
          alignment: Alignment.bottomCenter,
          child: image,
        );
      case MoveType.flipFlop:
        final double angle = (animation.value < 0.5) 
            ? sin(animation.value * 2 * pi) * pi 
            : 0; 
        return Transform(
          transform: Matrix4.rotationY(angle),
          alignment: Alignment.center,
          child: image,
        );
      case MoveType.squish:
        final double scaleY = 1.0 + (sin(animation.value * 2 * pi) * 0.4);
        final double scaleX = 1.0 - (sin(animation.value * 2 * pi) * 0.3);
        return Transform(
          transform: Matrix4.identity()..scale(scaleX, scaleY, 1.0),
          alignment: Alignment.bottomCenter,
          child: image,
        );
      case MoveType.peekaboo:
        // Goes from 0 -> 1 -> 0
        final double opacity = 1.0 - (animation.value * 2 - 1.0).abs();
        final double scale = 0.4 + (opacity * 0.6);
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: image),
        );
    }
  }

  String _getMoveName(MoveType type) {
    switch(type) {
      case MoveType.bounce: return "the big bounce!";
      case MoveType.spin: return "the wobbly spin!";
      case MoveType.float: return "the magic float!";
      case MoveType.zoom: return "the speedy zoom!";
      case MoveType.heartbeat: return "the heartbeat!";
      case MoveType.shake: return "the happy shake!";
      case MoveType.pendulum: return "the pendulum swing!";
      case MoveType.flipFlop: return "the flip flop!";
      case MoveType.squish: return "the squish!";
      case MoveType.peekaboo: return "the peekaboo!";
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCharacter = _characters[_selectedIndex];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'character shop',
          style: AppTypography.heading(fontSize: 24, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Stage: Displays the animated character
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative Spotlight
                  Positioned(
                    bottom: 40,
                    child: Container(
                      width: 250,
                      height: 60,
                      decoration: BoxDecoration(
                        color: selectedCharacter.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: selectedCharacter.color.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // The Animated Character
                  AnimatedBuilder(
                    animation: _moveController,
                    builder: (context, child) {
                      return _buildAnimatedCharacter(selectedCharacter, _moveController);
                    },
                  ),
                  // Move Name Text
                  Positioned(
                    top: 20,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey<String>(selectedCharacter.name),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedCharacter.color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: selectedCharacter.color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _getMoveName(selectedCharacter.moveType),
                          style: AppTypography.body(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Carousel: Grid of characters
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Text(
                        'choose your buddy!',
                        style: AppTypography.heading(
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, // 5 across (2 rows of 5 = 10 total)
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _characters.length,
                        itemBuilder: (context, index) {
                          final config = _characters[index];
                          final isSelected = index == _selectedIndex;

                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.5),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _gridController,
                              curve: Interval(index * 0.05, 1.0, curve: Curves.easeOutBack),
                            )),
                            child: GestureDetector(
                              onTap: () => _selectCharacter(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                                margin: EdgeInsets.only(
                                  top: isSelected ? 4 : 12,
                                  bottom: isSelected ? 12 : 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? config.color.withValues(alpha: 0.2) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? config.color : AppColors.borderLight,
                                    width: isSelected ? 3 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected ? config.color.withValues(alpha: 0.3) : Colors.transparent,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(config.assetPath, fit: BoxFit.contain),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

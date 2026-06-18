import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'math_game_screen.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  
  // Starting node position based on web sample (Node 1)
  final double charX = 0.22; // 22%
  final double charY = 0.62; // 62%

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Map Background
          Image.asset(
            'assets/images/backgrounds/new-map.png',
            fit: BoxFit.cover,
          ),
          
          // Character placed at node 1
          LayoutBuilder(
            builder: (context, constraints) {
              return Positioned(
                left: constraints.maxWidth * charX - 30, // Offset by half width
                top: constraints.maxHeight * charY - 60, // Offset by height to align bottom
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MathGameScreen()),
                    );
                  },
                  child: AnimatedBuilder(
                    animation: _bounceController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -10 * _bounceController.value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5)),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/characters/character.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
          
          // Back Button
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFF6EC7), Color(0xFFE0157A)],
                    center: Alignment(-0.3, -0.4),
                  ),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFFA00D55), offset: Offset(0, 4)),
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 6)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),
          
          // Helper text
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tap the character to play!',
                  style: GoogleFonts.fredoka(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

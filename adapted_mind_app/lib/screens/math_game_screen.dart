import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MathGameScreen extends StatefulWidget {
  const MathGameScreen({super.key});

  @override
  State<MathGameScreen> createState() => _MathGameScreenState();
}

class _MathGameScreenState extends State<MathGameScreen> {
  String _answer = '';
  final String _question = 'What is 16 - 1?';
  int _score = 185;

  void _onNumPress(String num) {
    if (_answer.length < 3) {
      setState(() {
        _answer += num;
      });
    }
  }

  void _onErase() {
    if (_answer.isNotEmpty) {
      setState(() {
        _answer = _answer.substring(0, _answer.length - 1);
      });
    }
  }

  void _onSubmit() {
    if (_answer == '15') {
      setState(() {
        _score += 10;
        _answer = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Correct! +10 Points', style: GoogleFonts.fredoka(fontSize: 18)),
          backgroundColor: const Color(0xFF2EC820),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      setState(() {
        _answer = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Try Again!', style: GoogleFonts.fredoka(fontSize: 18)),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                // Top Bar
                _buildTopBar(context),
                
                // Main Content (Question Card)
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [Color(0xFFD966CC), Color(0xFFB020A8)],
                                    center: Alignment(-0.3, -0.4),
                                  ),
                                ),
                                child: const Icon(Icons.volume_up_rounded, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Flexible(
                                child: Text(
                                  _question,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 28,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Container(
                            width: 120,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF6AB0F5), width: 3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _answer,
                              style: GoogleFonts.fredoka(
                                fontSize: 32,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Numpad Area
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2A3A8C), Color(0xFF1A2A6C)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildNumBtn('1'),
                            const SizedBox(width: 8),
                            _buildNumBtn('2'),
                            const SizedBox(width: 8),
                            _buildNumBtn('3'),
                            const SizedBox(width: 8),
                            _buildNumBtn('4'),
                            const SizedBox(width: 8),
                            _buildNumBtn('5'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildNumBtn('6'),
                            const SizedBox(width: 8),
                            _buildNumBtn('7'),
                            const SizedBox(width: 8),
                            _buildNumBtn('8'),
                            const SizedBox(width: 8),
                            _buildNumBtn('9'),
                            const SizedBox(width: 8),
                            _buildNumBtn('0'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: _onErase,
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Color(0xFFE060D0), Color(0xFFA020A0)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(color: Color(0xFF7A1080), offset: Offset(0, 4)),
                                    ],
                                  ),
                                  child: const Icon(Icons.backspace_rounded, color: Colors.white),
                                ),
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
          
          // Submit Button
          Positioned(
            bottom: 30,
            right: 20,
            child: GestureDetector(
              onTap: _onSubmit,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF6AE860), Color(0xFF2EC820)],
                    center: Alignment(-0.3, -0.4),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF1A8A0E), offset: Offset(0, 4)),
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Close button
          GestureDetector(
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
                boxShadow: const [
                  BoxShadow(color: Color(0xFFA00D55), offset: Offset(0, 3)),
                ],
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          // Progress Bar
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5, // 50% progress
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5CDD3C), Color(0xFF2FA018)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF5C04A), Color(0xFFD4890E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0xFFB8730A), offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                Text(
                  '$_score',
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.diamond_rounded, color: Color(0xFFFF6EC7), size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumBtn(String num) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNumPress(num),
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5CDD3C), Color(0xFF2FA018)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0xFF1D7010), offset: Offset(0, 4)),
            ],
          ),
          child: Text(
            num,
            style: GoogleFonts.fredoka(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

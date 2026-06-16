import 'package:flutter/material.dart';

import '../widgets/adapted_mind_ui.dart';
import '../widgets/kid_art.dart';
import 'task_flow_screen.dart';

class PlayHubScreen extends StatelessWidget {
  const PlayHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7E57C2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_emotions_rounded,
                        color: Color(0xFFFFEB3B),
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ආයුබෝවන්!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'පළමු ශ්‍රේණිය — කියවීම',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: const KidArt(visual: 'book'),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'පින්තූර, වචන, සහ කොටස්\nක්‍රීඩාව එකටම එනවා!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.35,
                    shadows: [
                      Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'මධ්‍යම මට්ටමෙන් පටන් ගන්නවා.\nවැරදුණොත් සරල මට්ටමට යනවා.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xE6FFFFFF),
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 68,
                  child: ElevatedButton(
                    onPressed: () => _start(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(34),
                      ),
                      elevation: 10,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 40),
                        SizedBox(width: 10),
                        Text(
                          'පටන් ගමු!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _start(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaskFlowScreen()),
    );
  }
}

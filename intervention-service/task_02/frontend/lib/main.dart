import 'package:flutter/material.dart';

import 'screens/play_hub_screen.dart';
import 'theme/play_theme.dart';

void main() {
  runApp(const Task02App());
}

class Task02App extends StatelessWidget {
  const Task02App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'කියවීමේ ක්‍රීඩාව — Task 02',
      debugShowCheckedModeBanner: false,
      theme: PlayTheme.theme(),
      home: const PlayHubScreen(),
    );
  }
}

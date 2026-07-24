import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/sound_world_screen.dart';
import 'theme/play_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const InterventionPlayApp());
}

/// C4 Intervention Engine — new Sound World UI (Grade 1).
class InterventionPlayApp extends StatelessWidget {
  const InterventionPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sound World',
      debugShowCheckedModeBanner: false,
      theme: PlayTheme.theme(),
      home: const SoundWorldScreen(),
    );
  }
}

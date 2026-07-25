import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/progress_service.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ProgressService (no longer bypassing student ID)
  await ProgressService().init();

  // Set status bar style for light backgrounds (dark icons)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,    // Dark icons on light bg
      statusBarBrightness: Brightness.light,       // Light background
    ),
  );

  // Lock to portrait mode (best for onboarding)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const SipsaraApp());
  });
}

class SipsaraApp extends StatelessWidget {
  const SipsaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sipsara',
      debugShowCheckedModeBanner: false,
      navigatorKey: globalNavigatorKey,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

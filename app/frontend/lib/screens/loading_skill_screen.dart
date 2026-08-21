import 'package:flutter/material.dart';
import '../models/dashboard_config.dart';
import '../models/curriculum_models.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_indicator.dart';
import 'level_map_screen.dart';
import 'skill_intro_screen.dart';

class LoadingSkillScreen extends StatefulWidget {
  final SkillSummary skill;
  final Map<String, dynamic>? studentData;
  final VoidCallback onReturn;

  const LoadingSkillScreen({
    super.key,
    required this.skill,
    this.studentData,
    required this.onReturn,
  });

  @override
  State<LoadingSkillScreen> createState() => _LoadingSkillScreenState();
}

class _LoadingSkillScreenState extends State<LoadingSkillScreen> {
  @override
  void initState() {
    super.initState();
    _loadSkillAndNavigate();
  }

  Future<void> _loadSkillAndNavigate() async {
    try {
      final skillDetail = await SkillDetail.load(widget.skill.file);
      if (!mounted) return;

      final bool isIntroSeen = ProgressService().isSkillIntroSeen(skillDetail.id);
      final Widget targetScreen = isIntroSeen
          ? LevelMapScreen(skillMap: skillDetail, studentData: widget.studentData)
          : SkillIntroScreen(skillMap: skillDetail, studentData: widget.studentData);

      // We use pushReplacement so the user doesn't go back to the loading screen
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      );
      
      // Since it's replaced, the return won't hit here in the same way,
      // but if we used push and waited, we could call onReturn.
      // Wait, dashboard expects onReturn to refresh state!
      // Let's pass the result back or invoke onReturn.
      // If we use pushReplacement, dashboard's 'await Navigator.push' completes!
      // So onReturn will be called immediately by the dashboard, which is fine.
    } catch (e) {
      debugPrint('Error loading skill detail: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: AppLoadingIndicator(),
      ),
    );
  }
}

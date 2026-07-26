import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/curriculum_models.dart';
import '../services/progress_service.dart';

class ProgressAnalyticsScreen extends StatefulWidget {
  final Map<String, dynamic>? studentData;

  const ProgressAnalyticsScreen({super.key, this.studentData});

  @override
  State<ProgressAnalyticsScreen> createState() => _ProgressAnalyticsScreenState();
}

class _ProgressAnalyticsScreenState extends State<ProgressAnalyticsScreen> {
  CurriculumIndex? _curriculum;
  final Map<String, SkillDetail> _skillDetails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await CurriculumIndex.load();
      // Load all skill details to get activities
      for (var skill in data.skills) {
        final detail = await SkillDetail.load(skill.file);
        _skillDetails[skill.id] = detail;
      }
      if (mounted) {
        setState(() {
          _curriculum = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading progress data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.studentData?['first_name'] ?? 'Learner';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.calmBlue,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '$studentName\'s Progress',
          style: AppTypography.heading(fontSize: 20, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _curriculum == null
              ? const Center(child: Text("No data available"))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _curriculum!.skills.length,
                  itemBuilder: (context, index) {
                    final skill = _curriculum!.skills[index];
                    final detail = _skillDetails[skill.id];
                    return _buildSkillProgressCard(skill, detail);
                  },
                ),
    );
  }

  Widget _buildSkillProgressCard(SkillSummary skill, SkillDetail? detail) {
    final double progress = ProgressService().getSkillProgress(skill.id, skill.totalActivities);
    final int completedCount = ProgressService().getCompletedActivitiesCount(skill.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black26,
      color: Colors.white,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: AppColors.calmBlue.withOpacity(0.1),
          radius: 25,
          child: Icon(Icons.star_rounded, color: AppColors.warmAmber, size: 30),
        ),
        title: Text(
          skill.title,
          style: AppTypography.heading(fontSize: 16, color: AppColors.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completedCount / ${skill.totalActivities} Completed',
                  style: AppTypography.caption(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: AppTypography.caption(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gentleGreen),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.borderLight,
              color: AppColors.gentleGreen,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: detail == null
                ? const Text("Details unavailable")
                : Column(
                    children: detail.activities.map((activity) {
                      bool isCompleted = ProgressService().isActivityCompleted(skill.id, activity.id);
                      int score = ProgressService().getActivityScore(skill.id, activity.id);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isCompleted ? AppColors.gentleGreen : AppColors.borderLight,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                activity.title,
                                style: AppTypography.body(
                                  fontSize: 14,
                                  color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warmAmber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Score: $score%',
                                  style: AppTypography.caption(
                                    fontSize: 12,
                                    color: AppColors.orangeDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:math';
import '../../theme/app_theme.dart';

class TherapistStudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const TherapistStudentDetailScreen({super.key, required this.student});

  @override
  State<TherapistStudentDetailScreen> createState() => _TherapistStudentDetailScreenState();
}

class _TherapistStudentDetailScreenState extends State<TherapistStudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock skill data
  final Map<String, double> _skills = {
    'phonological awareness': 0.72,
    'decoding': 0.58,
    'reading fluency': 0.65,
    'comprehension': 0.48,
    'spelling': 0.55,
  };

  // Mock weekly scores (8 weeks)
  final List<double> _weeklyScores = [42, 48, 45, 55, 52, 60, 63, 68];

  // Mock session history
  final List<Map<String, dynamic>> _sessions = [
    {
      'date': 'Jul 28, 2026',
      'duration': '45 min',
      'type': 'Phonological Awareness',
      'score': 78,
      'notes': 'Excellent progress in syllable segmentation. Struggling with phoneme deletion tasks.',
    },
    {
      'date': 'Jul 25, 2026',
      'duration': '40 min',
      'type': 'Reading Fluency',
      'score': 65,
      'notes': 'Read 42 words per minute (up from 38). Still pausing at multisyllabic words.',
    },
    {
      'date': 'Jul 22, 2026',
      'duration': '45 min',
      'type': 'Decoding Practice',
      'score': 62,
      'notes': 'Worked on CVC and CVCC patterns. Consistent b/d reversals noted.',
    },
    {
      'date': 'Jul 18, 2026',
      'duration': '35 min',
      'type': 'Spelling & Morphology',
      'score': 55,
      'notes': 'Introduced common prefixes (un-, re-). Good understanding of root words.',
    },
    {
      'date': 'Jul 15, 2026',
      'duration': '45 min',
      'type': 'Comprehension',
      'score': 48,
      'notes': 'Difficulty with inferential questions. Literal comprehension is strong.',
    },
  ];

  // Mock intervention suggestions
  final List<Map<String, dynamic>> _interventions = [
    {
      'skill': 'comprehension',
      'title': 'graphic organizer strategy',
      'description': 'Use story maps to help visualize narrative structure before answering questions.',
      'icon': Icons.map_outlined,
      'color': AppColors.softCoral,
    },
    {
      'skill': 'decoding',
      'title': 'multisensory phonics drill',
      'description': 'Practice tracing letters in sand/salt trays while saying sounds aloud.',
      'icon': Icons.touch_app_rounded,
      'color': AppColors.warmAmber,
    },
    {
      'skill': 'spelling',
      'title': 'word sort activity',
      'description': 'Sort words by spelling pattern (e.g., -ight, -tion) to build pattern recognition.',
      'icon': Icons.sort_rounded,
      'color': AppColors.calmBlue,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'student profile',
                      style: AppTypography.heading(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getRiskColor(student['risk']).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      student['risk'],
                      style: AppTypography.caption(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _getRiskColor(student['risk']),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Student Header Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.calmBlueDark.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.slateBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(student['avatar'], style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['name'],
                            style: AppTypography.heading(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'age ${student['age']} · parent: ${student['parent']}',
                            style: AppTypography.caption(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'connected since ${student['connected']}',
                            style: AppTypography.caption(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Overall Progress Circle
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: student['progress'] / 100,
                            strokeWidth: 5,
                            backgroundColor: AppColors.borderLight,
                            valueColor: AlwaysStoppedAnimation(_getRiskColor(student['risk'])),
                          ),
                          Text(
                            '${student['progress']}%',
                            style: AppTypography.caption(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.calmBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTypography.caption(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: AppTypography.caption(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'progress'),
                  Tab(text: 'sessions'),
                  Tab(text: 'plan'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProgressTab(),
                  _buildSessionsTab(),
                  _buildPlanTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Progress Tab ───
  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Weekly Progress Chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: AppColors.calmBlueDark.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'weekly progress',
                      style: AppTypography.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mintBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.gentleGreen),
                          const SizedBox(width: 4),
                          Text(
                            '+26%',
                            style: AppTypography.caption(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gentleGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 140,
                  child: CustomPaint(
                    size: const Size(double.infinity, 140),
                    painter: _ChartPainter(scores: _weeklyScores),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(8, (i) => Text(
                    'W${i + 1}',
                    style: AppTypography.caption(fontSize: 10, color: AppColors.textHint),
                  )),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Skill Breakdown
          Text(
            'skill breakdown',
            style: AppTypography.body(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          ..._skills.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: AppTypography.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${(entry.value * 100).round()}%',
                        style: AppTypography.caption(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _getSkillColor(entry.value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: entry.value,
                      minHeight: 8,
                      backgroundColor: AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation(_getSkillColor(entry.value)),
                    ),
                  ),
                ],
              ),
            ),
          )),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Sessions Tab ───
  Widget _buildSessionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.calmBlueDark.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.slateBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event_note_rounded, color: AppColors.calmBlue, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session['type'],
                          style: AppTypography.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${session['date']} · ${session['duration']}',
                          style: AppTypography.caption(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getScoreColor(session['score']).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${session['score']}%',
                      style: AppTypography.caption(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _getScoreColor(session['score']),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        session['notes'],
                        style: AppTypography.caption(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Intervention Plan Tab ───
  Widget _buildPlanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weakest skills alert
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softCoral.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.softCoral.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.priority_high_rounded, color: AppColors.softCoral, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'areas needing focus',
                        style: AppTypography.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.softCoral,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'comprehension (48%) and spelling (55%) are below target',
                        style: AppTypography.caption(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'recommended interventions',
            style: AppTypography.body(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          ..._interventions.map((intervention) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: AppColors.calmBlueDark.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (intervention['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(intervention['icon'] as IconData, color: intervention['color'] as Color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (intervention['color'] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          intervention['skill'],
                          style: AppTypography.caption(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: intervention['color'] as Color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        intervention['title'],
                        style: AppTypography.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        intervention['description'],
                        style: AppTypography.caption(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'On Track':
        return AppColors.gentleGreen;
      case 'Needs Support':
        return AppColors.warmAmber;
      case 'At Risk':
        return AppColors.softCoral;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getSkillColor(double value) {
    if (value >= 0.7) return AppColors.gentleGreen;
    if (value >= 0.55) return AppColors.warmAmber;
    return AppColors.softCoral;
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return AppColors.gentleGreen;
    if (score >= 55) return AppColors.warmAmber;
    return AppColors.softCoral;
  }
}

// ─── Custom Chart Painter ───
class _ChartPainter extends CustomPainter {
  final List<double> scores;

  _ChartPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final maxScore = scores.reduce(max);
    final minScore = scores.reduce(min);
    final range = maxScore - minScore;

    final points = <Offset>[];
    for (int i = 0; i < scores.length; i++) {
      final x = (i / (scores.length - 1)) * size.width;
      final y = size.height - ((scores[i] - minScore) / (range == 0 ? 1 : range)) * (size.height - 20) - 10;
      points.add(Offset(x, y));
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 0.5;

    for (int i = 0; i < 4; i++) {
      final y = (i / 3) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Gradient fill
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x334A90D9), Color(0x004A90D9)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFF4A90D9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    final dotPaint = Paint()..color = const Color(0xFF4A90D9);
    final dotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 4, dotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

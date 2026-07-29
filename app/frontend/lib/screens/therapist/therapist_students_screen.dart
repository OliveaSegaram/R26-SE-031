import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'therapist_student_detail_screen.dart';

class TherapistStudentsScreen extends StatefulWidget {
  const TherapistStudentsScreen({super.key});

  @override
  State<TherapistStudentsScreen> createState() => _TherapistStudentsScreenState();
}

class _TherapistStudentsScreenState extends State<TherapistStudentsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  // Mock students
  final List<Map<String, dynamic>> _students = [
    {
      'name': 'Kavitha Perera',
      'age': 8,
      'parent': 'Kumari Perera',
      'avatar': '👧',
      'progress': 72,
      'risk': 'On Track',
      'lastSession': 'Jul 28',
      'connected': 'Mar 2026',
      'sessionsThisWeek': 2,
    },
    {
      'name': 'Ashan Fernando',
      'age': 10,
      'parent': 'Saman Fernando',
      'avatar': '👦',
      'progress': 58,
      'risk': 'Needs Support',
      'lastSession': 'Jul 27',
      'connected': 'Apr 2026',
      'sessionsThisWeek': 1,
    },
    {
      'name': 'Nethmi Silva',
      'age': 7,
      'parent': 'Dilani Silva',
      'avatar': '👧',
      'progress': 85,
      'risk': 'On Track',
      'lastSession': 'Jul 28',
      'connected': 'Feb 2026',
      'sessionsThisWeek': 3,
    },
    {
      'name': 'Dinuka Bandara',
      'age': 9,
      'parent': 'Rajith Bandara',
      'avatar': '👦',
      'progress': 42,
      'risk': 'At Risk',
      'lastSession': 'Jul 25',
      'connected': 'May 2026',
      'sessionsThisWeek': 0,
    },
    {
      'name': 'Sanduni Jayawardena',
      'age': 8,
      'parent': 'Malini Jayawardena',
      'avatar': '👧',
      'progress': 65,
      'risk': 'Needs Support',
      'lastSession': 'Jul 26',
      'connected': 'Apr 2026',
      'sessionsThisWeek': 1,
    },
    {
      'name': 'Tharindu Rathnayake',
      'age': 11,
      'parent': 'Nimal Rathnayake',
      'avatar': '👦',
      'progress': 78,
      'risk': 'On Track',
      'lastSession': 'Jul 28',
      'connected': 'Jan 2026',
      'sessionsThisWeek': 2,
    },
    {
      'name': 'Ishara Gamage',
      'age': 7,
      'parent': 'Priya Gamage',
      'avatar': '👧',
      'progress': 50,
      'risk': 'At Risk',
      'lastSession': 'Jul 22',
      'connected': 'Jun 2026',
      'sessionsThisWeek': 0,
    },
    {
      'name': 'Hasitha De Silva',
      'age': 9,
      'parent': 'Chaminda De Silva',
      'avatar': '👦',
      'progress': 68,
      'risk': 'Needs Support',
      'lastSession': 'Jul 27',
      'connected': 'Mar 2026',
      'sessionsThisWeek': 2,
    },
  ];

  final List<String> _filters = ['All', 'On Track', 'Needs Support', 'At Risk'];

  List<Map<String, dynamic>> get _filteredStudents {
    var list = _students;
    if (_selectedFilter != 'All') {
      list = list.where((s) => s['risk'] == _selectedFilter).toList();
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((s) => (s['name'] as String).toLowerCase().contains(query)).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'my students',
                    style: AppTypography.heading(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.slateBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_students.length} total',
                      style: AppTypography.caption(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.calmBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.calmBlueDark.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: AppTypography.body(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'search students...',
                    hintStyle: AppTypography.body(fontSize: 14, color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
                    prefixIconConstraints: const BoxConstraints(minWidth: 36),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Filter Chips
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.calmBlue : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.calmBlue : AppColors.borderLight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            filter,
                            style: AppTypography.caption(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Student List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = _filteredStudents[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TherapistStudentDetailScreen(student: student),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
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
                        children: [
                          // Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.slateBg,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(student['avatar'], style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        student['name'],
                                        style: AppTypography.body(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _getRiskColor(student['risk']).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        student['risk'],
                                        style: AppTypography.caption(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _getRiskColor(student['risk']),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'age ${student['age']} · last session: ${student['lastSession']}',
                                  style: AppTypography.caption(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Progress bar
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: student['progress'] / 100,
                                          minHeight: 6,
                                          backgroundColor: AppColors.borderLight,
                                          valueColor: AlwaysStoppedAnimation(_getRiskColor(student['risk'])),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${student['progress']}%',
                                      style: AppTypography.caption(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
}

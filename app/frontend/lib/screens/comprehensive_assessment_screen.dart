import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/comprehensive_assessment_questions.dart';
import '../widgets/monster_character.dart';
import '../widgets/gradient_button.dart';
import '../widgets/pressable_game_button.dart';
import '../services/student_service.dart';

class ComprehensiveAssessmentScreen extends StatefulWidget {
  final String studentId;
  final String category;

  const ComprehensiveAssessmentScreen({
    super.key,
    required this.studentId,
    required this.category,
  });

  @override
  State<ComprehensiveAssessmentScreen> createState() => _ComprehensiveAssessmentScreenState();
}

class _ComprehensiveAssessmentScreenState extends State<ComprehensiveAssessmentScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isLoading = false;

  late List<bool?> _answers;
  late List<ComprehensiveQuestion> _questions;

  final List<String> _monsterImages = [
    'assets/images/solo_blue.png',
    'assets/images/solo_orange.png',
    'assets/images/solo_green.png',
    'assets/images/solo_teal.png',
    'assets/images/solo_pink.png',
    'assets/images/solo_yellow.png',
    'assets/images/solo_yellow_straight.png',
    'assets/images/solo_pink_up.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _questions = ComprehensiveAssessmentData.getQuestionsByCategory(widget.category);
    _answers = List.generate(_questions.length, (_) => null);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onOptionSelected(int index, bool isYes) {
    setState(() {
      _answers[index] = isYes;
    });
    
    // Automatically swipe to next question after a tiny delay for satisfaction
    if (index < _questions.length - 1) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _pageController.hasClients) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.fastOutSlowIn,
          );
        }
      });
    }
  }

  Future<void> _submitAssessment() async {
    if (_answers.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('කරුණාකර සියලුම ප්‍රශ්න වලට පිළිතුරු දෙන්න! (${_questions.length})'), 
          backgroundColor: AppColors.warmAmber
        ),
      );
      
      final firstUnanswered = _answers.indexOf(null);
      if (firstUnanswered != -1 && _pageController.hasClients) {
        _pageController.animateToPage(
          firstUnanswered, 
          duration: const Duration(milliseconds: 600), 
          curve: Curves.easeOut,
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final error = await StudentService().submitComprehensiveAssessment(
      widget.studentId,
      widget.category,
      _answers.cast<bool>(),
    );
    
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.softCoral),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('සාර්ථකව සම්පූර්ණ කරන ලදී!'), backgroundColor: AppColors.gentleGreen),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Questions not found for this category.')),
      );
    }

    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.gentleGreen))
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        _buildBackButton(context),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'ප්‍රශ්න ${_currentIndex + 1} / ${_questions.length}',
                                style: AppTypography.caption(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.calmBlue,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Stack(
                                children: [
                                  Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: AppColors.borderLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    height: 12,
                                    width: (MediaQuery.of(context).size.width - 100) * progress,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.greenGradient,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.gentleGreen.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Swipeable Cards Area
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        return _buildQuestionCard(_questions[index], index);
                      },
                    ),
                  ),

                  // Sticky Bottom Continue/Finish Button
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _answers[_currentIndex] == null ? 0.5 : 1.0,
                      child: GradientButton(
                        text: _currentIndex == _questions.length - 1 ? 'අවසන් කරන්න' : 'ඊළඟ ප්‍රශ්නය',
                        onPressed: _answers[_currentIndex] == null 
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('කරුණාකර පිළිතුරක් තෝරන්න!'), 
                                    backgroundColor: AppColors.warmAmber,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } 
                            : () {
                                if (_currentIndex < _questions.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.fastOutSlowIn,
                                  );
                                } else {
                                  _submitAssessment();
                                }
                              },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuestionCard(ComprehensiveQuestion question, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
        }
        
        return Center(
          child: Transform.scale(
            scale: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.borderBlue, width: 2),
          boxShadow: [
            const BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
            BoxShadow(
              color: AppColors.calmBlue.withValues(alpha: 0.05),
              blurRadius: 32,
              spreadRadius: 8,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxHeight < 540;
            final monsterSize = isSmall ? 110.0 : 150.0;
            final spacing = isSmall ? 16.0 : 28.0;
            final fontSize = isSmall ? 18.0 : 21.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24, vertical: isSmall ? 16 : 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MonsterCharacter(
                    size: monsterSize,
                    animation: MonsterAnimation.idle,
                    imagePath: _monsterImages[index % _monsterImages.length],
                  ),
                  
                  SizedBox(height: spacing),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      question.text,
                      textAlign: TextAlign.center,
                      style: AppTypography.heading(
                        fontSize: fontSize,
                        color: AppColors.calmBlueDark,
                      ),
                    ),
                  ),

                  SizedBox(height: spacing),

                  PressableGameButton(
                    text: 'ඔව් (Yes)',
                    icon: Icons.check_circle_outline_rounded,
                    isSelected: _answers[index] == true,
                    onTap: () => _onOptionSelected(index, true),
                    activeColor: AppColors.gentleGreen,
                  ),

                  const SizedBox(height: 14),

                  PressableGameButton(
                    text: 'නැත (No)',
                    icon: Icons.cancel_outlined,
                    isSelected: _answers[index] == false,
                    onTap: () => _onOptionSelected(index, false),
                    activeColor: AppColors.softCoral,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_currentIndex > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.fastOutSlowIn,
          );
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }
}

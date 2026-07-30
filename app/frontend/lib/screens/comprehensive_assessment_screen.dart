import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/comprehensive_assessment_questions.dart';
import '../widgets/gradient_button.dart';
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ප්‍රශ්නය ${index + 1}',
              style: AppTypography.caption(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),
            Text(
              question.text,
              style: AppTypography.body(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 40),
            _buildFormalOptionButton(
              text: 'ඔව් (Yes)',
              icon: Icons.check_circle_outline_rounded,
              isSelected: _answers[index] == true,
              activeColor: AppColors.gentleGreen,
              onTap: () => _onOptionSelected(index, true),
            ),
            const SizedBox(height: 16),
            _buildFormalOptionButton(
              text: 'නැත (No)',
              icon: Icons.cancel_outlined,
              isSelected: _answers[index] == false,
              activeColor: AppColors.softCoral,
              onTap: () => _onOptionSelected(index, false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormalOptionButton({
    required String text,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? activeColor.withValues(alpha: 0.1) : AppColors.cream,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? activeColor : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: AppTypography.body(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeColor : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: activeColor,
                  size: 20,
                ),
            ],
          ),
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

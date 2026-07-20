import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/assessment_question.dart';
import '../widgets/monster_character.dart';
import '../widgets/gradient_button.dart';
import '../widgets/flip_card_question.dart';
import '../widgets/pressable_game_button.dart';
import '../services/student_service.dart';
import 'parent_account_screen.dart';

/// Assessment Screen
/// Dyslexia-accessible: crème bg, green progress bar, warm white question card.
class AssessmentScreen extends StatefulWidget {
  final Map<String, dynamic>? studentData;

  const AssessmentScreen({super.key, this.studentData});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  // Tracking current question
  int _currentIndex = 0;
  bool _isLoading = false;

  // Track the selected answer for the CURRENT page. 
  // null = nothing selected, true = Yes, false = No.
  bool? _currentSelection;

  // Track all answers
  final List<bool> _answers = [];

  final List<AssessmentQuestion> _questions = AssessmentQuestion.allQuestions.take(10).toList();

  @override
  void dispose() {
    super.dispose();
  }

  void _onOptionSelected(bool isYes) {
    setState(() {
      _currentSelection = isYes;
    });
  }

  void _onContinue() {
    if (_currentSelection == null) return;

    if (_answers.length == _currentIndex) {
      _answers.add(_currentSelection!);
    } else {
      _answers[_currentIndex] = _currentSelection!;
    }

    if (_currentIndex < _questions.length - 1) {
      // Go to next question
      setState(() {
        _currentIndex++;
        _currentSelection = _answers.length > _currentIndex ? _answers[_currentIndex] : null;
      });
    } else {
      // Finish assessment
      _submitAssessment();
    }
  }

  Future<void> _submitAssessment() async {
    if (widget.studentData == null) {
      _navigateToResults();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final data = Map<String, dynamic>.from(widget.studentData!);
    data['assessment_results'] = _answers;

    final error = await StudentService().addStudent(data);
    
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
        SnackBar(content: const Text('student added successfully!'), backgroundColor: AppColors.gentleGreen),
      );
      _navigateToResults();
    }
  }

  void _navigateToResults() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const ParentAccountScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress (0.0 to 1.0)
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.gentleGreen))
          : SafeArea(
              child: Column(
          children: [
            // Top Bar: Back button + Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  _buildBackButton(context),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 12,
                          width: MediaQuery.of(context).size.width * 0.8 * progress,
                          decoration: BoxDecoration(
                            color: AppColors.gentleGreen,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gentleGreen.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main 3D Card and Character Area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return Flip3DTransition(animation: animation, child: child);
                },
                child: _buildQuestionPage(_questions[_currentIndex], _currentIndex),
              ),
            ),

            // Sticky Bottom Continue Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _currentSelection == null ? 0.5 : 1.0,
                child: GradientButton(
                  text: _currentIndex == _questions.length - 1 ? 'finish' : 'continue',
                  onPressed: _currentSelection == null ? () {} : _onContinue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPage(AssessmentQuestion question, int index) {
    return Padding(
      key: ValueKey<int>(index),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Quiz Master character
            const MonsterCharacter(
              size: 140,
              animation: MonsterAnimation.idle,
              imagePath: 'assets/images/quiz_master.png',
            ),
            
            const SizedBox(height: 10),

            // Question Card
            FlipCardQuestion(
              text: question.questionText,
            ),
          
          const SizedBox(height: 40),

          // YES Button
          PressableGameButton(
            text: 'yes',
            icon: Icons.check_circle_outline_rounded,
            isSelected: _currentSelection == true,
            onTap: () => _onOptionSelected(true),
            activeColor: AppColors.gentleGreen,
          ),

          const SizedBox(height: 20),

          // NO Button
          PressableGameButton(
            text: 'no',
            icon: Icons.cancel_outlined,
            isSelected: _currentSelection == false,
            onTap: () => _onOptionSelected(false),
            activeColor: AppColors.softCoral,
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_currentIndex > 0) {
          setState(() {
            _currentIndex--;
            _currentSelection = null;
          });
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

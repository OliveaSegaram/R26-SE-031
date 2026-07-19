import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/assessment_question.dart';
import '../widgets/monster_character.dart';
import '../widgets/gradient_button.dart';
import '../widgets/flip_card_question.dart';
import '../widgets/pressable_game_button.dart';
import '../services/auth_service.dart';
import 'parent_account_screen.dart';

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

    final error = await AuthService().addStudent(data);
    
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student added successfully!'), backgroundColor: Colors.green),
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
      backgroundColor: AppColors.darkSlate,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.mint))
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
                            color: AppColors.textLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 12,
                          width: MediaQuery.of(context).size.width * 0.8 * progress, // Approximation
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.mint.withValues(alpha: 0.4),
                                blurRadius: 8,
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
                  text: _currentIndex == _questions.length - 1 ? 'FINISH' : 'CONTINUE',
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
      key: ValueKey<int>(index), // Essential for AnimatedSwitcher to know it changed
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Breathing Quiz Master character
            const MonsterCharacter(
              size: 140,
              animation: MonsterAnimation.idle,
              imagePath: 'assets/images/quiz_master.png',
            ),
            
            const SizedBox(height: 10),

            // 3D Flipping Flashcard
            FlipCardQuestion(
              text: question.questionText,
            ),
          
          const SizedBox(height: 40),

          // 3D Pressable YES Button
          PressableGameButton(
            text: 'Yes',
            icon: Icons.check_circle_outline_rounded,
            isSelected: _currentSelection == true,
            onTap: () => _onOptionSelected(true),
            activeColor: AppColors.mint,
          ),

          const SizedBox(height: 20),

          // 3D Pressable NO Button
          PressableGameButton(
            text: 'No',
            icon: Icons.cancel_outlined,
            isSelected: _currentSelection == false,
            onTap: () => _onOptionSelected(false),
            activeColor: AppColors.orange,
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
            _currentSelection = null; // Normally we'd restore previous answer, but keeping it simple
          });
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.textLight.withValues(alpha: 0.08),
          ),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textLight,
          size: 22,
        ),
      ),
    );
  }
}

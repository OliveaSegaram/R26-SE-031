import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/assessment_question.dart';
import '../widgets/monster_character.dart';
import '../widgets/gradient_button.dart';
import '../widgets/flip_card_question.dart';
import '../widgets/pressable_game_button.dart';
import 'calculating_results_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  // Tracking current question
  int _currentIndex = 0;
  int _totalScore = 0;

  // Track the selected answer for the CURRENT page. 
  // null = nothing selected, true = Yes, false = No.
  bool? _currentSelection;

  final List<AssessmentQuestion> _questions = AssessmentQuestion.allQuestions;

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

    // Add score if Yes
    if (_currentSelection == true) {
      _totalScore += _questions[_currentIndex].yesWeight;
    }

    if (_currentIndex < _questions.length - 1) {
      // Go to next question
      setState(() {
        _currentIndex++;
        _currentSelection = null; // Reset selection for next question
      });
    } else {
      // Finish assessment
      _navigateToResults();
    }
  }

  void _navigateToResults() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CalculatingResultsScreen(score: _totalScore),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress (0.0 to 1.0)
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.darkSlate,
      body: SafeArea(
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

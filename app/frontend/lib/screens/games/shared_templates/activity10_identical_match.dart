import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import 'widgets/shared_game_layout.dart';

/// Activity 10: එක සමාන රූප හඳුනා ගනිමු (Identify Identical Images)
/// Template: identical_match_game
class Activity10IdenticalMatch extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  const Activity10IdenticalMatch({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Activity10IdenticalMatch> createState() => _Activity10IdenticalMatchState();
}

class _Activity10IdenticalMatchState extends State<Activity10IdenticalMatch> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _firstSelectedIndex;
  final List<int> _matchedIndices = [];
  bool _isProcessing = false;
  bool _activityComplete = false;
  int _currentRoundIndex = 0;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onCardTapped(int index, List<String> cardOptions, int totalRounds) async {
    if (_isProcessing || _matchedIndices.contains(index) || _firstSelectedIndex == index) return;

    if (_firstSelectedIndex == null) {
      // First card tapped
      setState(() {
        _firstSelectedIndex = index;
      });
    } else {
      // Second card tapped — compare!
      setState(() {
        _isProcessing = true;
      });

      final firstCardVal = cardOptions[_firstSelectedIndex!];
      final secondCardVal = cardOptions[index];

      if (firstCardVal == secondCardVal) {
        // Matched!
        await _audioPlayer.play(AssetSource('audio/correct.mp3'));
        setState(() {
          _matchedIndices.add(_firstSelectedIndex!);
          _matchedIndices.add(index);
          _firstSelectedIndex = null;
          _isProcessing = false;
        });

        // Check if all cards matched in this round
        if (_matchedIndices.length == cardOptions.length) {
          if (!mounted) return;
          context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(100);

          Future.delayed(const Duration(milliseconds: 1200), () {
            if (!mounted) return;
            if (_currentRoundIndex < totalRounds - 1) {
              setState(() {
                _currentRoundIndex++;
                _matchedIndices.clear();
                _firstSelectedIndex = null;
                _isProcessing = false;
              });
            } else {
              setState(() {
                _activityComplete = true;
              });
            }
          });
        }
      } else {
        // Mis-match
        await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _firstSelectedIndex = null;
              _isProcessing = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('එක සමාන රූප හඳුනා ගනිමු')),
        body: const Center(child: Text('No rounds available.')),
      );
    }
    
    if (rounds.length > 5) {
      rounds = rounds.sublist(0, 5);
    }

    final currentRound = rounds[_currentRoundIndex];
    final titleText = widget.activityNode?.title ?? 'එක සමාන රූප හඳුනා ගනිමු';
    final instructionText = widget.activityNode?.description ?? 'එකිනෙකට සමාන රූප යුගල වශයෙන් තෝරන්න.';
    var gridItems = (currentRound['grid_items'] as List?)?.map((e) => e.toString()).toList() ?? ['🍎', '🍌', '🍎', '🍌'];
    
    if (widget.isRemedial && gridItems.length > 4) {
      // Reduce the grid size for remedial students (e.g. from 6 to 4 items)
      // Make sure we have exactly pairs.
      final uniqueItems = gridItems.toSet().toList();
      if (uniqueItems.length > 2) {
        final allowedItems = uniqueItems.sublist(0, 2);
        gridItems = [...allowedItems, ...allowedItems];
        gridItems.shuffle();
      }
    }

    double itemSize;
    double spacing;
    double fontSize;
    final total = gridItems.length;
    final bool hasLongText = gridItems.any((opt) => opt.toString().length > 4 || opt.toString().contains(' '));

    if (total <= 2) {
      itemSize = 160.0;
      spacing = 32.0;
      fontSize = 72.0;
    } else if (total <= 4) {
      itemSize = 130.0;
      spacing = 16.0;
      fontSize = 56.0;
    } else if (total <= 6) {
      itemSize = 100.0; 
      spacing = 12.0;
      fontSize = 48.0;
    } else if (total <= 9) {
      itemSize = 80.0; 
      spacing = 10.0;
      fontSize = 40.0;
    } else {
      itemSize = 64.0; 
      spacing = 8.0;
      fontSize = 32.0;
    }

    return SharedGameLayout(
      title: titleText,
      currentRoundIndex: _currentRoundIndex,
      totalRounds: rounds.length,
      isRoundComplete: _matchedIndices.length == gridItems.length,
      isActivityComplete: _activityComplete,
      onNext: () {
        final wrapper = context.findAncestorStateOfType<TelemetryWrapperState>();
        if (wrapper != null) {
          wrapper.completeActivity(context);
        } else {
          Navigator.pop(context, 100);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            Text(
              instructionText,
              style: AppTypography.sinhala(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 64),

              // Matching Cards Grid
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      alignment: WrapAlignment.center,
                      children: List.generate(gridItems.length, (index) {
                      final isMatched = _matchedIndices.contains(index);
                      final isSelected = (_firstSelectedIndex == index);

                      return GestureDetector(
                        onTap: () => _onCardTapped(index, gridItems, rounds.length),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: hasLongText ? null : itemSize,
                          height: hasLongText ? null : itemSize,
                          padding: hasLongText ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16) : null,
                          decoration: BoxDecoration(
                            color: isMatched
                                ? AppColors.gentleGreen.withValues(alpha: 0.25)
                                : isSelected
                                    ? AppColors.warmAmber.withValues(alpha: 0.25)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isMatched
                                  ? AppColors.gentleGreen
                                  : isSelected
                                      ? AppColors.warmAmber
                                      : AppColors.borderLight,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Center(
                            child: isMatched
                                ? Icon(Icons.check_circle_rounded, color: AppColors.gentleGreen, size: fontSize)
                                : Text(gridItems[index], style: TextStyle(fontSize: hasLongText ? 24.0 : fontSize), textAlign: TextAlign.center),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
    );
  }
}

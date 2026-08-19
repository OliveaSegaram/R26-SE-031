import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/telemetry_wrapper.dart';
import '../../../../models/curriculum_models.dart';
import '../shared_templates/widgets/shared_game_layout.dart';

class Skill2Act5OddOneOut extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;

  const Skill2Act5OddOneOut({
    super.key,
    this.activityNode,
    this.isRemedial = false,
  });

  @override
  State<Skill2Act5OddOneOut> createState() => _Skill2Act5OddOneOutState();
}

class _Skill2Act5OddOneOutState extends State<Skill2Act5OddOneOut> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentRoundIndex = 0;
  bool _isRoundComplete = false;
  bool _isActivityComplete = false;
  
  late List<Map<String, dynamic>> _shuffledItems;
  Set<int> _foundIndices = {};
  int _targetCount = 0;
  
  // Track temporarily tapped incorrect items for red flash
  Set<int> _wrongIndices = {};

  // No randomized colors; we use clean, readable white/cream tiles

  @override
  void initState() {
    super.initState();
    _setupRound();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupRound() {
    final rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isNotEmpty && _currentRoundIndex < rounds.length) {
      final currentRound = rounds[_currentRoundIndex];
      
      final rawItems = currentRound['items'] as List<dynamic>? ?? [];
      final items = rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      
      // Shuffle the items for this round
      items.shuffle(Random());
      _shuffledItems = items;
      
      final targetLetter = currentRound['target_letter']?.toString();
      
      // Count targets (support both new 'is_target' boolean and old 'target_letter' string)
      _targetCount = items.where((item) {
        if (item.containsKey('is_target')) {
          return item['is_target'] == true;
        }
        return item['value'] == targetLetter;
      }).length;

    } else {
      _shuffledItems = [];
      _targetCount = 0;
    }

    _foundIndices.clear();
    _wrongIndices.clear();
    _isRoundComplete = false;
  }

  Future<void> _onItemTapped(int index) async {
    if (_isRoundComplete || _foundIndices.contains(index)) return;

    final item = _shuffledItems[index];
    final currentRound = widget.activityNode?.rounds[_currentRoundIndex] ?? {};
    final targetLetter = currentRound['target_letter']?.toString();
    
    final isCorrect = item['is_target'] == true || (item['is_target'] == null && item['value'] == targetLetter);

    if (isCorrect) {
      setState(() {
        _foundIndices.add(index);
      });
      await _audioPlayer.play(AssetSource('audio/correct.mp3'));
      
      if (_foundIndices.length == _targetCount) {
        setState(() {
          _isRoundComplete = true;
        });
        
        final rounds = widget.activityNode?.rounds ?? [];
        context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(100);

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          if (_currentRoundIndex < rounds.length - 1) {
            setState(() {
              _currentRoundIndex++;
              _setupRound();
            });
          } else {
            setState(() {
              _isActivityComplete = true;
            });
          }
        });
      }
    } else {
      setState(() {
        _wrongIndices.add(index);
      });
      await _audioPlayer.play(AssetSource('audio/wrong.mp3'));
      
      context.findAncestorStateOfType<TelemetryWrapperState>()?.completeRound(0);
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_isRoundComplete) {
          setState(() {
            _wrongIndices.remove(index);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rounds = widget.activityNode?.rounds ?? [];
    if (rounds.isEmpty || _shuffledItems.isEmpty) {
      return const Scaffold(body: Center(child: Text('No rounds available')));
    }

    final currentRound = rounds[_currentRoundIndex];
    final promptText = currentRound['prompt']?.toString() ?? 'වෙනස් රූපය සොයන්න.';
    final titleText = widget.activityNode?.title ?? 'වෙනස් රූපය සොයමු';

    return SharedGameLayout(
      title: titleText,
      currentRoundIndex: _currentRoundIndex,
      totalRounds: rounds.length,
      isRoundComplete: _isRoundComplete,
      isActivityComplete: _isActivityComplete,
      onNext: () {
        final wrapper = context.findAncestorStateOfType<TelemetryWrapperState>();
        if (wrapper != null) {
          wrapper.completeActivity(context);
        } else {
          Navigator.pop(context);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Skill 1 Style Instruction Card
            _buildInstructionCard(promptText),
            const SizedBox(height: 12),
            
            // Found Counter
            _buildFoundCounter(),
            const SizedBox(height: 32),
            
            // Giant Wooden Board with Grid of Tiles
            Expanded(
              child: Center(
                child: _buildWoodenBoard(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard(String instruction) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            context.findAncestorStateOfType<TelemetryWrapperState>()?.logAudioReplay();
            if (widget.activityNode?.audioUrl != null && widget.activityNode!.audioUrl.isNotEmpty) {
              await _audioPlayer.play(UrlSource(widget.activityNode!.audioUrl));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.warmAmber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.warmAmber, width: 3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_up_rounded, color: AppColors.warmAmber, size: 40),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    instruction,
                    style: AppTypography.sinhala(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '(නැවත ඇසීමට බොත්තම තට්ටු කරන්න)',
          style: AppTypography.sinhala(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFoundCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _foundIndices.length == _targetCount
            ? const Color(0xFF6DBE6D).withOpacity(0.15)
            : const Color(0xFFF9C623).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _foundIndices.length == _targetCount
              ? const Color(0xFF6DBE6D).withOpacity(0.3)
              : const Color(0xFFF9C623).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _foundIndices.length == _targetCount
                ? Icons.check_circle_rounded
                : Icons.search_rounded,
            color: _foundIndices.length == _targetCount
                ? const Color(0xFF6DBE6D)
                : const Color(0xFFE8A54B),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${_foundIndices.length} / $_targetCount සොයා ගත්තා',
            style: AppTypography.sinhala(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _foundIndices.length == _targetCount
                  ? const Color(0xFF4E9E4E)
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWoodenBoard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8C396), // Light warm wood inner
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFF8B5A2B), width: 10), // Thick dark wood frame
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          // Inner shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: -5,
            offset: const Offset(0, 5), // Inner top shadow to make it feel recessed
          )
        ],
      ),
      child: _buildCardGrid(),
    );
  }

  Widget _buildCardGrid() {
    final total = _shuffledItems.length;
    
    // Dynamic sizing based on items to perfectly fit the board
    double itemSize;
    double spacing;
    
    if (total <= 4) {
      itemSize = 115.0;
      spacing = 24.0;
    } else {
      itemSize = 90.0;
      spacing = 16.0;
    }

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: WrapAlignment.center,
      children: List.generate(_shuffledItems.length, (index) {
        return SizedBox(
          width: itemSize,
          height: itemSize + 8, // Allow extra height for the 3D press shadow
          child: _buildCard(index),
        );
      }),
    );
  }

  Widget _buildCard(int index) {
    final item = _shuffledItems[index];
    final isFound = _foundIndices.contains(index);
    final isWrong = _wrongIndices.contains(index);
    
    // 3D Press state
    final isPressed = isFound || isWrong;
    
    // Base colors (Clean white for readability)
    Color tileColor = Colors.white;
    Color borderColor = Colors.black.withValues(alpha: 0.1);
    Color shadowColor = const Color(0xFFD1D5DB); // Light grey shadow
    Color textColor = AppColors.textPrimary;

    if (isFound) {
      tileColor = AppColors.gentleGreen;
      borderColor = Colors.green[700]!;
      shadowColor = Colors.green[800]!;
      textColor = Colors.white;
    } else if (isWrong) {
      tileColor = AppColors.softCoral;
      borderColor = Colors.red[800]!;
      shadowColor = Colors.red[900]!;
      textColor = Colors.white;
    }

    // Dim the unselected tiles if the round is complete to focus on the correct answers
    final double tileOpacity = (_isRoundComplete && !isFound) ? 0.5 : 1.0;

    Widget content;
    if (item['type'] == 'icon') {
      content = Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset(
          item['value'], 
          fit: BoxFit.contain,
        ),
      );
    } else {
      content = Center(
        child: Text(
          item['value'],
          style: TextStyle(
            fontFamily: 'IskoolaPota',
            fontSize: _shuffledItems.length > 4 ? 44 : 54,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) {
        if (!_isRoundComplete && !_foundIndices.contains(index)) {
          // Play a tiny click sound or just let visual feedback handle it
        }
      },
      onTap: () => _onItemTapped(index),
      child: Opacity(
        opacity: tileOpacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          // When pressed, the tile moves down by adding top margin and removing bottom margin
          margin: EdgeInsets.only(
            top: isPressed ? 8.0 : 0.0,
            bottom: isPressed ? 0.0 : 8.0,
          ),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPressed ? borderColor : Colors.white.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              // The 3D bottom edge shadow
              if (!isPressed)
                BoxShadow(
                  color: shadowColor,
                  offset: const Offset(0, 8),
                  blurRadius: 0,
                ),
              // General drop shadow
              if (!isPressed)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: const Offset(0, 12),
                  blurRadius: 10,
                )
            ],
          ),
          child: AnimatedScale(
            scale: isPressed && isWrong ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: content,
          ),
        ),
      ),
    );
  }
}

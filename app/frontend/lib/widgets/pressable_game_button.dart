import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Dyslexia-accessible pressable game button.
/// Green for yes, coral for no — both on warm white unselected state.
class PressableGameButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const PressableGameButton({
    super.key,
    required this.text,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  State<PressableGameButton> createState() => _PressableGameButtonState();
}

class _PressableGameButtonState extends State<PressableGameButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected 
        ? widget.activeColor 
        : AppColors.cardSurface;
    
    final textColor = widget.isSelected 
        ? Colors.white 
        : AppColors.textPrimary;

    final borderColor = widget.isSelected
        ? widget.activeColor
        : AppColors.borderLight;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected 
                    ? widget.activeColor.withValues(alpha: 0.3) 
                    : AppColors.shadow,
                offset: widget.isSelected ? const Offset(0, 2) : const Offset(0, 4),
                blurRadius: widget.isSelected ? 10 : 4,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: textColor,
                size: 32,
              ),
              const SizedBox(width: 16),
              Text(
                widget.text,
                style: AppTypography.body(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

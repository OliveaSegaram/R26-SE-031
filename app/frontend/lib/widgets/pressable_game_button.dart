import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

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
        : AppColors.darkSlateLight;
    
    final textColor = widget.isSelected 
        ? AppColors.darkSlate 
        : AppColors.textLight;

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
            border: Border.all(
              color: widget.isSelected ? widget.activeColor : AppColors.textLight.withValues(alpha: 0.1), 
              width: 2
            ),
            boxShadow: [
              // 3D bottom shadow
              BoxShadow(
                color: widget.isSelected 
                    ? widget.activeColor.withValues(alpha: 0.4) 
                    : Colors.black.withValues(alpha: 0.5),
                offset: widget.isSelected ? const Offset(0, 2) : const Offset(0, 8),
                blurRadius: widget.isSelected ? 10 : 0,
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
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
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

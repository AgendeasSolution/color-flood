import 'package:flutter/material.dart';
import '../constants/game_constants.dart';

/// Reusable color button component for the color palette
class ColorButton extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;
  final bool isDisabled;

  const ColorButton({
    super.key,
    required this.color,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  State<ColorButton> createState() => _ColorButtonState();
}

class _ColorButtonState extends State<ColorButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (!widget.isDisabled) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    if (!widget.isDisabled) {
      widget.onTap();
    }
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate responsive button size based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth < 400 
        ? GameConstants.colorButtonSizeSmall 
        : GameConstants.colorButtonSize;
    
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 1.1 : 1.0,
        duration: GameConstants.colorButtonAnimationDuration,
        curve: Curves.fastOutSlowIn,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: widget.isDisabled 
                ? widget.color.withOpacity(0.5) 
                : widget.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.9), 
              width: GameConstants.colorButtonBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

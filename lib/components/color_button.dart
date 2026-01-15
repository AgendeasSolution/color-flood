import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import 'mahjong_icon.dart';

/// Reusable 3D gem-style color button component for the color palette
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
  void _onTapDown(TapDownDetails details) {
    // Visual feedback can be added here if needed
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.isDisabled) {
      widget.onTap();
    }
  }

  void _onTapCancel() {
    // Handle tap cancel if needed
  }

  @override
  Widget build(BuildContext context) {
    // Get responsive button size
    final buttonSize = ResponsiveUtils.getResponsiveButtonSize(context);
    final baseColor = widget.isDisabled 
        ? widget.color.withOpacity(0.5) 
        : widget.color;
    
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Outer shadow for depth
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: -2,
                offset: const Offset(0, 6),
              ),
              // Inner glow
              BoxShadow(
                color: baseColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Stack(
              children: [
                // Base gem layer with radial gradient for 3D ball effect
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.2,
                      colors: [
                        _lightenColor(baseColor, 0.2),
                        baseColor,
                        _darkenColor(baseColor, 0.25),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
                
                // Top-left bright highlight (main light source)
                Positioned(
                  top: buttonSize * 0.15,
                  left: buttonSize * 0.15,
                  width: buttonSize * 0.4,
                  height: buttonSize * 0.4,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.topLeft,
                        radius: 0.8,
                        colors: [
                          Colors.white.withOpacity(0.6),
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                
                // Secondary highlight spot (top-right)
                Positioned(
                  top: buttonSize * 0.1,
                  right: buttonSize * 0.2,
                  width: buttonSize * 0.25,
                  height: buttonSize * 0.25,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.6,
                        colors: [
                          Colors.white.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Subtle border
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                ),
                
                // Mahjong icon on top
                Center(
                  child: MahjongIcon(
                    color: Colors.white,
                    size: buttonSize * 0.7,
                    iconType: MahjongIcon.getIconTypeForColor(baseColor),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }


  Color _lightenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Color _darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../utils/responsive_utils.dart';
import 'color_button.dart';

/// Color palette component for selecting colors
class ColorPalette extends StatelessWidget {
  final List<Color> colors;
  final Function(Color) onColorSelected;
  final bool isDisabled;

  const ColorPalette({
    super.key,
    required this.colors,
    required this.onColorSelected,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 12,
      mediumPhone: 14,
      largePhone: 16,
      tablet: 20,
    );
    final spacing = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 6,
      mediumPhone: 7,
      largePhone: 8,
      tablet: 10,
    );
    
    return AnimatedOpacity(
      duration: GameConstants.colorPaletteAnimationDuration,
      opacity: isDisabled ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: isDisabled,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: padding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF60A5FA), // Light blue
                const Color(0xFF3B82F6), // Base blue
                const Color(0xFF2563EB), // Dark blue
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            border: Border.all(
              color: const Color(0xFFDBEAFE), // Light blue border
              width: 2.0,
            ),
            boxShadow: [
              // Main shadow for depth
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              // Soft outer glow
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: -2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: spacing,
            children: colors.map((color) {
              return ColorButton(
                color: color,
                onTap: () => onColorSelected(color),
                isDisabled: isDisabled,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

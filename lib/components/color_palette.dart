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
            color: Colors.white,
            borderRadius: BorderRadius.circular(60),
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

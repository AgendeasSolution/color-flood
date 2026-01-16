import 'package:flutter/material.dart';

/// Utility class for color manipulation operations
class ColorUtils {
  /// Lighten a color by a specified amount (0.0 to 1.0)
  static Color lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Darken a color by a specified amount (0.0 to 1.0)
  static Color darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Blend two colors with a ratio (0.0 to 1.0)
  static Color blendColor(Color c1, Color c2, double ratio) {
    return Color.lerp(c1, c2, ratio)!;
  }

  /// Get a random color different from the given color
  static Color getRandomDifferentColor(Color currentColor, List<Color> availableColors) {
    final differentColors = availableColors.where((color) => color != currentColor).toList();
    if (differentColors.isEmpty) {
      return availableColors.isNotEmpty ? availableColors[0] : Colors.blue;
    }
    return differentColors[differentColors.length ~/ 2]; // Return middle color for consistency
  }
}

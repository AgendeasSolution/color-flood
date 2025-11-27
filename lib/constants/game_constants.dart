import 'package:flutter/material.dart';

/// Game configuration and constants
class GameConstants {
  // Game colors used in the color flood game
  static const List<Color> gameColors = [
    Color(0xFFEF4444), // red
    Color(0xFF3B82F6), // blue
    Color(0xFF22C55E), // green
    Color(0xFFFFFF00), // yellow
    Color(0xFFFFA500), // orange
    Color(0xFFEC4899), // pink
  ];

  // Animation durations
  static const Duration popupAnimationDuration = Duration(milliseconds: 450);
  static const Duration colorButtonAnimationDuration = Duration(milliseconds: 150);
  static const Duration gameBoardAnimationDuration = Duration(milliseconds: 300);
  static const Duration colorPaletteAnimationDuration = Duration(milliseconds: 300);
  static const Duration gameOverDelay = Duration(milliseconds: 600);

  // Game configuration
  static const int baseGridSize = 5;
  static const int gridSizeIncrement = 3;
  static const int maxBailoutMoves = 5; // Increased for AI complexity
  static const int moveBufferBase = 3; // Reduced for tighter difficulty
  
  // AI Difficulty Configuration
  static const int maxGridGenerationAttempts = 5;
  static const double minColorDistributionBias = 0.3;
  static const double maxColorDistributionBias = 0.7;
  static const int minPatternComplexity = 3;
  static const int maxPatternComplexity = 7;
  static const double maxColorDominance = 0.6; // Max 60% of any single color
  
  // Level progression configuration (24 levels with rectangular grids)
  // Get grid width for a given level
  static int getGridWidth(int level) {
    if (level < 1 || level > maxLevel) return baseGridSize;
    // Calculate base size: every 3 levels, base increases by 1
    // Base starts at 5 for levels 1-3
    final groupIndex = (level - 1) ~/ 3;
    return 5 + groupIndex;
  }
  
  // Get grid height for a given level
  static int getGridHeight(int level) {
    if (level < 1 || level > maxLevel) return baseGridSize;
    // Calculate base size: every 3 levels, base increases by 1
    final groupIndex = (level - 1) ~/ 3;
    final baseSize = 5 + groupIndex;
    // Within each group of 3, height increases: base, base+1, base+2
    final positionInGroup = (level - 1) % 3;
    return baseSize + positionInGroup;
  }
  
  // Legacy support: get grid size (returns width for backward compatibility)
  static int getGridSize(int level) {
    return getGridWidth(level);
  }
  
  static const int maxLevel = 24;

  // UI configuration
  static const double gameBoardPadding = 12.0;
  static const double colorButtonSize = 48.0;
  static const double colorButtonSizeSmall = 40.0;
  static const double colorButtonBorderWidth = 3.0;
  static const double gameBoardBorderRadius = 24.0;
  static const double colorPaletteBorderRadius = 60.0;
  static const double hudCardBorderRadius = 20.0;
  static const double popupBorderRadius = 32.0;

  // Spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;
}

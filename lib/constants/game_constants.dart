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
  
  // Level progression configuration (level 1-14 only)
  static const Map<int, int> levelGridSizes = {
    1: 5,   // level 1 - 5x5
    2: 6,   // level 2 - 6x6
    3: 7,   // level 3 - 7x7
    4: 8,   // level 4 - 8x8
    5: 9,   // level 5 - 9x9
    6: 10,  // level 6 - 10x10
    7: 11,  // level 7 - 11x11
    8: 12,  // level 8 - 12x12
    9: 13,  // level 9 - 13x13
    10: 14, // level 10 - 14x14
    11: 15, // level 11 - 15x15
    12: 16, // level 12 - 16x16
    13: 17, // level 13 - 17x17
    14: 18, // level 14 - 18x18
  };
  
  static const int maxLevel = 14;

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

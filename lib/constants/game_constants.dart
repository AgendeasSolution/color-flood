import 'package:flutter/material.dart';

/// Game configuration and constants
class GameConstants {
  // Game colors used in the color flood game
  static const List<Color> gameColors = [
    Color(0xFFEF4444), // red
    Color(0xFF3B82F6), // blue
    Color(0xFF30D158), // green
    Color(0xFFFFD60A), // yellow
    Color(0xFFFF9F0A), // orange
    Color(0xFFEC4899), // pink
  ];

  // Animation durations
  static const Duration popupAnimationDuration = Duration(milliseconds: 450);
  static const Duration colorButtonAnimationDuration = Duration(milliseconds: 150);
  static const Duration gameBoardAnimationDuration = Duration(milliseconds: 300);
  static const Duration colorPaletteAnimationDuration = Duration(milliseconds: 300);
  static const Duration gameOverDelay = Duration(milliseconds: 600);

  // Game configuration
  static const int baseGridSize = 3;
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
  
  // Level progression configuration (39 levels with rectangular grids)
  // Levels 1-3: 3 columns, rows 3-5
  // Levels 4-6: 4 columns, rows 4-6
  // Levels 7-9: 5 columns, rows 5-8 (assuming 7-9 to fix overlap)
  // Levels 9-12: 6 columns, rows 6-9
  // Levels 13-16: 7 columns, rows 7-10
  // Levels 17-20: 8 columns, rows 8-11
  // Levels 21-24: 9 columns, rows 9-12
  // Levels 25-29: 10 columns, rows 10-14
  // Levels 30-34: 11 columns, rows 11-15
  // Levels 35-39: 12 columns, rows 12-16
  // Get grid width for a given level
  static int getGridWidth(int level) {
    if (level < 1 || level > maxLevel) return baseGridSize;
    
    if (level <= 3) return 3;
    if (level <= 6) return 4;
    if (level <= 8) return 5;  // Levels 7-8 (assuming 7-8 to fix overlap with 4-6)
    if (level <= 12) return 6;
    if (level <= 16) return 7;
    if (level <= 20) return 8;
    if (level <= 24) return 9;
    if (level <= 29) return 10;
    if (level <= 34) return 11;
    if (level <= 39) return 12;
    
    return 12; // Default for levels beyond 39
  }
  
  // Get grid height for a given level
  static int getGridHeight(int level) {
    if (level < 1 || level > maxLevel) return baseGridSize;
    
    // Levels 1-3: rows 3-5
    if (level == 1) return 3;
    if (level == 2) return 4;
    if (level == 3) return 5;
    
    // Levels 4-6: rows 4-6
    if (level == 4) return 4;
    if (level == 5) return 5;
    if (level == 6) return 6;
    
    // Levels 7-8: rows 5-8 (assuming 7-8 to fix overlap)
    if (level == 7) return 5;
    if (level == 8) return 8;
    
    // Levels 9-12: rows 6-9
    if (level == 9) return 6;
    if (level == 10) return 7;
    if (level == 11) return 8;
    if (level == 12) return 9;
    
    // Levels 13-16: rows 7-10
    if (level == 13) return 7;
    if (level == 14) return 8;
    if (level == 15) return 9;
    if (level == 16) return 10;
    
    // Levels 17-20: rows 8-11
    if (level == 17) return 8;
    if (level == 18) return 9;
    if (level == 19) return 10;
    if (level == 20) return 11;
    
    // Levels 21-24: rows 9-12
    if (level == 21) return 9;
    if (level == 22) return 10;
    if (level == 23) return 11;
    if (level == 24) return 12;
    
    // Levels 25-29: rows 10-14
    if (level == 25) return 10;
    if (level == 26) return 11;
    if (level == 27) return 12;
    if (level == 28) return 13;
    if (level == 29) return 14;
    
    // Levels 30-34: rows 11-15
    if (level == 30) return 11;
    if (level == 31) return 12;
    if (level == 32) return 13;
    if (level == 33) return 14;
    if (level == 34) return 15;
    
    // Levels 35-39: rows 12-16
    if (level == 35) return 12;
    if (level == 36) return 13;
    if (level == 37) return 14;
    if (level == 38) return 15;
    if (level == 39) return 16;
    
    return 16; // Default for levels beyond 39
  }
  
  // Legacy support: get grid size (returns width for backward compatibility)
  static int getGridSize(int level) {
    return getGridWidth(level);
  }
  
  static const int maxLevel = 39;

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

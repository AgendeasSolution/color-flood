import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/game_constants.dart';
import '../types/game_types.dart';
import '../services/game_service.dart';
import '../services/level_progression_service.dart';

/// Service to manage daily puzzles
class DailyPuzzleService {
  static const String _lastPuzzleDateKey = 'last_daily_puzzle_date';
  static const String _dailyPuzzleGridKey = 'daily_puzzle_grid';
  static const String _dailyPuzzleWidthKey = 'daily_puzzle_width';
  static const String _dailyPuzzleHeightKey = 'daily_puzzle_height';
  static const String _dailyPuzzleMaxMovesKey = 'daily_puzzle_max_moves';
  
  static DailyPuzzleService? _instance;
  static DailyPuzzleService get instance {
    _instance ??= DailyPuzzleService._();
    return _instance!;
  }
  
  DailyPuzzleService._();
  
  final GameService _gameService = GameService();
  final LevelProgressionService _levelService = LevelProgressionService.instance;
  
  /// Get the current date as a string (YYYY-MM-DD format)
  String _getCurrentDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  
  /// Get the grid size based on current progress
  Future<Map<String, int>> _getGridSizeForDailyPuzzle() async {
    final completedLevels = await _levelService.getCompletedLevels();
    final highestUnlocked = await _levelService.getHighestUnlockedLevel();
    
    int targetLevel;
    
    // If all levels are completed, use the last level (maxLevel)
    if (completedLevels.length >= GameConstants.maxLevel) {
      targetLevel = GameConstants.maxLevel;
    } else {
      // Use the highest unlocked level
      targetLevel = highestUnlocked;
    }
    
    // Ensure level is within valid range
    targetLevel = targetLevel.clamp(1, GameConstants.maxLevel);
    
    return {
      'width': GameConstants.getGridWidth(targetLevel),
      'height': GameConstants.getGridHeight(targetLevel),
      'level': targetLevel,
    };
  }
  
  /// Generate a daily puzzle for today
  Future<GameConfig> generateDailyPuzzle() async {
    final currentDate = _getCurrentDateString();
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastPuzzleDateKey);
    
    // Check if we already have a puzzle for today
    if (lastDate == currentDate) {
      final savedGridString = prefs.getString(_dailyPuzzleGridKey);
      final savedWidth = prefs.getInt(_dailyPuzzleWidthKey);
      final savedHeight = prefs.getInt(_dailyPuzzleHeightKey);
      final savedMaxMoves = prefs.getInt(_dailyPuzzleMaxMovesKey);
      
      if (savedGridString != null && 
          savedWidth != null && 
          savedHeight != null &&
          savedMaxMoves != null) {
        // Check if the saved puzzle's grid size matches the current highest unlocked level
        final currentGridSize = await _getGridSizeForDailyPuzzle();
        final currentWidth = currentGridSize['width']!;
        final currentHeight = currentGridSize['height']!;
        
        // If grid size matches, restore saved puzzle
        if (savedWidth == currentWidth && savedHeight == currentHeight) {
          final grid = _parseGridFromString(savedGridString, savedWidth, savedHeight);
          if (grid.isNotEmpty) {
            return GameConfig(
              level: 0, // Special level 0 for daily puzzle
              gridWidth: savedWidth,
              gridHeight: savedHeight,
              maxMoves: savedMaxMoves,
              grid: grid,
              originalGrid: _gameService.cloneGrid(grid),
            );
          }
        }
        // If grid size doesn't match, fall through to regenerate with correct size
      }
    }
    
    // Generate new puzzle for today
    final gridSize = await _getGridSizeForDailyPuzzle();
    final gridWidth = gridSize['width']!;
    final gridHeight = gridSize['height']!;
    final baseLevel = gridSize['level']!;
    
    // Generate a puzzle with similar difficulty to the base level
    // Use a seed based on the current date for consistent daily puzzles
    final dateSeed = _getDateSeed(currentDate);
    final random = Random(dateSeed);
    
    // Generate grid with seeded random for consistency
    final grid = _generateSeededGrid(gridWidth, gridHeight, baseLevel, random);
    
    // Calculate optimal solution to determine max moves
    final optimalMoves = _gameService.calculateOptimalSolution(grid);
    final maxMoves = optimalMoves > 0 
        ? optimalMoves + 3 // Add buffer for daily puzzle
        : (gridWidth * gridHeight) ~/ 2; // Fallback calculation
    
    // Save the puzzle for today
    await prefs.setString(_lastPuzzleDateKey, currentDate);
    await prefs.setString(_dailyPuzzleGridKey, _gridToString(grid));
    await prefs.setInt(_dailyPuzzleWidthKey, gridWidth);
    await prefs.setInt(_dailyPuzzleHeightKey, gridHeight);
    await prefs.setInt(_dailyPuzzleMaxMovesKey, maxMoves);
    
    return GameConfig(
      level: 0, // Special level 0 for daily puzzle
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      maxMoves: maxMoves,
      grid: grid,
      originalGrid: _gameService.cloneGrid(grid),
    );
  }
  
  /// Get a seed value from the date string
  int _getDateSeed(String dateString) {
    int seed = 0;
    for (int i = 0; i < dateString.length; i++) {
      seed = seed * 31 + dateString.codeUnitAt(i);
    }
    return seed;
  }
  
  /// Generate a grid with seeded random for daily puzzles
  List<List<Color>> _generateSeededGrid(int gridWidth, int gridHeight, int level, Random random) {
    // Start with a random grid
    final grid = List.generate(
      gridHeight,
      (_) => List.generate(
        gridWidth,
        (_) => GameConstants.gameColors[random.nextInt(GameConstants.gameColors.length)],
      ),
    );
    
    // Shuffle the grid
    for (int pass = 0; pass < 3; pass++) {
      for (int i = 0; i < gridHeight; i++) {
        for (int j = 0; j < gridWidth; j++) {
          final swapI = random.nextInt(gridHeight);
          final swapJ = random.nextInt(gridWidth);
          final temp = grid[i][j];
          grid[i][j] = grid[swapI][swapJ];
          grid[swapI][swapJ] = temp;
        }
      }
    }
    
    // Ensure equal color distribution
    _ensureEqualColorDistribution(grid, gridWidth, gridHeight);
    
    // Prevent four adjacent same colors
    _preventFourAdjacentCells(grid, gridWidth, gridHeight, random);
    
    // Final equal distribution pass
    _ensureEqualColorDistribution(grid, gridWidth, gridHeight);
    
    return grid;
  }
  
  /// Ensure equal color distribution
  void _ensureEqualColorDistribution(List<List<Color>> grid, int gridWidth, int gridHeight) {
    final totalCells = gridWidth * gridHeight;
    final numColors = GameConstants.gameColors.length;
    final targetCount = totalCells / numColors;
    
    // Count current color distribution
    final colorCounts = <Color, int>{};
    for (final color in GameConstants.gameColors) {
      colorCounts[color] = 0;
    }
    
    for (final row in grid) {
      for (final color in row) {
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // Adjust colors to be more evenly distributed
    final cells = <List<int>>[];
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        cells.add([i, j]);
      }
    }
    
    // Shuffle cells for random replacement
    cells.shuffle();
    
    for (final cell in cells) {
      final i = cell[0];
      final j = cell[1];
      final currentColor = grid[i][j];
      final currentCount = colorCounts[currentColor] ?? 0;
      
      if (currentCount > targetCount + 1) {
        // Find a color that needs more cells
        Color? targetColor;
        int minCount = totalCells;
        
        for (final color in GameConstants.gameColors) {
          final count = colorCounts[color] ?? 0;
          if (count < minCount && color != currentColor) {
            minCount = count;
            targetColor = color;
          }
        }
        
        if (targetColor != null) {
          grid[i][j] = targetColor;
          colorCounts[currentColor] = currentCount - 1;
          colorCounts[targetColor] = (colorCounts[targetColor] ?? 0) + 1;
        }
      }
    }
  }
  
  /// Prevent four adjacent cells of the same color
  void _preventFourAdjacentCells(List<List<Color>> grid, int gridWidth, int gridHeight, Random random) {
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        final currentColor = grid[i][j];
        
        // Check horizontal
        if (j < gridWidth - 3) {
          if (grid[i][j + 1] == currentColor &&
              grid[i][j + 2] == currentColor &&
              grid[i][j + 3] == currentColor) {
            // Change one of them
            final newColor = _getRandomDifferentColor(currentColor, random);
            grid[i][j + 2] = newColor;
          }
        }
        
        // Check vertical
        if (i < gridHeight - 3) {
          if (grid[i + 1][j] == currentColor &&
              grid[i + 2][j] == currentColor &&
              grid[i + 3][j] == currentColor) {
            // Change one of them
            final newColor = _getRandomDifferentColor(currentColor, random);
            grid[i + 2][j] = newColor;
          }
        }
      }
    }
  }
  
  /// Get a random color different from the given color
  Color _getRandomDifferentColor(Color color, Random random) {
    final availableColors = GameConstants.gameColors
        .where((c) => c != color)
        .toList();
    if (availableColors.isEmpty) {
      return GameConstants.gameColors[0];
    }
    return availableColors[random.nextInt(availableColors.length)];
  }
  
  /// Convert grid to string for storage
  String _gridToString(List<List<Color>> grid) {
    final buffer = StringBuffer();
    for (final row in grid) {
      for (final color in row) {
        buffer.write('${color.value},');
      }
    }
    return buffer.toString();
  }
  
  /// Parse grid from string
  List<List<Color>> _parseGridFromString(String gridString, int width, int height) {
    try {
      final values = gridString.split(',').where((s) => s.isNotEmpty).toList();
      if (values.length != width * height) {
        return [];
      }
      
      final grid = <List<Color>>[];
      for (int i = 0; i < height; i++) {
        final row = <Color>[];
        for (int j = 0; j < width; j++) {
          final index = i * width + j;
          final colorValue = int.parse(values[index]);
          row.add(Color(colorValue));
        }
        grid.add(row);
      }
      return grid;
    } catch (e) {
      return [];
    }
  }
  
  /// Get today's puzzle (cached or generated)
  Future<GameConfig> getTodaysPuzzle() async {
    return await generateDailyPuzzle();
  }
  
  /// Check if today's puzzle has been completed
  Future<bool> isTodaysPuzzleCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final currentDate = _getCurrentDateString();
    final lastDate = prefs.getString(_lastPuzzleDateKey);
    
    if (lastDate != currentDate) {
      return false; // New day, puzzle not completed yet
    }
    
    return prefs.getBool('daily_puzzle_completed_$currentDate') ?? false;
  }
  
  /// Mark today's puzzle as completed
  Future<void> markTodaysPuzzleCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final currentDate = _getCurrentDateString();
    await prefs.setBool('daily_puzzle_completed_$currentDate', true);
  }
}


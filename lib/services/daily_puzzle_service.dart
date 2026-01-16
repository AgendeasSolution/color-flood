import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/game_constants.dart';
import '../types/game_types.dart';
import '../services/game_service.dart';
import '../services/level_progression_service.dart';

/// Service to manage daily puzzles
class DailyPuzzleService {
  // Old keys (for puzzle generation)
  static const String _lastPuzzleDateKey = 'last_daily_puzzle_date';
  static const String _dailyPuzzleGridKey = 'daily_puzzle_grid';
  static const String _dailyPuzzleWidthKey = 'daily_puzzle_width';
  static const String _dailyPuzzleHeightKey = 'daily_puzzle_height';
  static const String _dailyPuzzleMaxMovesKey = 'daily_puzzle_max_moves';
  
  // New storage keys for streak system
  static const String _dailyPuzzleDateKey = 'daily_puzzle_date';
  static const String _dailyPuzzleCompletedKey = 'daily_puzzle_completed';
  static const String _dailyPuzzleHistoryKey = 'daily_puzzle_history';
  static const String _bestStreakKey = 'best_streak';
  
  static DailyPuzzleService? _instance;
  static DailyPuzzleService get instance {
    _instance ??= DailyPuzzleService._();
    return _instance!;
  }
  
  DailyPuzzleService._();
  
  final GameService _gameService = GameService();
  final LevelProgressionService _levelService = LevelProgressionService.instance;
  
  /// Get the current date as a string (YYYY-M-D format - no padding)
  String _getCurrentDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
  
  /// Convert DateTime to date key string (YYYY-M-D format)
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
  
  /// Parse date key string to DateTime
  DateTime? _keyToDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length != 3) return null;
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (e) {
      return null;
    }
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
    // Add additional randomization factors to ensure uniqueness from regular levels
    final dateSeed = _getDateSeed(currentDate);
    // Add grid dimensions and level to seed to ensure different patterns
    final enhancedSeed = dateSeed ^ (gridWidth * 1000) ^ (gridHeight * 100) ^ (baseLevel * 10);
    final random = Random(enhancedSeed);
    
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
  /// This ensures the daily puzzle is completely random and different from regular levels
  List<List<Color>> _generateSeededGrid(int gridWidth, int gridHeight, int level, Random random) {
    // Use multiple randomization passes to ensure uniqueness
    // Start with a completely random grid
    final grid = List.generate(
      gridHeight,
      (_) => List.generate(
        gridWidth,
        (_) => GameConstants.gameColors[random.nextInt(GameConstants.gameColors.length)],
      ),
    );
    
    // Enhanced shuffling with more passes for better randomization
    for (int pass = 0; pass < 5; pass++) {
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
    
    // Additional randomization: randomly swap colors in different patterns
    for (int i = 0; i < gridWidth * gridHeight * 2; i++) {
      final row1 = random.nextInt(gridHeight);
      final col1 = random.nextInt(gridWidth);
      final row2 = random.nextInt(gridHeight);
      final col2 = random.nextInt(gridWidth);
      
      final temp = grid[row1][col1];
      grid[row1][col1] = grid[row2][col2];
      grid[row2][col2] = temp;
    }
    
    // Ensure equal color distribution
    _ensureEqualColorDistribution(grid, gridWidth, gridHeight);
    
    // Prevent four adjacent same colors
    _preventFourAdjacentCells(grid, gridWidth, gridHeight, random);
    
    // Additional randomization pass after pattern prevention
    for (int i = 0; i < gridWidth * gridHeight; i++) {
      final row1 = random.nextInt(gridHeight);
      final col1 = random.nextInt(gridWidth);
      final row2 = random.nextInt(gridHeight);
      final col2 = random.nextInt(gridWidth);
      
      // Only swap if colors are different to maintain distribution
      if (grid[row1][col1] != grid[row2][col2]) {
        final temp = grid[row1][col1];
        grid[row1][col1] = grid[row2][col2];
        grid[row2][col2] = temp;
      }
    }
    
    // Final equal distribution pass
    _ensureEqualColorDistribution(grid, gridWidth, gridHeight);
    
    // Final shuffle to ensure complete randomness
    for (int pass = 0; pass < 2; pass++) {
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
  
  // ========== Daily Puzzle Availability ==========
  
  /// Returns true if daily puzzle is available (no date saved, different date, or today but not completed)
  Future<bool> isDailyPuzzleAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentDate = _getCurrentDateString();
      final savedDate = prefs.getString(_dailyPuzzleDateKey);
      
      // No date saved - available
      if (savedDate == null) {
        return true;
      }
      
      // Date is different from today - available
      if (savedDate != currentDate) {
        // Reset completion status for new day
        await prefs.setBool(_dailyPuzzleCompletedKey, false);
        return true;
      }
      
      // It's today but not completed - available
      final isCompleted = prefs.getBool(_dailyPuzzleCompletedKey) ?? false;
      return !isCompleted;
    } catch (e) {
      return true; // Default to available on error
    }
  }
  
  // ========== Starting a Daily Puzzle ==========
  
  /// Marks the puzzle as started by saving today's date key
  Future<void> startDailyPuzzle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentDate = _getCurrentDateString();
      await prefs.setString(_dailyPuzzleDateKey, currentDate);
    } catch (e) {
      // Silently handle errors
    }
  }
  
  // ========== Completion Tracking ==========
  
  /// Returns true only if it's today's puzzle AND it's marked as completed
  Future<bool> isDailyPuzzleCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentDate = _getCurrentDateString();
      final savedDate = prefs.getString(_dailyPuzzleDateKey);
      
      // Not today's puzzle
      if (savedDate != currentDate) {
        return false;
      }
      
      // Check completion flag
      return prefs.getBool(_dailyPuzzleCompletedKey) ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Marks today's puzzle as completed
  Future<void> completeDailyPuzzle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentDate = _getCurrentDateString();
      
      // Save today's date
      await prefs.setString(_dailyPuzzleDateKey, currentDate);
      
      // Set completion flag to true
      await prefs.setBool(_dailyPuzzleCompletedKey, true);
      
      // Add date to history
      await _addDateToHistory(currentDate);
      
      // Update best streak if current streak is higher
      final currentStreak = await getCompletionStreak();
      await updateBestStreak(currentStreak);
    } catch (e) {
      // Silently handle errors
    }
  }
  
  /// Marks a specific date as completed (adds to history, only updates flags/best streak if it's today)
  Future<void> completeDailyPuzzleForDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = _dateToKey(date);
      final currentDate = _getCurrentDateString();
      
      // Add to history
      await _addDateToHistory(dateKey);
      
      // Only update flags/best streak if it's today's puzzle
      if (dateKey == currentDate) {
        await prefs.setString(_dailyPuzzleDateKey, currentDate);
        await prefs.setBool(_dailyPuzzleCompletedKey, true);
        
        final currentStreak = await getCompletionStreak();
        await updateBestStreak(currentStreak);
      }
    } catch (e) {
      // Silently handle errors
    }
  }
  
  /// Helper to add a date to history
  Future<void> _addDateToHistory(String dateKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString(_dailyPuzzleHistoryKey) ?? '';
      final historySet = historyString.isEmpty 
          ? <String>{}
          : historyString.split(',').where((s) => s.isNotEmpty).toSet();
      
      historySet.add(dateKey);
      
      await prefs.setString(_dailyPuzzleHistoryKey, historySet.join(','));
    } catch (e) {
      // Silently handle errors
    }
  }
  
  // ========== Completion History ==========
  
  /// Returns a Set of all completed date keys (format: 'YYYY-M-D')
  Future<Set<String>> getCompletedDailyPuzzleDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString(_dailyPuzzleHistoryKey) ?? '';
      
      if (historyString.isEmpty) {
        return <String>{};
      }
      
      return historyString.split(',').where((s) => s.isNotEmpty).toSet();
    } catch (e) {
      return <String>{};
    }
  }
  
  /// Checks if a specific date was completed
  Future<bool> isDateCompleted(String dateKey) async {
    try {
      final completedDates = await getCompletedDailyPuzzleDates();
      return completedDates.contains(dateKey);
    } catch (e) {
      return false;
    }
  }
  
  // ========== Streak System ==========
  
  /// Counts consecutive days from today backwards
  /// Returns 0 if today is not completed (streak broken)
  /// Maximum check: 365 days
  Future<int> getCompletionStreak() async {
    try {
      final completedDates = await getCompletedDailyPuzzleDates();
      if (completedDates.isEmpty) {
        return 0;
      }
      
      final today = DateTime.now();
      final todayKey = _getCurrentDateString();
      
      // If today is not completed, streak is 0
      if (!completedDates.contains(todayKey)) {
        return 0;
      }
      
      // Count backwards day by day
      int streak = 0;
      DateTime checkDate = today;
      
      for (int i = 0; i < 365; i++) {
        final dateKey = _dateToKey(checkDate);
        
        if (completedDates.contains(dateKey)) {
          streak++;
        } else {
          // Stop at first missing day
          break;
        }
        
        // Move to previous day
        checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
      }
      
      return streak;
    } catch (e) {
      return 0;
    }
  }
  
  /// Returns the highest streak ever achieved
  Future<int> getBestStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_bestStreakKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Updates best streak only if current streak > best streak
  Future<void> updateBestStreak(int currentStreak) async {
    try {
      final bestStreak = await getBestStreak();
      if (currentStreak > bestStreak) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_bestStreakKey, currentStreak);
      }
    } catch (e) {
      // Silently handle errors
    }
  }
  
  // ========== Total Completions ==========
  
  /// Returns the total count of completed daily puzzles
  Future<int> getTotalCompleted() async {
    try {
      final completedDates = await getCompletedDailyPuzzleDates();
      return completedDates.length;
    } catch (e) {
      return 0;
    }
  }
  
  // ========== Legacy Methods (for backward compatibility) ==========
  
  /// Check if today's puzzle has been completed (legacy method)
  Future<bool> isTodaysPuzzleCompleted() async {
    return await isDailyPuzzleCompleted();
  }
  
  /// Mark today's puzzle as completed (legacy method)
  Future<void> markTodaysPuzzleCompleted() async {
    await completeDailyPuzzle();
  }
}


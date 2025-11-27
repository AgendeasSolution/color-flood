import 'dart:collection';
import 'dart:math' as math;
import 'dart:math' show Random, Point;
import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../types/game_types.dart';

/// Service class to handle all game logic
class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  /// Clone a grid to create a deep copy
  List<List<Color>> cloneGrid(List<List<Color>> gridToClone) {
    return gridToClone.map((row) => List<Color>.from(row)).toList();
  }

  /// Check if the grid is solved (all cells have the same color)
  bool isGridSolved(List<List<Color>> gridToCheck) {
    if (gridToCheck.isEmpty) return false;
    if (gridToCheck[0].isEmpty) return false;
    try {
      final firstColor = gridToCheck[0][0];
      for (var row in gridToCheck) {
        if (row.isEmpty) return false;
        for (var cellColor in row) {
          if (cellColor != firstColor) return false;
        }
      }
      return true;
    } catch (e) {
      // If any error occurs, consider grid as not solved
      return false;
    }
  }

  /// Perform flood fill on the grid
  List<List<Color>> floodFillOnGrid(
    List<List<Color>> gridData,
    int startX,
    int startY,
    Color replacementColor,
  ) {
    // Validate bounds
    if (gridData.isEmpty) return gridData;
    if (startX < 0 || startX >= gridData.length) return gridData;
    if (gridData[startX].isEmpty) return gridData;
    if (startY < 0 || startY >= gridData[startX].length) return gridData;
    
    final targetColor = gridData[startX][startY];
    if (targetColor == replacementColor) return gridData;

    try {
      final filledGrid = cloneGrid(gridData);
      final queue = Queue<Point<int>>();
      queue.add(Point(startX, startY));

      final visited = <Point<int>>{Point(startX, startY)};

      while (queue.isNotEmpty) {
        final point = queue.removeFirst();
        final x = point.x;
        final y = point.y;

        // Validate bounds before accessing
        if (x < 0 || x >= filledGrid.length) continue;
        if (y < 0 || y >= filledGrid[x].length) continue;
        
        if (filledGrid[x][y] == targetColor) {
          filledGrid[x][y] = replacementColor;

          final neighbors = [
            Point(x + 1, y),
            Point(x - 1, y),
            Point(x, y + 1),
            Point(x, y - 1),
          ];

          for (final neighbor in neighbors) {
            final nx = neighbor.x;
            final ny = neighbor.y;
            if (nx >= 0 &&
                nx < filledGrid.length &&
                ny >= 0 &&
                ny < filledGrid[nx].length &&
                !visited.contains(neighbor) &&
                filledGrid[nx][ny] == targetColor) {
              visited.add(neighbor);
              queue.add(neighbor);
            }
          }
        }
      }
      return filledGrid;
    } catch (e) {
      // If any error occurs, return original grid
      return gridData;
    }
  }

  /// Count the current area size starting from top-left corner
  int countCurrentArea(List<List<Color>> gridData) {
    if (gridData.isEmpty) return 0;
    if (gridData[0].isEmpty) return 0;
    
    try {
      final targetColor = gridData[0][0];
      final queue = Queue<Point<int>>();
      queue.add(const Point(0, 0));
      final visited = <Point<int>>{const Point(0, 0)};
      int count = 0;

      while (queue.isNotEmpty) {
        final point = queue.removeFirst();
        count++;
        final neighbors = [
          Point(point.x + 1, point.y),
          Point(point.x - 1, point.y),
          Point(point.x, point.y + 1),
          Point(point.x, point.y - 1),
        ];
        for (final neighbor in neighbors) {
          if (neighbor.x >= 0 &&
              neighbor.x < gridData.length &&
              neighbor.y >= 0 &&
              neighbor.y < gridData[neighbor.x].length &&
              !visited.contains(neighbor) &&
              gridData[neighbor.x][neighbor.y] == targetColor) {
            visited.add(neighbor);
            queue.add(neighbor);
          }
        }
      }
      return count;
    } catch (e) {
      // If any error occurs, return safe default
      return 0;
    }
  }

  /// Find the best move for the current grid state using advanced AI strategies
  Color findBestMove(List<List<Color>> gridToAnalyze) {
    if (gridToAnalyze.isEmpty || 
        gridToAnalyze[0].isEmpty || 
        GameConstants.gameColors.isEmpty) {
      // Return first available color as fallback
      return GameConstants.gameColors.isNotEmpty 
          ? GameConstants.gameColors[0] 
          : Colors.blue;
    }
    
    try {
      Color? bestColor;
      double bestScore = -1.0;
      final startColor = gridToAnalyze[0][0];

      for (final color in GameConstants.gameColors) {
        if (color == startColor) continue;
        
        try {
          final simulatedGrid = floodFillOnGrid(gridToAnalyze, 0, 0, color);
          final score = _calculateMoveScore(gridToAnalyze, simulatedGrid, color);
          
          if (score > bestScore) {
            bestScore = score;
            bestColor = color;
          }
        } catch (e) {
          // Skip this color if it causes an error
          continue;
        }
      }
      
      // Return best color or fallback to first available color
      return bestColor ?? 
             (GameConstants.gameColors.where((c) => c != startColor).isNotEmpty
                 ? GameConstants.gameColors.where((c) => c != startColor).first
                 : GameConstants.gameColors[0]);
    } catch (e) {
      // Fallback to first available color
      return GameConstants.gameColors.isNotEmpty 
          ? GameConstants.gameColors[0] 
          : Colors.blue;
    }
  }

  /// Calculate a sophisticated score for a potential move
  double _calculateMoveScore(List<List<Color>> originalGrid, List<List<Color>> newGrid, Color moveColor) {
    final gridHeight = originalGrid.length;
    final gridWidth = originalGrid.isNotEmpty ? originalGrid[0].length : 0;
    final totalCells = gridWidth * gridHeight;
    
    // Base score: area gained
    final areaGained = countCurrentArea(newGrid) - countCurrentArea(originalGrid);
    final areaScore = areaGained / totalCells;
    
    // Strategic score: color distribution analysis
    final colorDistributionScore = _analyzeColorDistribution(newGrid, moveColor);
    
    // Connectivity score: how well connected the new area is
    final connectivityScore = _analyzeConnectivity(newGrid);
    
    // Future potential score: lookahead analysis
    final futurePotentialScore = _analyzeFuturePotential(newGrid, moveColor);
    
    // Anti-pattern penalty: avoid moves that create easy solutions
    final antiPatternPenalty = _calculateAntiPatternPenalty(originalGrid, newGrid, moveColor);
    
    // Weighted combination of all factors
    return (areaScore * 0.4) + 
           (colorDistributionScore * 0.25) + 
           (connectivityScore * 0.15) + 
           (futurePotentialScore * 0.15) - 
           (antiPatternPenalty * 0.05);
  }

  /// Analyze color distribution for strategic value
  double _analyzeColorDistribution(List<List<Color>> grid, Color moveColor) {
    final colorCounts = <Color, int>{};
    final gridHeight = grid.length;
    final gridWidth = grid.isNotEmpty ? grid[0].length : 0;
    
    // Count all colors in the grid
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        final color = grid[i][j];
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // Calculate distribution entropy (higher is better for difficulty)
    double entropy = 0.0;
    final totalCells = gridWidth * gridHeight;
    
    for (final count in colorCounts.values) {
      if (count > 0) {
        final probability = count / totalCells;
        entropy -= probability * (probability > 0 ? math.log(probability) / math.ln2 : 0);
      }
    }
    
    // Normalize entropy (0-1 scale)
    final maxEntropy = math.log(GameConstants.gameColors.length) / math.ln2;
    return entropy / maxEntropy;
  }

  /// Analyze connectivity of the current area
  double _analyzeConnectivity(List<List<Color>> grid) {
    final currentArea = countCurrentArea(grid);
    final gridHeight = grid.length;
    final gridWidth = grid.isNotEmpty ? grid[0].length : 0;
    final totalCells = gridWidth * gridHeight;
    
    // More connected areas are generally better for strategic play
    return currentArea / totalCells;
  }

  /// Analyze future potential of the move
  double _analyzeFuturePotential(List<List<Color>> grid, Color moveColor) {
    // Look ahead 2 moves to see potential
    double maxFutureArea = 0.0;
    final startColor = grid[0][0];
    
    for (final nextColor in GameConstants.gameColors) {
      if (nextColor == startColor) continue;
      
      final nextGrid = floodFillOnGrid(grid, 0, 0, nextColor);
      final nextArea = countCurrentArea(nextGrid);
      
      if (nextArea > maxFutureArea) {
        maxFutureArea = nextArea.toDouble();
      }
    }
    
    final gridHeight = grid.length;
    final gridWidth = grid.isNotEmpty ? grid[0].length : 0;
    final totalCells = gridWidth * gridHeight;
    return maxFutureArea / totalCells;
  }

  /// Calculate anti-pattern penalty to avoid easy solutions
  double _calculateAntiPatternPenalty(List<List<Color>> originalGrid, List<List<Color>> newGrid, Color moveColor) {
    double penalty = 0.0;
    final gridHeight = originalGrid.length;
    final gridWidth = originalGrid.isNotEmpty ? originalGrid[0].length : 0;
    
    // Penalty for creating large uniform blocks
    final newAreaSize = countCurrentArea(newGrid);
    final totalCells = gridWidth * gridHeight;
    
    if (newAreaSize > totalCells * 0.7) {
      penalty += 0.3; // Heavy penalty for too large areas
    }
    
    // Penalty for creating obvious next moves
    final remainingColors = <Color>{};
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        if (newGrid[i][j] != newGrid[0][0]) {
          remainingColors.add(newGrid[i][j]);
        }
      }
    }
    
    if (remainingColors.length <= 2) {
      penalty += 0.2; // Penalty for too few remaining colors
    }
    
    return penalty;
  }

  /// Generate an intelligent grid for the given level with challenging patterns
  List<List<Color>> generateRandomGrid(int level) {
    final random = Random();
    final gridWidth = GameConstants.getGridWidth(level);
    final gridHeight = GameConstants.getGridHeight(level);
    
    // Use intelligent generation for higher levels
    if (level >= 3) {
      return _generateIntelligentGrid(gridWidth, gridHeight, level, random);
    }
    
    // Simple random generation for early levels with proper shuffling
    final grid = List.generate(
      gridHeight,
      (_) => List.generate(
        gridWidth,
        (_) => GameConstants.gameColors[random.nextInt(GameConstants.gameColors.length)],
      ),
    );
    
    // Shuffle to ensure proper randomization
    _shuffleGrid(grid, gridWidth, gridHeight, random);
    
    return grid;
  }

  /// Generate an intelligent grid with challenging patterns - MUCH HARDER
  List<List<Color>> _generateIntelligentGrid(int gridWidth, int gridHeight, int level, Random random) {
    // Start with a completely random grid for proper shuffling
    final grid = List.generate(
      gridHeight,
      (_) => List.generate(
        gridWidth,
        (_) => GameConstants.gameColors[random.nextInt(GameConstants.gameColors.length)],
      ),
    );
    
    // Shuffle the grid multiple times to ensure proper randomization
    _shuffleGrid(grid, gridWidth, gridHeight, random);
    
    // Calculate difficulty parameters based on level - MUCH HARDER
    final difficultyMultiplier = (level - 1) / (GameConstants.maxLevel - 1);
    final patternComplexity = (5 + (difficultyMultiplier * 6)).round(); // 5-11 patterns (more complex)
    final colorDistributionBias = 0.1 + (difficultyMultiplier * 0.2); // 0.1-0.3 bias (more scattered)
    
    // Generate challenging patterns
    _createStrategicPatterns(grid, gridWidth, gridHeight, patternComplexity, colorDistributionBias, random);
    
    // Add MORE strategic noise to make it harder
    _addStrategicNoise(grid, gridWidth, gridHeight, level, random);
    
    // Ensure the grid is solvable but challenging
    _optimizeForDifficulty(grid, gridWidth, gridHeight, level);
    
    // Additional difficulty pass
    _addExtraDifficulty(grid, gridWidth, gridHeight, level, random);
    
    // Final shuffle to ensure randomness
    _shuffleGrid(grid, gridWidth, gridHeight, random);
    
    return grid;
  }
  
  /// Properly shuffle the grid to ensure randomness
  void _shuffleGrid(List<List<Color>> grid, int gridWidth, int gridHeight, Random random) {
    // Multiple shuffle passes for better randomization
    for (int pass = 0; pass < 3; pass++) {
      // Shuffle by swapping random cells
      for (int i = 0; i < gridHeight; i++) {
        for (int j = 0; j < gridWidth; j++) {
          // Randomly swap with another cell
          final swapI = random.nextInt(gridHeight);
          final swapJ = random.nextInt(gridWidth);
          
          final temp = grid[i][j];
          grid[i][j] = grid[swapI][swapJ];
          grid[swapI][swapJ] = temp;
        }
      }
    }
    
    // Additional pass: randomly change some cells
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        if (random.nextDouble() < 0.3) { // 30% chance to change
          grid[i][j] = GameConstants.gameColors[random.nextInt(GameConstants.gameColors.length)];
        }
      }
    }
  }

  /// Add extra difficulty to make the game much harder
  void _addExtraDifficulty(List<List<Color>> grid, int gridWidth, int gridHeight, int level, Random random) {
    // Create more isolated single cells
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        if (random.nextDouble() < 0.3) { // 30% chance to create isolated cells
          final currentColor = grid[i][j];
          final newColor = _getRandomDifferentColor(currentColor);
          grid[i][j] = newColor;
        }
      }
    }
    
    // Ensure maximum color diversity
    _ensureMaximumColorDiversity(grid, gridWidth, gridHeight);
  }

  /// Ensure maximum color diversity in the grid
  void _ensureMaximumColorDiversity(List<List<Color>> grid, int gridWidth, int gridHeight) {
    final colorCounts = <Color, int>{};
    final totalCells = gridWidth * gridHeight;
    final maxColorCount = (totalCells / GameConstants.gameColors.length * 1.5).round();
    
    // Count colors
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        final color = grid[i][j];
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // Redistribute excess colors
    for (final entry in colorCounts.entries) {
      if (entry.value > maxColorCount) {
        _redistributeColor(grid, gridWidth, gridHeight, entry.key, entry.value - maxColorCount);
      }
    }
  }

  /// Create strategic patterns that make the game more challenging
  void _createStrategicPatterns(List<List<Color>> grid, int gridWidth, int gridHeight, int patternCount, double bias, Random random) {
    final colors = List<Color>.from(GameConstants.gameColors);
    colors.shuffle(random);
    
    for (int pattern = 0; pattern < patternCount; pattern++) {
      final color = colors[pattern % colors.length];
      final patternType = random.nextInt(4);
      
      switch (patternType) {
        case 0:
          _createIslandPattern(grid, gridWidth, gridHeight, color, random);
          break;
        case 1:
          _createCorridorPattern(grid, gridWidth, gridHeight, color, random);
          break;
        case 2:
          _createSpiralPattern(grid, gridWidth, gridHeight, color, random);
          break;
        case 3:
          _createCheckerboardPattern(grid, gridWidth, gridHeight, color, random);
          break;
      }
    }
  }

  /// Create isolated island patterns
  void _createIslandPattern(List<List<Color>> grid, int gridWidth, int gridHeight, Color color, Random random) {
    final centerX = random.nextInt(gridHeight);
    final centerY = random.nextInt(gridWidth);
    final maxRadius = math.min(gridWidth, gridHeight);
    final radius = 1 + random.nextInt((maxRadius / 3).round());
    
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        final distance = math.sqrt(math.pow(i - centerX, 2) + math.pow(j - centerY, 2));
        if (distance <= radius && random.nextDouble() < 0.8) {
          grid[i][j] = color;
        }
      }
    }
  }

  /// Create corridor patterns
  void _createCorridorPattern(List<List<Color>> grid, int gridWidth, int gridHeight, Color color, Random random) {
    final isVertical = random.nextBool();
    final width = 1 + random.nextInt(3);
    
    if (isVertical) {
      final startPos = random.nextInt(gridWidth);
      for (int i = 0; i < gridHeight; i++) {
        for (int j = startPos; j < math.min(startPos + width, gridWidth); j++) {
          if (random.nextDouble() < 0.9) {
            grid[i][j] = color;
          }
        }
      }
    } else {
      final startPos = random.nextInt(gridHeight);
      for (int i = startPos; i < math.min(startPos + width, gridHeight); i++) {
        for (int j = 0; j < gridWidth; j++) {
          if (random.nextDouble() < 0.9) {
            grid[i][j] = color;
          }
        }
      }
    }
  }

  /// Create spiral patterns
  void _createSpiralPattern(List<List<Color>> grid, int gridWidth, int gridHeight, Color color, Random random) {
    final centerX = gridHeight ~/ 2;
    final centerY = gridWidth ~/ 2;
    final maxRadius = math.min(centerX, centerY);
    
    for (int r = 0; r < maxRadius; r++) {
      for (int angle = 0; angle < 360; angle += 15) {
        final rad = angle * math.pi / 180;
        final x = centerX + (r * math.cos(rad)).round();
        final y = centerY + (r * math.sin(rad)).round();
        
        if (x >= 0 && x < gridHeight && y >= 0 && y < gridWidth && random.nextDouble() < 0.7) {
          grid[x][y] = color;
        }
      }
    }
  }

  /// Create checkerboard patterns
  void _createCheckerboardPattern(List<List<Color>> grid, int gridWidth, int gridHeight, Color color, Random random) {
    final startX = random.nextInt(gridHeight);
    final startY = random.nextInt(gridWidth);
    final size = 2 + random.nextInt(4);
    
    for (int i = startX; i < math.min(startX + size, gridHeight); i++) {
      for (int j = startY; j < math.min(startY + size, gridWidth); j++) {
        if ((i + j) % 2 == 0 && random.nextDouble() < 0.8) {
          grid[i][j] = color;
        }
      }
    }
  }

  /// Add strategic noise to make patterns less predictable - MUCH MORE AGGRESSIVE
  void _addStrategicNoise(List<List<Color>> grid, int gridWidth, int gridHeight, int level, Random random) {
    final noiseLevel = (level * 0.15).clamp(0.2, 0.5); // Increased from 0.1-0.3 to 0.2-0.5
    
    // Multiple noise passes for maximum scattering
    for (int pass = 0; pass < 2; pass++) {
      for (int i = 0; i < gridHeight; i++) {
        for (int j = 0; j < gridWidth; j++) {
          if (random.nextDouble() < noiseLevel) {
            grid[i][j] = GameConstants.gameColors[random.nextInt(GameConstants.gameColors.length)];
          }
        }
      }
    }
    
    // Additional targeted noise to break up any remaining groups
    _breakUpRemainingGroups(grid, gridWidth, gridHeight, random);
  }

  /// Break up any remaining color groups
  void _breakUpRemainingGroups(List<List<Color>> grid, int gridWidth, int gridHeight, Random random) {
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        final currentColor = grid[i][j];
        int adjacentSameColor = 0;
        
        // Count adjacent same colors
        if (i > 0 && grid[i - 1][j] == currentColor) adjacentSameColor++;
        if (i < gridHeight - 1 && grid[i + 1][j] == currentColor) adjacentSameColor++;
        if (j > 0 && grid[i][j - 1] == currentColor) adjacentSameColor++;
        if (j < gridWidth - 1 && grid[i][j + 1] == currentColor) adjacentSameColor++;
        
        // If any adjacent same colors, change this cell
        if (adjacentSameColor > 0 && random.nextDouble() < 0.4) {
          final newColor = _getRandomDifferentColor(currentColor);
          grid[i][j] = newColor;
        }
      }
    }
  }

  /// Optimize the grid for maximum difficulty while keeping it solvable
  void _optimizeForDifficulty(List<List<Color>> grid, int gridWidth, int gridHeight, int level) {
    // Ensure the grid has a good distribution of colors
    final colorCounts = <Color, int>{};
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        final color = grid[i][j];
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // If any color is too dominant, redistribute
    final totalCells = gridWidth * gridHeight;
    final maxColorCount = (totalCells * 0.6).round();
    
    for (final entry in colorCounts.entries) {
      if (entry.value > maxColorCount) {
        _redistributeColor(grid, gridWidth, gridHeight, entry.key, entry.value - maxColorCount);
      }
    }
    
    // CRITICAL: Ensure no 4 same color cells are adjacent
    _preventFourAdjacentCells(grid, gridWidth, gridHeight);
  }

  /// Ensure maximum 2 colors appear in adjacent cells for wild distribution
  void _preventFourAdjacentCells(List<List<Color>> grid, int gridWidth, int gridHeight) {
    bool hasAdjacent = true;
    int attempts = 0;
    final maxAttempts = 300; // More attempts for wild distribution
    
    while (hasAdjacent && attempts < maxAttempts) {
      hasAdjacent = false;
      attempts++;
      
      for (int i = 0; i < gridHeight; i++) {
        for (int j = 0; j < gridWidth; j++) {
          final currentColor = grid[i][j];
          
          // Check horizontal 2-in-a-row and break any 3+ patterns
          if (j <= gridWidth - 2) {
            if (grid[i][j] == currentColor && grid[i][j + 1] == currentColor) {
              // Found 2 in a row, check if there's a 3rd
              if (j <= gridWidth - 3 && grid[i][j + 2] == currentColor) {
                // Break the pattern by changing middle cell
                final newColor = _getRandomDifferentColor(currentColor);
                grid[i][j + 1] = newColor;
                hasAdjacent = true;
              }
            }
          }
          
          // Check vertical 2-in-a-row and break any 3+ patterns
          if (i <= gridHeight - 2) {
            if (grid[i][j] == currentColor && grid[i + 1][j] == currentColor) {
              // Found 2 in a row, check if there's a 3rd
              if (i <= gridHeight - 3 && grid[i + 2][j] == currentColor) {
                // Break the pattern by changing middle cell
                final newColor = _getRandomDifferentColor(currentColor);
                grid[i + 1][j] = newColor;
                hasAdjacent = true;
              }
            }
          }
          
          // Ensure no 2x2 squares of same color
          if (i <= gridHeight - 2 && j <= gridWidth - 2) {
            if (grid[i][j] == currentColor && 
                grid[i][j + 1] == currentColor &&
                grid[i + 1][j] == currentColor &&
                grid[i + 1][j + 1] == currentColor) {
              // Break the 2x2 square by changing two corners
              final newColor1 = _getRandomDifferentColor(currentColor);
              final newColor2 = _getRandomDifferentColor(currentColor);
              grid[i][j] = newColor1;
              grid[i + 1][j + 1] = newColor2;
              hasAdjacent = true;
            }
          }
          
          // Break L-shapes and other patterns
          _breakLShapes(grid, gridWidth, gridHeight, i, j, currentColor);
        }
      }
    }
    
    // Additional pass to ensure maximum wild distribution
    _maximizeWildColorDistribution(grid, gridWidth, gridHeight);
  }

  /// Break L-shaped patterns of same colors
  void _breakLShapes(List<List<Color>> grid, int gridWidth, int gridHeight, int i, int j, Color currentColor) {
    // Check for L-shapes and break them
    if (i < gridHeight - 1 && j < gridWidth - 1) {
      // L-shape: current + right + down
      if (grid[i][j] == currentColor && 
          grid[i][j + 1] == currentColor &&
          grid[i + 1][j] == currentColor) {
        final newColor = _getRandomDifferentColor(currentColor);
        grid[i][j + 1] = newColor;
      }
      
      // L-shape: current + left + down
      if (j > 0 && grid[i][j] == currentColor && 
          grid[i][j - 1] == currentColor &&
          grid[i + 1][j] == currentColor) {
        final newColor = _getRandomDifferentColor(currentColor);
        grid[i][j - 1] = newColor;
      }
    }
  }

  /// Maximize wild color distribution - no two adjacent cells can have the same color AND balanced color count
  void _maximizeWildColorDistribution(List<List<Color>> grid, int gridWidth, int gridHeight) {
    final random = Random();
    bool changed = true;
    int attempts = 0;
    final maxAttempts = 1000; // More attempts for complete distribution
    
    // Keep iterating until perfect distribution
    while (changed && attempts < maxAttempts) {
      changed = false;
      attempts++;
      
      for (int i = 0; i < gridHeight; i++) {
        for (int j = 0; j < gridWidth; j++) {
          final currentColor = grid[i][j];
          
          // Check all 8 adjacent cells (orthogonal + diagonal)
          bool hasAdjacentSame = false;
          
          // Check orthogonal neighbors (up, down, left, right)
          if (i > 0 && grid[i - 1][j] == currentColor) hasAdjacentSame = true;
          if (i < gridHeight - 1 && grid[i + 1][j] == currentColor) hasAdjacentSame = true;
          if (j > 0 && grid[i][j - 1] == currentColor) hasAdjacentSame = true;
          if (j < gridWidth - 1 && grid[i][j + 1] == currentColor) hasAdjacentSame = true;
          
          // Check diagonal neighbors (all 4 corners)
          if (i > 0 && j > 0 && grid[i - 1][j - 1] == currentColor) hasAdjacentSame = true;
          if (i > 0 && j < gridWidth - 1 && grid[i - 1][j + 1] == currentColor) hasAdjacentSame = true;
          if (i < gridHeight - 1 && j > 0 && grid[i + 1][j - 1] == currentColor) hasAdjacentSame = true;
          if (i < gridHeight - 1 && j < gridWidth - 1 && grid[i + 1][j + 1] == currentColor) hasAdjacentSame = true;
          
          // If any adjacent cell has the same color, change this cell to a color that's NOT adjacent
          if (hasAdjacentSame) {
            final newColor = _getBestDifferentColor(grid, gridWidth, gridHeight, i, j, currentColor);
            grid[i][j] = newColor;
            changed = true;
          }
        }
      }
    }
  }
  
  /// Get the best color that's not adjacent AND helps balance color distribution
  Color _getBestDifferentColor(List<List<Color>> grid, int gridWidth, int gridHeight, int i, int j, Color currentColor) {
    // Get color counts to balance distribution
    final colorCounts = <Color, int>{};
    for (int x = 0; x < gridHeight; x++) {
      for (int y = 0; y < gridWidth; y++) {
        final color = grid[x][y];
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // Get adjacent colors to exclude
    final adjacentColors = <Color>{};
    
    // Check all 8 adjacent cells for colors to avoid
    if (i > 0) adjacentColors.add(grid[i - 1][j]);
    if (i < gridHeight - 1) adjacentColors.add(grid[i + 1][j]);
    if (j > 0) adjacentColors.add(grid[i][j - 1]);
    if (j < gridWidth - 1) adjacentColors.add(grid[i][j + 1]);
    if (i > 0 && j > 0) adjacentColors.add(grid[i - 1][j - 1]);
    if (i > 0 && j < gridWidth - 1) adjacentColors.add(grid[i - 1][j + 1]);
    if (i < gridHeight - 1 && j > 0) adjacentColors.add(grid[i + 1][j - 1]);
    if (i < gridHeight - 1 && j < gridWidth - 1) adjacentColors.add(grid[i + 1][j + 1]);
    
    // Find color with lowest count that's not adjacent
    Color? bestColor;
    int lowestCount = 9999;
    
    for (final color in GameConstants.gameColors) {
      if (color == currentColor) continue;
      if (adjacentColors.contains(color)) continue;
      
      final count = colorCounts[color] ?? 0;
      if (count < lowestCount) {
        lowestCount = count;
        bestColor = color;
      }
    }
    
    // If no non-adjacent color found, use random different color
    if (bestColor == null) {
      return _getRandomDifferentColor(currentColor);
    }
    
    return bestColor;
  }

  /// Break horizontal patterns of 3+ same colors
  void _breakHorizontalPattern(List<List<Color>> grid, int gridSize, int i, int j, Color currentColor) {
    if (j <= gridSize - 3) {
      int count = 1;
      for (int k = j + 1; k < gridSize && grid[i][k] == currentColor; k++) {
        count++;
      }
      if (count >= 3) {
        // Break the pattern by changing middle cells
        for (int k = j + 1; k < j + count - 1; k++) {
          if (k < gridSize) {
            grid[i][k] = _getRandomDifferentColor(currentColor);
          }
        }
      }
    }
  }

  /// Break vertical patterns of 3+ same colors
  void _breakVerticalPattern(List<List<Color>> grid, int gridSize, int i, int j, Color currentColor) {
    if (i <= gridSize - 3) {
      int count = 1;
      for (int k = i + 1; k < gridSize && grid[k][j] == currentColor; k++) {
        count++;
      }
      if (count >= 3) {
        // Break the pattern by changing middle cells
        for (int k = i + 1; k < i + count - 1; k++) {
          if (k < gridSize) {
            grid[k][j] = _getRandomDifferentColor(currentColor);
          }
        }
      }
    }
  }

  /// Break diagonal patterns of 3+ same colors
  void _breakDiagonalPattern(List<List<Color>> grid, int gridSize, int i, int j, Color currentColor) {
    // Check diagonal patterns and break them
    if (i <= gridSize - 3 && j <= gridSize - 3) {
      // Check main diagonal
      if (grid[i + 1][j + 1] == currentColor && grid[i + 2][j + 2] == currentColor) {
        grid[i + 1][j + 1] = _getRandomDifferentColor(currentColor);
      }
    }
    
    // Check anti-diagonal (need to ensure j is at least 2 to avoid negative indices)
    if (i <= gridSize - 3 && j >= 2 && j <= gridSize - 1) {
      if (grid[i + 1][j - 1] == currentColor && grid[i + 2][j - 2] == currentColor) {
        grid[i + 1][j - 1] = _getRandomDifferentColor(currentColor);
      }
    }
  }

  /// Get a random color different from the given color
  Color _getRandomDifferentColor(Color currentColor) {
    final random = Random();
    final availableColors = GameConstants.gameColors.where((color) => color != currentColor).toList();
    if (availableColors.isEmpty) {
      return GameConstants.gameColors[random.nextInt(GameConstants.gameColors.length)];
    }
    return availableColors[random.nextInt(availableColors.length)];
  }

  /// Redistribute excess color cells
  void _redistributeColor(List<List<Color>> grid, int gridWidth, int gridHeight, Color color, int excessCount) {
    final random = Random();
    final cellsToChange = <Point<int>>[];
    
    // Find all cells with the excess color
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        if (grid[i][j] == color) {
          cellsToChange.add(Point(i, j));
        }
      }
    }
    
    // Randomly change excess cells to other colors
    cellsToChange.shuffle(random);
    for (int i = 0; i < math.min(excessCount, cellsToChange.length); i++) {
      final point = cellsToChange[i];
      final newColor = GameConstants.gameColors[random.nextInt(GameConstants.gameColors.length)];
      grid[point.x][point.y] = newColor;
    }
  }

  /// Calculate the optimal solution for a grid - ACTUALLY SOLVES THE PUZZLE STEP BY STEP
  int calculateOptimalSolution(List<List<Color>> grid) {
    if (grid.isEmpty || grid[0].isEmpty) return -1;
    
    // Check if already solved
    if (isGridSolved(grid)) return 0;
    
    // Actually solve the puzzle step by step using greedy approach
    var currentGrid = cloneGrid(grid);
    int moves = 0;
    
    // Maximum moves limit (safety)
    final gridHeight = grid.length;
    final gridWidth = grid[0].length;
    final int maxMoves = gridWidth * gridHeight * 10;

    // Solve step by step - always pick color that gains most area
    while (!isGridSolved(currentGrid) && moves < maxMoves) {
      final currentColor = currentGrid[0][0];
      Color? bestColor;
      int maxAreaGained = -1;
      
      // Try each color and find the one that gains the most area
      for (final color in GameConstants.gameColors) {
        if (color == currentColor) continue; // Skip current color
        
        final testGrid = floodFillOnGrid(currentGrid, 0, 0, color);
        final currentArea = countCurrentArea(currentGrid);
        final newArea = countCurrentArea(testGrid);
        final areaGained = newArea - currentArea;
        
        if (areaGained > maxAreaGained) {
          maxAreaGained = areaGained;
          bestColor = color;
        }
      }
      
      // If no color found (shouldn't happen), use first available
      if (bestColor == null) {
        for (final color in GameConstants.gameColors) {
          if (color != currentColor) {
            bestColor = color;
            break;
          }
        }
      }
      
      // If still no color, puzzle is stuck
      if (bestColor == null) {
        break;
      }
      
      // Apply the move
      currentGrid = floodFillOnGrid(currentGrid, 0, 0, bestColor);
      moves++;
      
      // Check if solved
      if (isGridSolved(currentGrid)) {
        return moves; // Return exact move count
      }
    }

    // Verify we actually solved it
    if (isGridSolved(currentGrid)) {
      return moves;
    }
    
    return -1; // Failed to solve
  }

  /// Calculate the AI-optimal solution - ACTUALLY SOLVES THE PUZZLE
  int calculateAIOptimalSolution(List<List<Color>> grid) {
    // Just use the basic optimal solution which actually solves the puzzle
    final solution = calculateOptimalSolution(grid);
    
    // If that fails, try greedy approach
    if (solution == -1) {
      return _calculateGreedySolution(grid);
    }
    
    return solution;
  }

  /// Greedy strategy: always choose the move that gains the most area
  int _calculateGreedySolution(List<List<Color>> grid) {
    if (grid.isEmpty || grid[0].isEmpty) return -1;
    if (isGridSolved(grid)) return 0;
    
    List<List<Color>> tempGrid = cloneGrid(grid);
    int solutionMoves = 0;
    
    // Calculate bailout based on total grid size
    final gridHeight = grid.length;
    final gridWidth = grid[0].length;
    final totalCells = gridWidth * gridHeight;
    final int bailout = math.max(totalCells * 3, 50);

    while (!isGridSolved(tempGrid) && solutionMoves < bailout) {
      final bestMove = findBestMove(tempGrid);
      if (bestMove == tempGrid[0][0]) {
        break; // Can't make progress
      }
      tempGrid = floodFillOnGrid(tempGrid, 0, 0, bestMove);
      solutionMoves++;
      
      if (isGridSolved(tempGrid)) {
        return solutionMoves;
      }
    }

    return isGridSolved(tempGrid) ? solutionMoves : -1;
  }

  /// Strategic strategy: considers future moves and color distribution
  int _calculateStrategicSolution(List<List<Color>> grid) {
    if (grid.isEmpty || grid[0].isEmpty) return -1;
    if (isGridSolved(grid)) return 0;
    
    List<List<Color>> tempGrid = cloneGrid(grid);
    int solutionMoves = 0;
    
    // Calculate bailout based on total grid size
    final gridHeight = grid.length;
    final gridWidth = grid[0].length;
    final totalCells = gridWidth * gridHeight;
    final int bailout = math.max(totalCells * 3, 50);

    while (!isGridSolved(tempGrid) && solutionMoves < bailout) {
      final bestMove = _findStrategicMove(tempGrid);
      if (bestMove == tempGrid[0][0]) {
        break; // Can't make progress
      }
      tempGrid = floodFillOnGrid(tempGrid, 0, 0, bestMove);
      solutionMoves++;
      
      if (isGridSolved(tempGrid)) {
        return solutionMoves;
      }
    }

    return isGridSolved(tempGrid) ? solutionMoves : -1;
  }

  /// Find a strategic move considering multiple factors
  Color _findStrategicMove(List<List<Color>> grid) {
    if (grid.isEmpty || grid[0].isEmpty || GameConstants.gameColors.isEmpty) {
      return GameConstants.gameColors.isNotEmpty 
          ? GameConstants.gameColors[0] 
          : Colors.blue;
    }
    
    try {
      Color? bestColor;
      double bestScore = -1.0;
      final startColor = grid[0][0];

      for (final color in GameConstants.gameColors) {
        if (color == startColor) continue;
        
        try {
          final simulatedGrid = floodFillOnGrid(grid, 0, 0, color);
          final score = _calculateStrategicScore(grid, simulatedGrid, color);
          
          if (score > bestScore) {
            bestScore = score;
            bestColor = color;
          }
        } catch (e) {
          continue;
        }
      }
      
      return bestColor ?? 
             (GameConstants.gameColors.where((c) => c != startColor).isNotEmpty
                 ? GameConstants.gameColors.where((c) => c != startColor).first
                 : GameConstants.gameColors[0]);
    } catch (e) {
      return GameConstants.gameColors.isNotEmpty 
          ? GameConstants.gameColors[0] 
          : Colors.blue;
    }
  }

  /// Calculate strategic score for a move
  double _calculateStrategicScore(List<List<Color>> originalGrid, List<List<Color>> newGrid, Color moveColor) {
    final gridHeight = originalGrid.length;
    final gridWidth = originalGrid.isNotEmpty ? originalGrid[0].length : 0;
    final totalCells = gridWidth * gridHeight;
    
    // Area gained (primary factor)
    final areaGained = countCurrentArea(newGrid) - countCurrentArea(originalGrid);
    final areaScore = areaGained / totalCells;
    
    // Color diversity (higher is better for strategic play)
    final colorDiversity = _calculateColorDiversity(newGrid);
    
    // Connectivity potential (how well the new area connects)
    final connectivityScore = _calculateConnectivityScore(newGrid);
    
    // Future move potential
    final futurePotential = _calculateFutureMovePotential(newGrid);
    
    // Weighted combination
    return (areaScore * 0.5) + 
           (colorDiversity * 0.2) + 
           (connectivityScore * 0.2) + 
           (futurePotential * 0.1);
  }

  /// Calculate color diversity in the grid
  double _calculateColorDiversity(List<List<Color>> grid) {
    final colorCounts = <Color, int>{};
    final gridHeight = grid.length;
    final gridWidth = grid.isNotEmpty ? grid[0].length : 0;
    
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        final color = grid[i][j];
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // Calculate Shannon entropy
    double entropy = 0.0;
    final totalCells = gridWidth * gridHeight;
    
    for (final count in colorCounts.values) {
      if (count > 0) {
        final probability = count / totalCells;
        entropy -= probability * math.log(probability) / math.ln2;
      }
    }
    
    // Normalize to 0-1 scale
    final maxEntropy = math.log(GameConstants.gameColors.length) / math.ln2;
    return entropy / maxEntropy;
  }

  /// Calculate connectivity score
  double _calculateConnectivityScore(List<List<Color>> grid) {
    final currentArea = countCurrentArea(grid);
    final gridHeight = grid.length;
    final gridWidth = grid.isNotEmpty ? grid[0].length : 0;
    final totalCells = gridWidth * gridHeight;
    
    return currentArea / totalCells;
  }

  /// Calculate future move potential
  double _calculateFutureMovePotential(List<List<Color>> grid) {
    final startColor = grid[0][0];
    double maxPotential = 0.0;
    final gridHeight = grid.length;
    final gridWidth = grid.isNotEmpty ? grid[0].length : 0;
    final totalCells = gridWidth * gridHeight;
    
    for (final color in GameConstants.gameColors) {
      if (color == startColor) continue;
      
      final simulatedGrid = floodFillOnGrid(grid, 0, 0, color);
      final potentialArea = countCurrentArea(simulatedGrid);
      final potential = potentialArea / totalCells;
      
      if (potential > maxPotential) {
        maxPotential = potential;
      }
    }
    
    return maxPotential;
  }

  /// Minimax strategy: considers opponent's best response
  int _calculateMinimaxSolution(List<List<Color>> grid) {
    // Simplified minimax for now - could be expanded
    return _calculateGreedySolution(grid);
  }

  /// Create a new game configuration for the given level with AI-precise difficulty
  GameConfig createGameConfig(int level) {
    try {
      // Ensure level is within valid range (1-24)
      final validLevel = level.clamp(1, GameConstants.maxLevel);
      final gridWidth = GameConstants.getGridWidth(validLevel);
      final gridHeight = GameConstants.getGridHeight(validLevel);
      
      // Validate grid dimensions
      if (gridWidth <= 0 || gridHeight <= 0) {
        throw Exception('Invalid grid dimensions: ${gridWidth}x${gridHeight}');
      }
      
      // Generate multiple grids and pick the most challenging one
      List<List<Color>> bestGrid;
      int bestSolutionMoves = -1;
      int bestDifficulty = -1;
      int attempts = 0;
      const maxAttempts = 10; // Limit attempts to prevent infinite loops
      
      // Generate initial grid
      try {
        bestGrid = generateRandomGrid(validLevel);
        if (bestGrid.isEmpty || bestGrid[0].isEmpty) {
          throw Exception('Generated empty grid');
        }
      } catch (e) {
        // If generation fails, create a simple grid as fallback
        bestGrid = List.generate(
          gridHeight,
          (_) => List.generate(
            gridWidth,
            (_) => GameConstants.gameColors.isNotEmpty
                ? GameConstants.gameColors[0]
                : Colors.blue,
          ),
        );
      }
      
      // ACTUALLY SOLVE THE PUZZLE AND COUNT MOVES
      // Calculate solution for the generated grid - this actually solves it
      bestSolutionMoves = calculateOptimalSolution(bestGrid);
      
      // If solution calculation failed, try again with AI solution
      if (bestSolutionMoves == -1 || bestSolutionMoves <= 0) {
        bestSolutionMoves = calculateAIOptimalSolution(bestGrid);
      }
      
      // If still no solution, the grid might be unsolvable - generate a new one
      if (bestSolutionMoves == -1 || bestSolutionMoves <= 0) {
        // Try a few more times to get a solvable grid
        for (int retry = 0; retry < 3; retry++) {
          try {
            final newGrid = generateRandomGrid(validLevel);
            if (newGrid.isEmpty || newGrid[0].isEmpty) continue;
            
            final newSolution = calculateOptimalSolution(newGrid);
            if (newSolution != -1 && newSolution > 0) {
              bestGrid = newGrid;
              bestSolutionMoves = newSolution;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }
      
      // Final fallback: if we still don't have a solution, use estimate
      if (bestSolutionMoves == -1 || bestSolutionMoves <= 0) {
        final totalCells = gridWidth * gridHeight;
        bestSolutionMoves = (totalCells / 2).round().clamp(5, 30);
      }
      
      // Ensure minimum solution (at least 1 move)
      if (bestSolutionMoves < 1) {
        bestSolutionMoves = 1;
      }

      // Validate bestGrid before calculating max moves
      if (bestGrid.isEmpty || bestGrid[0].isEmpty) {
        // Create minimal valid grid
        bestGrid = List.generate(
          gridHeight,
          (_) => List.generate(
            gridWidth,
            (_) => GameConstants.gameColors.isNotEmpty
                ? GameConstants.gameColors[0]
                : Colors.blue,
          ),
        );
        // Calculate solution for fallback grid
        bestSolutionMoves = calculateAIOptimalSolution(bestGrid);
        if (bestSolutionMoves == -1 || bestSolutionMoves <= 0) {
          bestSolutionMoves = ((gridWidth + gridHeight) / 2 * 2).round().clamp(5, 40);
        }
      }

      // Use EXACT solution moves - NO BUFFER, NO DOUBLE CALCULATION
      final validMaxMoves = bestSolutionMoves;

      return GameConfig(
        level: validLevel,
        gridWidth: gridWidth,
        gridHeight: gridHeight,
        maxMoves: validMaxMoves,
        grid: bestGrid,
        originalGrid: cloneGrid(bestGrid),
      );
    } catch (e) {
      // Last resort: create a minimal valid game config
      final fallbackLevel = level.clamp(1, GameConstants.maxLevel);
      final fallbackGridWidth = GameConstants.getGridWidth(fallbackLevel);
      final fallbackGridHeight = GameConstants.getGridHeight(fallbackLevel);
      final fallbackGrid = List.generate(
        fallbackGridHeight,
        (_) => List.generate(
          fallbackGridWidth,
          (_) => GameConstants.gameColors.isNotEmpty
              ? GameConstants.gameColors[0]
              : Colors.blue,
        ),
      );
      
      return GameConfig(
        level: fallbackLevel,
        gridWidth: fallbackGridWidth,
        gridHeight: fallbackGridHeight,
        maxMoves: (fallbackGridWidth + fallbackGridHeight) ~/ 2 + 5,
        grid: fallbackGrid,
        originalGrid: cloneGrid(fallbackGrid),
      );
    }
  }

  /// Calculate grid difficulty based on multiple factors
  int _calculateGridDifficulty(List<List<Color>> grid, int solutionMoves) {
    final gridHeight = grid.length;
    final gridWidth = grid.isNotEmpty ? grid[0].length : 0;
    final totalCells = gridWidth * gridHeight;
    
    // Base difficulty from solution moves
    int difficulty = solutionMoves * 10;
    
    // Add difficulty for color distribution complexity
    final colorDiversity = _calculateColorDiversity(grid);
    difficulty += (colorDiversity * 20).round();
    
    // Add difficulty for grid size (use average of width and height)
    difficulty += ((gridWidth + gridHeight) ~/ 2) * 2;
    
    // Add difficulty for pattern complexity
    final patternComplexity = _calculatePatternComplexity(grid);
    difficulty += (patternComplexity * 15).round();
    
    return difficulty;
  }

  /// Calculate pattern complexity in the grid
  double _calculatePatternComplexity(List<List<Color>> grid) {
    final gridSize = grid.length;
    double complexity = 0.0;
    
    // Check for isolated regions
    final isolatedRegions = _countIsolatedRegions(grid);
    complexity += isolatedRegions * 0.3;
    
    // Check for color clustering
    final clusteringScore = _calculateClusteringScore(grid);
    complexity += clusteringScore * 0.4;
    
    // Check for edge patterns
    final edgePatternScore = _calculateEdgePatternScore(grid);
    complexity += edgePatternScore * 0.3;
    
    return complexity.clamp(0.0, 1.0);
  }

  /// Count isolated regions in the grid
  int _countIsolatedRegions(List<List<Color>> grid) {
    final gridSize = grid.length;
    final visited = List.generate(gridSize, (_) => List.generate(gridSize, (_) => false));
    int regionCount = 0;
    
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (!visited[i][j]) {
          _markConnectedRegion(grid, visited, i, j, grid[i][j]);
          regionCount++;
        }
      }
    }
    
    return regionCount;
  }

  /// Mark all connected cells of the same color
  void _markConnectedRegion(List<List<Color>> grid, List<List<bool>> visited, int x, int y, Color color) {
    if (x < 0 || x >= grid.length || y < 0 || y >= grid.length || 
        visited[x][y] || grid[x][y] != color) {
      return;
    }
    
    visited[x][y] = true;
    
    _markConnectedRegion(grid, visited, x + 1, y, color);
    _markConnectedRegion(grid, visited, x - 1, y, color);
    _markConnectedRegion(grid, visited, x, y + 1, color);
    _markConnectedRegion(grid, visited, x, y - 1, color);
  }

  /// Calculate clustering score
  double _calculateClusteringScore(List<List<Color>> grid) {
    final gridSize = grid.length;
    double clusteringScore = 0.0;
    
    for (int i = 0; i < gridSize - 1; i++) {
      for (int j = 0; j < gridSize - 1; j++) {
        final currentColor = grid[i][j];
        
        // Check if adjacent cells have the same color
        if (grid[i + 1][j] == currentColor) clusteringScore += 0.25;
        if (grid[i][j + 1] == currentColor) clusteringScore += 0.25;
        if (i > 0 && grid[i - 1][j] == currentColor) clusteringScore += 0.25;
        if (j > 0 && grid[i][j - 1] == currentColor) clusteringScore += 0.25;
      }
    }
    
    final totalPossible = (gridSize - 1) * (gridSize - 1) * 4;
    return clusteringScore / totalPossible;
  }

  /// Calculate edge pattern score
  double _calculateEdgePatternScore(List<List<Color>> grid) {
    final gridHeight = grid.length;
    final gridWidth = grid.isNotEmpty ? grid[0].length : 0;
    double edgeScore = 0.0;
    
    // Check top and bottom edges
    for (int j = 0; j < gridWidth; j++) {
      if (grid[0][j] == grid[gridHeight - 1][j]) edgeScore += 0.5;
    }
    
    // Check left and right edges
    for (int i = 0; i < gridHeight; i++) {
      if (grid[i][0] == grid[i][gridWidth - 1]) edgeScore += 0.5;
    }
    
    return edgeScore / (gridWidth + gridHeight);
  }

  /// Verify that a solution actually solves the puzzle
  bool _verifySolution(List<List<Color>> grid, int solutionMoves) {
    try {
      List<List<Color>> testGrid = cloneGrid(grid);
      int moves = 0;
      final maxMoves = solutionMoves * 2; // Allow some buffer for verification
      
      while (!isGridSolved(testGrid) && moves < maxMoves) {
        final bestMove = findBestMove(testGrid);
        if (bestMove == testGrid[0][0]) {
          return false; // Can't make progress
        }
        testGrid = floodFillOnGrid(testGrid, 0, 0, bestMove);
        moves++;
      }
      
      return isGridSolved(testGrid) && moves <= solutionMoves * 1.5;
    } catch (e) {
      return false;
    }
  }

  /// Calculate precise max moves using AI intelligence - GENEROUS BUFFER TO ENSURE SOLVABILITY
  int _calculatePreciseMaxMoves(int level, int solutionMoves, List<List<Color>> grid) {
    // Base buffer: minimum 5 extra moves, more for higher levels
    int baseBuffer = 5;
    
    // Add more buffer for higher levels (scales with level)
    final levelMultiplier = (level / GameConstants.maxLevel).clamp(0.0, 1.0);
    final additionalBuffer = (levelMultiplier * 10).round(); // Up to 10 more moves for high levels
    
    // Add buffer based on grid size (larger grids need more moves)
    final gridHeight = grid.length;
    final gridWidth = grid.isNotEmpty ? grid[0].length : 0;
    final gridSizeFactor = ((gridWidth + gridHeight) / 2).round();
    final sizeBuffer = (gridSizeFactor * 0.5).round(); // Larger grids get more buffer
    
    // Total buffer: base + level-based + size-based
    final totalBuffer = baseBuffer + additionalBuffer + sizeBuffer;
    
    // Ensure minimum buffer of 5 moves, maximum reasonable buffer
    final finalBuffer = totalBuffer.clamp(5, 20);
    
    // Final moves = solution + generous buffer
    final finalMoves = solutionMoves + finalBuffer;
    
    // Safety check: ensure we have at least solution + 5 moves
    return finalMoves.clamp(solutionMoves + 5, solutionMoves + 25);
  }

  /// Analyze the actual difficulty of a puzzle based on color distribution and patterns
  double _analyzePuzzleDifficulty(List<List<Color>> grid, int solutionMoves) {
    
    // Analyze color distribution complexity
    final colorDistributionScore = _analyzeColorDistributionComplexity(grid);
    
    // Analyze pattern complexity (isolated regions, clusters, etc.)
    final patternComplexityScore = _analyzePatternComplexity(grid);
    
    // Analyze solution efficiency (how close to optimal the solution is)
    final solutionEfficiencyScore = _analyzeSolutionEfficiency(grid, solutionMoves);
    
    // Analyze strategic difficulty (how many good vs bad moves exist)
    final strategicDifficultyScore = _analyzeStrategicDifficulty(grid);
    
    // Weighted combination of all factors
    return (colorDistributionScore * 0.3) + 
           (patternComplexityScore * 0.3) + 
           (solutionEfficiencyScore * 0.2) + 
           (strategicDifficultyScore * 0.2);
  }

  /// Calculate extra moves based on actual puzzle difficulty, not just level
  int _calculateExtraMovesBasedOnPuzzle(double puzzleDifficulty, int level) {
    // Base extra moves based on puzzle difficulty (0-1 scale)
    int baseExtraMoves = (puzzleDifficulty * 2).round(); // 0-2 extra moves based on difficulty
    
    // Small level adjustment (only 0-1 extra move based on level)
    int levelAdjustment = 0;
    if (level > 6) levelAdjustment = 1; // Only higher levels get 1 extra move
    
    return baseExtraMoves + levelAdjustment;
  }

  /// Analyze color distribution complexity
  double _analyzeColorDistributionComplexity(List<List<Color>> grid) {
    final colorCounts = <Color, int>{};
    final gridHeight = grid.length;
    final gridWidth = grid.isNotEmpty ? grid[0].length : 0;
    
    // Count colors
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        final color = grid[i][j];
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // Calculate distribution variance (higher variance = more complex)
    final totalCells = gridWidth * gridHeight;
    final expectedCount = totalCells / GameConstants.gameColors.length;
    double variance = 0.0;
    
    for (final count in colorCounts.values) {
      final diff = count - expectedCount;
      variance += diff * diff;
    }
    
    // Normalize variance to 0-1 scale
    final maxVariance = totalCells * totalCells / GameConstants.gameColors.length;
    return (variance / maxVariance).clamp(0.0, 1.0);
  }

  /// Analyze pattern complexity in the grid
  double _analyzePatternComplexity(List<List<Color>> grid) {
    final gridHeight = grid.length;
    final gridWidth = grid.isNotEmpty ? grid[0].length : 0;
    
    // Count isolated single cells (harder to solve)
    int isolatedCells = 0;
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        final currentColor = grid[i][j];
        int sameColorNeighbors = 0;
        
        // Count adjacent same colors
        if (i > 0 && grid[i - 1][j] == currentColor) sameColorNeighbors++;
        if (i < gridHeight - 1 && grid[i + 1][j] == currentColor) sameColorNeighbors++;
        if (j > 0 && grid[i][j - 1] == currentColor) sameColorNeighbors++;
        if (j < gridWidth - 1 && grid[i][j + 1] == currentColor) sameColorNeighbors++;
        
        if (sameColorNeighbors == 0) isolatedCells++;
      }
    }
    
    // Count color regions (more regions = more complex)
    final regionCount = _countIsolatedRegions(grid);
    
    // Calculate complexity score
    final totalCells = gridWidth * gridHeight;
    final isolatedScore = isolatedCells / totalCells;
    final regionScore = regionCount / GameConstants.gameColors.length;
    
    return (isolatedScore * 0.6 + regionScore * 0.4).clamp(0.0, 1.0);
  }

  /// Analyze how efficient the solution is compared to optimal
  double _analyzeSolutionEfficiency(List<List<Color>> grid, int solutionMoves) {
    // Calculate theoretical minimum moves needed
    final colorCounts = <Color, int>{};
    final gridHeight = grid.length;
    final gridWidth = grid.isNotEmpty ? grid[0].length : 0;
    
    for (int i = 0; i < gridHeight; i++) {
      for (int j = 0; j < gridWidth; j++) {
        final color = grid[i][j];
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // Theoretical minimum is number of different colors - 1
    final theoreticalMin = colorCounts.length - 1;
    
    // If solution is close to theoretical minimum, it's harder
    if (theoreticalMin == 0) return 0.0;
    final efficiency = theoreticalMin / solutionMoves;
    
    return efficiency.clamp(0.0, 1.0);
  }

  /// Analyze strategic difficulty (how many good vs bad moves exist)
  double _analyzeStrategicDifficulty(List<List<Color>> grid) {
    final startColor = grid[0][0];
    int goodMoves = 0;
    int totalMoves = 0;
    
    for (final color in GameConstants.gameColors) {
      if (color == startColor) continue;
      
      totalMoves++;
      final simulatedGrid = floodFillOnGrid(grid, 0, 0, color);
      final areaGained = countCurrentArea(simulatedGrid) - countCurrentArea(grid);
      
      // A "good" move gains significant area
      if (areaGained > grid.length) {
        goodMoves++;
      }
    }
    
    if (totalMoves == 0) return 0.0;
    
    // More good moves = easier puzzle, fewer good moves = harder puzzle
    final goodMoveRatio = goodMoves / totalMoves;
    return (1.0 - goodMoveRatio).clamp(0.0, 1.0); // Invert so higher = harder
  }

  /// Calculate grid complexity
  double _calculateGridComplexity(List<List<Color>> grid) {
    final gridSize = grid.length;
    
    // Color distribution complexity
    final colorDiversity = _calculateColorDiversity(grid);
    
    // Pattern complexity
    final patternComplexity = _calculatePatternComplexity(grid);
    
    // Size factor
    final sizeFactor = gridSize / 18.0; // Normalize to max level size
    
    return (colorDiversity * 0.4) + (patternComplexity * 0.4) + (sizeFactor * 0.2);
  }

  /// Check if a move is valid
  bool isValidMove(List<List<Color>> grid, Color newColor) {
    try {
      // Validate grid before accessing
      if (grid.isEmpty || grid[0].isEmpty) {
        return false;
      }
      final startColor = grid[0][0];
      return startColor != newColor;
    } catch (e) {
      // If any error occurs, consider move invalid
      return false;
    }
  }

  /// Apply a move to the grid
  List<List<Color>> applyMove(List<List<Color>> grid, Color newColor) {
    try {
      // Validate grid before applying move
      if (grid.isEmpty || grid[0].isEmpty) {
        return grid; // Return original grid if invalid
      }
      return floodFillOnGrid(grid, 0, 0, newColor);
    } catch (e) {
      // If any error occurs, return original grid
      return grid;
    }
  }

  /// Get AI hint for the current grid state
  Color getAIHint(List<List<Color>> grid) {
    return findBestMove(grid);
  }

  /// Calculate move efficiency (how good a move was)
  double calculateMoveEfficiency(List<List<Color>> originalGrid, List<List<Color>> newGrid) {
    final originalArea = countCurrentArea(originalGrid);
    final newArea = countCurrentArea(newGrid);
    final gridHeight = originalGrid.length;
    final gridWidth = originalGrid.isNotEmpty ? originalGrid[0].length : 0;
    final totalCells = gridWidth * gridHeight;
    
    final areaGained = newArea - originalArea;
    final efficiency = areaGained / totalCells;
    
    return efficiency.clamp(0.0, 1.0);
  }

  /// Check if a move is suboptimal (penalty system)
  bool isSuboptimalMove(List<List<Color>> grid, Color moveColor) {
    final aiHint = getAIHint(grid);
    return moveColor != aiHint;
  }

  /// Calculate difficulty rating for the current grid
  String getDifficultyRating(List<List<Color>> grid, int level) {
    final complexity = _calculateGridComplexity(grid);
    final solutionMoves = calculateAIOptimalSolution(grid);
    
    if (solutionMoves == -1) return "Impossible";
    
    final difficultyScore = complexity * 100 + (solutionMoves * 2) + (level * 3);
    
    if (difficultyScore < 30) return "Easy";
    if (difficultyScore < 60) return "Medium";
    if (difficultyScore < 100) return "Hard";
    if (difficultyScore < 150) return "Expert";
    return "Master";
  }
}

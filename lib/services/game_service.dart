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
    final firstColor = gridToCheck[0][0];
    for (var row in gridToCheck) {
      for (var cellColor in row) {
        if (cellColor != firstColor) return false;
      }
    }
    return true;
  }

  /// Perform flood fill on the grid
  List<List<Color>> floodFillOnGrid(
    List<List<Color>> gridData,
    int startX,
    int startY,
    Color replacementColor,
  ) {
    final targetColor = gridData[startX][startY];
    if (targetColor == replacementColor) return gridData;

    final filledGrid = cloneGrid(gridData);
    final queue = Queue<Point<int>>();
    queue.add(Point(startX, startY));

    final visited = <Point<int>>{Point(startX, startY)};

    while (queue.isNotEmpty) {
      final point = queue.removeFirst();
      final x = point.x;
      final y = point.y;

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
              nx < gridData.length &&
              ny >= 0 &&
              ny < gridData.length &&
              !visited.contains(neighbor) &&
              filledGrid[nx][ny] == targetColor) {
            visited.add(neighbor);
            queue.add(neighbor);
          }
        }
      }
    }
    return filledGrid;
  }

  /// Count the current area size starting from top-left corner
  int countCurrentArea(List<List<Color>> gridData) {
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
            neighbor.y < gridData.length &&
            !visited.contains(neighbor) &&
            gridData[neighbor.x][neighbor.y] == targetColor) {
          visited.add(neighbor);
          queue.add(neighbor);
        }
      }
    }
    return count;
  }

  /// Find the best move for the current grid state using advanced AI strategies
  Color findBestMove(List<List<Color>> gridToAnalyze) {
    Color? bestColor;
    double bestScore = -1.0;
    final startColor = gridToAnalyze[0][0];

    for (final color in GameConstants.gameColors) {
      if (color == startColor) continue;
      
      final simulatedGrid = floodFillOnGrid(gridToAnalyze, 0, 0, color);
      final score = _calculateMoveScore(gridToAnalyze, simulatedGrid, color);
      
      if (score > bestScore) {
        bestScore = score;
        bestColor = color;
      }
    }
    return bestColor!;
  }

  /// Calculate a sophisticated score for a potential move
  double _calculateMoveScore(List<List<Color>> originalGrid, List<List<Color>> newGrid, Color moveColor) {
    final gridSize = originalGrid.length;
    final totalCells = gridSize * gridSize;
    
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
    final gridSize = grid.length;
    
    // Count all colors in the grid
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final color = grid[i][j];
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // Calculate distribution entropy (higher is better for difficulty)
    double entropy = 0.0;
    final totalCells = gridSize * gridSize;
    
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
    final gridSize = grid.length;
    final totalCells = gridSize * gridSize;
    
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
    
    final gridSize = grid.length;
    final totalCells = gridSize * gridSize;
    return maxFutureArea / totalCells;
  }

  /// Calculate anti-pattern penalty to avoid easy solutions
  double _calculateAntiPatternPenalty(List<List<Color>> originalGrid, List<List<Color>> newGrid, Color moveColor) {
    double penalty = 0.0;
    final gridSize = originalGrid.length;
    
    // Penalty for creating large uniform blocks
    final newAreaSize = countCurrentArea(newGrid);
    final totalCells = gridSize * gridSize;
    
    if (newAreaSize > totalCells * 0.7) {
      penalty += 0.3; // Heavy penalty for too large areas
    }
    
    // Penalty for creating obvious next moves
    final remainingColors = <Color>{};
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
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
    final gridSize = GameConstants.levelGridSizes[level] ?? GameConstants.baseGridSize;
    
    // Use intelligent generation for higher levels
    if (level >= 3) {
      return _generateIntelligentGrid(gridSize, level, random);
    }
    
    // Simple random generation for early levels
    return List.generate(
      gridSize,
      (_) => List.generate(
        gridSize,
        (_) => GameConstants.gameColors[random.nextInt(GameConstants.gameColors.length)],
      ),
    );
  }

  /// Generate an intelligent grid with challenging patterns - MUCH HARDER
  List<List<Color>> _generateIntelligentGrid(int gridSize, int level, Random random) {
    final grid = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => GameConstants.gameColors[0]),
    );
    
    // Calculate difficulty parameters based on level - MUCH HARDER
    final difficultyMultiplier = (level - 1) / (GameConstants.maxLevel - 1);
    final patternComplexity = (5 + (difficultyMultiplier * 6)).round(); // 5-11 patterns (more complex)
    final colorDistributionBias = 0.1 + (difficultyMultiplier * 0.2); // 0.1-0.3 bias (more scattered)
    
    // Generate challenging patterns
    _createStrategicPatterns(grid, gridSize, patternComplexity, colorDistributionBias, random);
    
    // Add MORE strategic noise to make it harder
    _addStrategicNoise(grid, gridSize, level, random);
    
    // Ensure the grid is solvable but challenging
    _optimizeForDifficulty(grid, gridSize, level);
    
    // Additional difficulty pass
    _addExtraDifficulty(grid, gridSize, level, random);
    
    return grid;
  }

  /// Add extra difficulty to make the game much harder
  void _addExtraDifficulty(List<List<Color>> grid, int gridSize, int level, Random random) {
    // Create more isolated single cells
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (random.nextDouble() < 0.3) { // 30% chance to create isolated cells
          final currentColor = grid[i][j];
          final newColor = _getRandomDifferentColor(currentColor);
          grid[i][j] = newColor;
        }
      }
    }
    
    // Ensure maximum color diversity
    _ensureMaximumColorDiversity(grid, gridSize);
  }

  /// Ensure maximum color diversity in the grid
  void _ensureMaximumColorDiversity(List<List<Color>> grid, int gridSize) {
    final colorCounts = <Color, int>{};
    final totalCells = gridSize * gridSize;
    final maxColorCount = (totalCells / GameConstants.gameColors.length * 1.5).round();
    
    // Count colors
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final color = grid[i][j];
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // Redistribute excess colors
    for (final entry in colorCounts.entries) {
      if (entry.value > maxColorCount) {
        _redistributeColor(grid, gridSize, entry.key, entry.value - maxColorCount);
      }
    }
  }

  /// Create strategic patterns that make the game more challenging
  void _createStrategicPatterns(List<List<Color>> grid, int gridSize, int patternCount, double bias, Random random) {
    final colors = List<Color>.from(GameConstants.gameColors);
    colors.shuffle(random);
    
    for (int pattern = 0; pattern < patternCount; pattern++) {
      final color = colors[pattern % colors.length];
      final patternType = random.nextInt(4);
      
      switch (patternType) {
        case 0:
          _createIslandPattern(grid, gridSize, color, random);
          break;
        case 1:
          _createCorridorPattern(grid, gridSize, color, random);
          break;
        case 2:
          _createSpiralPattern(grid, gridSize, color, random);
          break;
        case 3:
          _createCheckerboardPattern(grid, gridSize, color, random);
          break;
      }
    }
  }

  /// Create isolated island patterns
  void _createIslandPattern(List<List<Color>> grid, int gridSize, Color color, Random random) {
    final centerX = random.nextInt(gridSize);
    final centerY = random.nextInt(gridSize);
    final radius = 1 + random.nextInt((gridSize / 3).round());
    
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final distance = math.sqrt(math.pow(i - centerX, 2) + math.pow(j - centerY, 2));
        if (distance <= radius && random.nextDouble() < 0.8) {
          grid[i][j] = color;
        }
      }
    }
  }

  /// Create corridor patterns
  void _createCorridorPattern(List<List<Color>> grid, int gridSize, Color color, Random random) {
    final isVertical = random.nextBool();
    final startPos = random.nextInt(gridSize);
    final width = 1 + random.nextInt(3);
    
    if (isVertical) {
      for (int i = 0; i < gridSize; i++) {
        for (int j = startPos; j < math.min(startPos + width, gridSize); j++) {
          if (random.nextDouble() < 0.9) {
            grid[i][j] = color;
          }
        }
      }
    } else {
      for (int i = startPos; i < math.min(startPos + width, gridSize); i++) {
        for (int j = 0; j < gridSize; j++) {
          if (random.nextDouble() < 0.9) {
            grid[i][j] = color;
          }
        }
      }
    }
  }

  /// Create spiral patterns
  void _createSpiralPattern(List<List<Color>> grid, int gridSize, Color color, Random random) {
    final centerX = gridSize ~/ 2;
    final centerY = gridSize ~/ 2;
    final maxRadius = math.min(centerX, centerY);
    
    for (int r = 0; r < maxRadius; r++) {
      for (int angle = 0; angle < 360; angle += 15) {
        final rad = angle * math.pi / 180;
        final x = centerX + (r * math.cos(rad)).round();
        final y = centerY + (r * math.sin(rad)).round();
        
        if (x >= 0 && x < gridSize && y >= 0 && y < gridSize && random.nextDouble() < 0.7) {
          grid[x][y] = color;
        }
      }
    }
  }

  /// Create checkerboard patterns
  void _createCheckerboardPattern(List<List<Color>> grid, int gridSize, Color color, Random random) {
    final startX = random.nextInt(gridSize);
    final startY = random.nextInt(gridSize);
    final size = 2 + random.nextInt(4);
    
    for (int i = startX; i < math.min(startX + size, gridSize); i++) {
      for (int j = startY; j < math.min(startY + size, gridSize); j++) {
        if ((i + j) % 2 == 0 && random.nextDouble() < 0.8) {
          grid[i][j] = color;
        }
      }
    }
  }

  /// Add strategic noise to make patterns less predictable - MUCH MORE AGGRESSIVE
  void _addStrategicNoise(List<List<Color>> grid, int gridSize, int level, Random random) {
    final noiseLevel = (level * 0.15).clamp(0.2, 0.5); // Increased from 0.1-0.3 to 0.2-0.5
    
    // Multiple noise passes for maximum scattering
    for (int pass = 0; pass < 2; pass++) {
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          if (random.nextDouble() < noiseLevel) {
            grid[i][j] = GameConstants.gameColors[random.nextInt(GameConstants.gameColors.length)];
          }
        }
      }
    }
    
    // Additional targeted noise to break up any remaining groups
    _breakUpRemainingGroups(grid, gridSize, random);
  }

  /// Break up any remaining color groups
  void _breakUpRemainingGroups(List<List<Color>> grid, int gridSize, Random random) {
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final currentColor = grid[i][j];
        int adjacentSameColor = 0;
        
        // Count adjacent same colors
        if (i > 0 && grid[i - 1][j] == currentColor) adjacentSameColor++;
        if (i < gridSize - 1 && grid[i + 1][j] == currentColor) adjacentSameColor++;
        if (j > 0 && grid[i][j - 1] == currentColor) adjacentSameColor++;
        if (j < gridSize - 1 && grid[i][j + 1] == currentColor) adjacentSameColor++;
        
        // If any adjacent same colors, change this cell
        if (adjacentSameColor > 0 && random.nextDouble() < 0.4) {
          final newColor = _getRandomDifferentColor(currentColor);
          grid[i][j] = newColor;
        }
      }
    }
  }

  /// Optimize the grid for maximum difficulty while keeping it solvable
  void _optimizeForDifficulty(List<List<Color>> grid, int gridSize, int level) {
    // Ensure the grid has a good distribution of colors
    final colorCounts = <Color, int>{};
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final color = grid[i][j];
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // If any color is too dominant, redistribute
    final totalCells = gridSize * gridSize;
    final maxColorCount = (totalCells * 0.6).round();
    
    for (final entry in colorCounts.entries) {
      if (entry.value > maxColorCount) {
        _redistributeColor(grid, gridSize, entry.key, entry.value - maxColorCount);
      }
    }
    
    // CRITICAL: Ensure no 4 same color cells are adjacent
    _preventFourAdjacentCells(grid, gridSize);
  }

  /// Ensure maximum 2 colors appear in adjacent cells for wild distribution
  void _preventFourAdjacentCells(List<List<Color>> grid, int gridSize) {
    bool hasAdjacent = true;
    int attempts = 0;
    final maxAttempts = 300; // More attempts for wild distribution
    
    while (hasAdjacent && attempts < maxAttempts) {
      hasAdjacent = false;
      attempts++;
      
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          final currentColor = grid[i][j];
          
          // Check horizontal 2-in-a-row and break any 3+ patterns
          if (j <= gridSize - 2) {
            if (grid[i][j] == currentColor && grid[i][j + 1] == currentColor) {
              // Found 2 in a row, check if there's a 3rd
              if (j <= gridSize - 3 && grid[i][j + 2] == currentColor) {
                // Break the pattern by changing middle cell
                final newColor = _getRandomDifferentColor(currentColor);
                grid[i][j + 1] = newColor;
                hasAdjacent = true;
              }
            }
          }
          
          // Check vertical 2-in-a-row and break any 3+ patterns
          if (i <= gridSize - 2) {
            if (grid[i][j] == currentColor && grid[i + 1][j] == currentColor) {
              // Found 2 in a row, check if there's a 3rd
              if (i <= gridSize - 3 && grid[i + 2][j] == currentColor) {
                // Break the pattern by changing middle cell
                final newColor = _getRandomDifferentColor(currentColor);
                grid[i + 1][j] = newColor;
                hasAdjacent = true;
              }
            }
          }
          
          // Ensure no 2x2 squares of same color
          if (i <= gridSize - 2 && j <= gridSize - 2) {
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
          _breakLShapes(grid, gridSize, i, j, currentColor);
        }
      }
    }
    
    // Additional pass to ensure maximum wild distribution
    _maximizeWildColorDistribution(grid, gridSize);
  }

  /// Break L-shaped patterns of same colors
  void _breakLShapes(List<List<Color>> grid, int gridSize, int i, int j, Color currentColor) {
    // Check for L-shapes and break them
    if (i < gridSize - 1 && j < gridSize - 1) {
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
  void _maximizeWildColorDistribution(List<List<Color>> grid, int gridSize) {
    final random = Random();
    bool changed = true;
    int attempts = 0;
    final maxAttempts = 1000; // More attempts for complete distribution
    
    // Keep iterating until perfect distribution
    while (changed && attempts < maxAttempts) {
      changed = false;
      attempts++;
      
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          final currentColor = grid[i][j];
          
          // Check all 8 adjacent cells (orthogonal + diagonal)
          bool hasAdjacentSame = false;
          
          // Check orthogonal neighbors (up, down, left, right)
          if (i > 0 && grid[i - 1][j] == currentColor) hasAdjacentSame = true;
          if (i < gridSize - 1 && grid[i + 1][j] == currentColor) hasAdjacentSame = true;
          if (j > 0 && grid[i][j - 1] == currentColor) hasAdjacentSame = true;
          if (j < gridSize - 1 && grid[i][j + 1] == currentColor) hasAdjacentSame = true;
          
          // Check diagonal neighbors (all 4 corners)
          if (i > 0 && j > 0 && grid[i - 1][j - 1] == currentColor) hasAdjacentSame = true;
          if (i > 0 && j < gridSize - 1 && grid[i - 1][j + 1] == currentColor) hasAdjacentSame = true;
          if (i < gridSize - 1 && j > 0 && grid[i + 1][j - 1] == currentColor) hasAdjacentSame = true;
          if (i < gridSize - 1 && j < gridSize - 1 && grid[i + 1][j + 1] == currentColor) hasAdjacentSame = true;
          
          // If any adjacent cell has the same color, change this cell to a color that's NOT adjacent
          if (hasAdjacentSame) {
            final newColor = _getBestDifferentColor(grid, gridSize, i, j, currentColor);
            grid[i][j] = newColor;
            changed = true;
          }
        }
      }
    }
  }
  
  /// Get the best color that's not adjacent AND helps balance color distribution
  Color _getBestDifferentColor(List<List<Color>> grid, int gridSize, int i, int j, Color currentColor) {
    // Get color counts to balance distribution
    final colorCounts = <Color, int>{};
    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        final color = grid[x][y];
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // Get adjacent colors to exclude
    final adjacentColors = <Color>{};
    
    // Check all 8 adjacent cells for colors to avoid
    if (i > 0) adjacentColors.add(grid[i - 1][j]);
    if (i < gridSize - 1) adjacentColors.add(grid[i + 1][j]);
    if (j > 0) adjacentColors.add(grid[i][j - 1]);
    if (j < gridSize - 1) adjacentColors.add(grid[i][j + 1]);
    if (i > 0 && j > 0) adjacentColors.add(grid[i - 1][j - 1]);
    if (i > 0 && j < gridSize - 1) adjacentColors.add(grid[i - 1][j + 1]);
    if (i < gridSize - 1 && j > 0) adjacentColors.add(grid[i + 1][j - 1]);
    if (i < gridSize - 1 && j < gridSize - 1) adjacentColors.add(grid[i + 1][j + 1]);
    
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
  void _redistributeColor(List<List<Color>> grid, int gridSize, Color color, int excessCount) {
    final random = Random();
    final cellsToChange = <Point<int>>[];
    
    // Find all cells with the excess color
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
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

  /// Calculate the optimal solution for a grid using advanced AI
  int calculateOptimalSolution(List<List<Color>> grid) {
    List<List<Color>> tempGrid = cloneGrid(grid);
    int solutionMoves = 0;
    final int bailout = grid.length * 8; // More generous bailout for complex puzzles

    while (!isGridSolved(tempGrid) && solutionMoves < bailout) {
      final bestMove = findBestMove(tempGrid);
      tempGrid = floodFillOnGrid(tempGrid, 0, 0, bestMove);
      solutionMoves++;
    }

    return solutionMoves >= bailout ? -1 : solutionMoves;
  }

  /// Calculate the AI-optimal solution with multiple strategies - ENHANCED ACCURACY
  int calculateAIOptimalSolution(List<List<Color>> grid) {
    final strategies = [
      _calculateGreedySolution,
      _calculateStrategicSolution,
      _calculateMinimaxSolution,
    ];
    
    int bestSolution = -1;
    
    for (final strategy in strategies) {
      final solution = strategy(grid);
      if (solution != -1 && (bestSolution == -1 || solution < bestSolution)) {
        bestSolution = solution;
      }
    }
    
    // If no strategy found a solution, try the original optimal solution
    if (bestSolution == -1) {
      bestSolution = calculateOptimalSolution(grid);
    }
    
    // No buffer - use exact AI solution for maximum challenge
    return bestSolution;
  }

  /// Greedy strategy: always choose the move that gains the most area
  int _calculateGreedySolution(List<List<Color>> grid) {
    List<List<Color>> tempGrid = cloneGrid(grid);
    int solutionMoves = 0;
    final int bailout = grid.length * 8; // More generous bailout for complex puzzles

    while (!isGridSolved(tempGrid) && solutionMoves < bailout) {
      final bestMove = findBestMove(tempGrid);
      tempGrid = floodFillOnGrid(tempGrid, 0, 0, bestMove);
      solutionMoves++;
    }

    return solutionMoves >= bailout ? -1 : solutionMoves;
  }

  /// Strategic strategy: considers future moves and color distribution
  int _calculateStrategicSolution(List<List<Color>> grid) {
    List<List<Color>> tempGrid = cloneGrid(grid);
    int solutionMoves = 0;
    final int bailout = grid.length * 8; // More generous bailout for complex puzzles

    while (!isGridSolved(tempGrid) && solutionMoves < bailout) {
      final bestMove = _findStrategicMove(tempGrid);
      tempGrid = floodFillOnGrid(tempGrid, 0, 0, bestMove);
      solutionMoves++;
    }

    return solutionMoves >= bailout ? -1 : solutionMoves;
  }

  /// Find a strategic move considering multiple factors
  Color _findStrategicMove(List<List<Color>> grid) {
    Color? bestColor;
    double bestScore = -1.0;
    final startColor = grid[0][0];

    for (final color in GameConstants.gameColors) {
      if (color == startColor) continue;
      
      final simulatedGrid = floodFillOnGrid(grid, 0, 0, color);
      final score = _calculateStrategicScore(grid, simulatedGrid, color);
      
      if (score > bestScore) {
        bestScore = score;
        bestColor = color;
      }
    }
    return bestColor!;
  }

  /// Calculate strategic score for a move
  double _calculateStrategicScore(List<List<Color>> originalGrid, List<List<Color>> newGrid, Color moveColor) {
    final gridSize = originalGrid.length;
    final totalCells = gridSize * gridSize;
    
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
    final gridSize = grid.length;
    
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final color = grid[i][j];
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // Calculate Shannon entropy
    double entropy = 0.0;
    final totalCells = gridSize * gridSize;
    
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
    final gridSize = grid.length;
    final totalCells = gridSize * gridSize;
    
    return currentArea / totalCells;
  }

  /// Calculate future move potential
  double _calculateFutureMovePotential(List<List<Color>> grid) {
    final startColor = grid[0][0];
    double maxPotential = 0.0;
    final gridSize = grid.length;
    final totalCells = gridSize * gridSize;
    
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
    // Ensure level is within valid range (1-14)
    final validLevel = level.clamp(1, GameConstants.maxLevel);
    final gridSize = GameConstants.levelGridSizes[validLevel] ?? GameConstants.baseGridSize;
    
    // Generate multiple grids and pick the most challenging one
    List<List<Color>> bestGrid = generateRandomGrid(validLevel);
    int bestSolutionMoves = -1;
    int bestDifficulty = -1;
    
    // Try multiple grids to find the most challenging one
    for (int attempt = 0; attempt < 5; attempt++) {
      final testGrid = generateRandomGrid(validLevel);
      final solutionMoves = calculateAIOptimalSolution(testGrid);
      
      if (solutionMoves != -1) {
        final difficulty = _calculateGridDifficulty(testGrid, solutionMoves);
        
        if (difficulty > bestDifficulty) {
          bestDifficulty = difficulty;
          bestSolutionMoves = solutionMoves;
          bestGrid = testGrid;
        }
      }
    }
    
    // If no good grid found, use the last generated one
    if (bestSolutionMoves == -1) {
      bestSolutionMoves = calculateOptimalSolution(bestGrid);
      if (bestSolutionMoves == -1) {
      return createGameConfig(validLevel);
      }
    }

    // Calculate precise max moves using AI intelligence
    final maxMoves = _calculatePreciseMaxMoves(validLevel, bestSolutionMoves, bestGrid);

    return GameConfig(
      level: validLevel,
      gridSize: gridSize,
      maxMoves: maxMoves,
      grid: bestGrid,
      originalGrid: cloneGrid(bestGrid),
    );
  }

  /// Calculate grid difficulty based on multiple factors
  int _calculateGridDifficulty(List<List<Color>> grid, int solutionMoves) {
    final gridSize = grid.length;
    final totalCells = gridSize * gridSize;
    
    // Base difficulty from solution moves
    int difficulty = solutionMoves * 10;
    
    // Add difficulty for color distribution complexity
    final colorDiversity = _calculateColorDiversity(grid);
    difficulty += (colorDiversity * 20).round();
    
    // Add difficulty for grid size
    difficulty += gridSize * 2;
    
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
    final gridSize = grid.length;
    double edgeScore = 0.0;
    
    // Check top and bottom edges
    for (int j = 0; j < gridSize; j++) {
      if (grid[0][j] == grid[gridSize - 1][j]) edgeScore += 0.5;
    }
    
    // Check left and right edges
    for (int i = 0; i < gridSize; i++) {
      if (grid[i][0] == grid[i][gridSize - 1]) edgeScore += 0.5;
    }
    
    return edgeScore / (gridSize * 2);
  }

  /// Calculate precise max moves using AI intelligence - CHALLENGING BUT FAIR
  int _calculatePreciseMaxMoves(int level, int solutionMoves, List<List<Color>> grid) {
    // Analyze the actual puzzle difficulty based on color distribution and patterns
    final puzzleDifficulty = _analyzePuzzleDifficulty(grid, solutionMoves);
    
    // Calculate extra moves based on actual puzzle complexity, not just level
    int extraMoves = _calculateExtraMovesBasedOnPuzzle(puzzleDifficulty, level);
    
    // Very tight bounds - maximum 3 extra moves for maximum challenge
    final minMoves = solutionMoves + 1; // Minimum 1 extra move
    final maxMovesCap = solutionMoves + 3; // Maximum 3 extra moves only!
    
    final finalMoves = solutionMoves + extraMoves;
    return finalMoves.clamp(minMoves, maxMovesCap);
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
    final gridSize = grid.length;
    
    // Count colors
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final color = grid[i][j];
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    
    // Calculate distribution variance (higher variance = more complex)
    final totalCells = gridSize * gridSize;
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
    final gridSize = grid.length;
    
    // Count isolated single cells (harder to solve)
    int isolatedCells = 0;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final currentColor = grid[i][j];
        int sameColorNeighbors = 0;
        
        // Count adjacent same colors
        if (i > 0 && grid[i - 1][j] == currentColor) sameColorNeighbors++;
        if (i < gridSize - 1 && grid[i + 1][j] == currentColor) sameColorNeighbors++;
        if (j > 0 && grid[i][j - 1] == currentColor) sameColorNeighbors++;
        if (j < gridSize - 1 && grid[i][j + 1] == currentColor) sameColorNeighbors++;
        
        if (sameColorNeighbors == 0) isolatedCells++;
      }
    }
    
    // Count color regions (more regions = more complex)
    final regionCount = _countIsolatedRegions(grid);
    
    // Calculate complexity score
    final totalCells = gridSize * gridSize;
    final isolatedScore = isolatedCells / totalCells;
    final regionScore = regionCount / GameConstants.gameColors.length;
    
    return (isolatedScore * 0.6 + regionScore * 0.4).clamp(0.0, 1.0);
  }

  /// Analyze how efficient the solution is compared to optimal
  double _analyzeSolutionEfficiency(List<List<Color>> grid, int solutionMoves) {
    // Calculate theoretical minimum moves needed
    final colorCounts = <Color, int>{};
    final gridSize = grid.length;
    
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
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
    final startColor = grid[0][0];
    return startColor != newColor;
  }

  /// Apply a move to the grid
  List<List<Color>> applyMove(List<List<Color>> grid, Color newColor) {
    return floodFillOnGrid(grid, 0, 0, newColor);
  }

  /// Get AI hint for the current grid state
  Color getAIHint(List<List<Color>> grid) {
    return findBestMove(grid);
  }

  /// Calculate move efficiency (how good a move was)
  double calculateMoveEfficiency(List<List<Color>> originalGrid, List<List<Color>> newGrid) {
    final originalArea = countCurrentArea(originalGrid);
    final newArea = countCurrentArea(newGrid);
    final gridSize = originalGrid.length;
    final totalCells = gridSize * gridSize;
    
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

import 'package:flutter/material.dart';

/// Game state enumeration
enum GameState {
  notStarted,
  playing,
  gameOver,
}

/// Game result enumeration
enum GameResult {
  win,
  lose,
}

/// Game configuration data class
class GameConfig {
  final int level;
  final int gridWidth;
  final int gridHeight;
  final int maxMoves;
  final List<List<Color>> grid;
  final List<List<Color>> originalGrid;

  const GameConfig({
    required this.level,
    required this.gridWidth,
    required this.gridHeight,
    required this.maxMoves,
    required this.grid,
    required this.originalGrid,
  });

  // Legacy support: gridSize returns width for backward compatibility
  int get gridSize => gridWidth;

  GameConfig copyWith({
    int? level,
    int? gridWidth,
    int? gridHeight,
    int? maxMoves,
    List<List<Color>>? grid,
    List<List<Color>>? originalGrid,
  }) {
    return GameConfig(
      level: level ?? this.level,
      gridWidth: gridWidth ?? this.gridWidth,
      gridHeight: gridHeight ?? this.gridHeight,
      maxMoves: maxMoves ?? this.maxMoves,
      grid: grid ?? this.grid,
      originalGrid: originalGrid ?? this.originalGrid,
    );
  }
}

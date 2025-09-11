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
  final int gridSize;
  final int maxMoves;
  final List<List<Color>> grid;
  final List<List<Color>> originalGrid;

  const GameConfig({
    required this.level,
    required this.gridSize,
    required this.maxMoves,
    required this.grid,
    required this.originalGrid,
  });

  GameConfig copyWith({
    int? level,
    int? gridSize,
    int? maxMoves,
    List<List<Color>>? grid,
    List<List<Color>>? originalGrid,
  }) {
    return GameConfig(
      level: level ?? this.level,
      gridSize: gridSize ?? this.gridSize,
      maxMoves: maxMoves ?? this.maxMoves,
      grid: grid ?? this.grid,
      originalGrid: originalGrid ?? this.originalGrid,
    );
  }
}

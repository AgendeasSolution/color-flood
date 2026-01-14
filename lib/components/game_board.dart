import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../utils/responsive_utils.dart';
import 'mahjong_icon.dart';

/// Game board component that displays the color grid
class GameBoard extends StatefulWidget {
  final List<List<Color>> grid;
  final int gridWidth;
  final int gridHeight;
  final bool gameStarted;

  const GameBoard({
    super.key,
    required this.grid,
    required this.gridWidth,
    required this.gridHeight,
    required this.gameStarted,
  });
  
  // Legacy support: gridSize returns width for backward compatibility
  int get gridSize => gridWidth;

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  late List<List<Color>> _previousGrid;

  @override
  void initState() {
    super.initState();
    // Validate grid before cloning
    if (widget.grid.isEmpty || widget.gridWidth <= 0 || widget.gridHeight <= 0) {
      _previousGrid = _createEmptyGrid();
    } else {
      _previousGrid = _cloneGrid(widget.grid);
    }
  }

  @override
  void didUpdateWidget(GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Validate current grid
    if (widget.grid.isEmpty || widget.gridWidth <= 0 || widget.gridHeight <= 0) {
      _previousGrid = _createEmptyGrid();
      return;
    }
    
    // If grid size changed (new level), update _previousGrid to match new grid
    // Otherwise, keep the old grid for animation purposes
    if (oldWidget.gridWidth != widget.gridWidth || 
        oldWidget.gridHeight != widget.gridHeight ||
        oldWidget.grid.length != widget.grid.length ||
        oldWidget.grid.isEmpty) {
      _previousGrid = _cloneGrid(widget.grid);
    } else {
      // Update previous grid to the OLD grid state before the change
      try {
        _previousGrid = _cloneGrid(oldWidget.grid);
      } catch (e) {
        // If cloning fails, use current grid
        _previousGrid = _cloneGrid(widget.grid);
      }
    }
  }

  List<List<Color>> _cloneGrid(List<List<Color>> grid) {
    if (grid.isEmpty) {
      return _createEmptyGrid();
    }
    try {
      return grid.map((row) => 
        row.isEmpty ? <Color>[] : List<Color>.from(row)
      ).toList();
    } catch (e) {
      return _createEmptyGrid();
    }
  }
  
  List<List<Color>> _createEmptyGrid() {
    final width = widget.gridWidth > 0 ? widget.gridWidth : 6;
    final height = widget.gridHeight > 0 ? widget.gridHeight : 6;
    return List.generate(
      height,
      (_) => List.generate(width, (_) => Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Validate grid and dimensions before building
      if (widget.grid.isEmpty || widget.gridWidth <= 0 || widget.gridHeight <= 0) {
        return _buildErrorPlaceholder();
      }
      
      // Validate grid dimensions match expected width and height
      if (widget.grid.length != widget.gridHeight ||
          (widget.grid.isNotEmpty && widget.grid[0].length != widget.gridWidth)) {
        return _buildErrorPlaceholder();
      }
      
      final boardPadding = ResponsiveUtils.getResponsiveSpacing(
        context,
        smallPhone: 8,
        mediumPhone: 10,
        largePhone: 12,
        tablet: 14,
      );
      
      // Calculate aspect ratio based on width and height
      final aspectRatio = widget.gridWidth / widget.gridHeight;
      
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          padding: EdgeInsets.all(boardPadding),
          child: widget.gameStarted
              ? GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.gridWidth,
                    crossAxisSpacing: 1.5,
                    mainAxisSpacing: 1.5,
                  ),
                  itemCount: widget.gridWidth * widget.gridHeight,
                  itemBuilder: (context, index) {
                    try {
                      final row = index ~/ widget.gridWidth;
                      final col = index % widget.gridWidth;
                      
                      // Validate indices before accessing
                      if (row < 0 || row >= widget.grid.length ||
                          col < 0 || col >= widget.grid[row].length) {
                        return Container(color: Colors.grey);
                      }
                      
                      // Validate previousGrid indices
                      Color currentColor;
                      Color previousColor;
                      
                      try {
                        currentColor = widget.grid[row][col];
                      } catch (e) {
                        currentColor = Colors.grey;
                      }
                      
                      try {
                        if (row < _previousGrid.length &&
                            col < _previousGrid[row].length) {
                          previousColor = _previousGrid[row][col];
                        } else {
                          previousColor = currentColor;
                        }
                      } catch (e) {
                        previousColor = currentColor;
                      }
                      
                      final isChanging = currentColor != previousColor;
                      
                      return _AnimatedCell(
                        color: currentColor,
                        previousColor: previousColor,
                        isChanging: isChanging,
                      );
                    } catch (e) {
                      // Return safe fallback cell
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }
                  },
                )
              : const SizedBox.shrink(),
        ),
      );
    } catch (e) {
      // Return error placeholder if build fails
      return _buildErrorPlaceholder();
    }
  }
  
  Widget _buildErrorPlaceholder() {
    final aspectRatio = widget.gridWidth > 0 && widget.gridHeight > 0
        ? widget.gridWidth / widget.gridHeight
        : 1.0;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.white54,
            size: 32,
          ),
        ),
      ),
    );
  }
}

/// Animated cell widget with swipe effect when color changes
class _AnimatedCell extends StatefulWidget {
  final Color color;
  final Color previousColor;
  final bool isChanging;

  const _AnimatedCell({
    required this.color,
    required this.previousColor,
    required this.isChanging,
  });

  @override
  State<_AnimatedCell> createState() => _AnimatedCellState();
}

class _AnimatedCellState extends State<_AnimatedCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: GameConstants.gameBoardAnimationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    // Start animation if color is changing
    if (widget.isChanging) {
      _controller.forward(from: 0.0);
    } else {
      _controller.value = 1.0; // Already at final state
    }
  }

  @override
  void didUpdateWidget(_AnimatedCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If color changed, restart animation
    if (widget.isChanging && oldWidget.color != widget.color) {
      _controller.reset();
      _controller.forward();
    } else if (!widget.isChanging) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = constraints.maxWidth;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
                // Previous color (base layer) with 3D gem effect
                _buildGemCell(
                  widget.previousColor,
                  cellSize,
                ),
                // New color with swipe animation and 3D gem effect
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: _animation.value,
                    child: _buildGemCell(
                      widget.color,
                      cellSize,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGemCell(Color baseColor, double cellSize) {
    final borderRadius = cellSize * 0.08;
    
    // Helper functions for color manipulation
    Color lightenColor(Color color, double amount) {
      final hsl = HSLColor.fromColor(color);
      final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
      return hsl.withLightness(lightness).toColor();
    }
    
    Color darkenColor(Color color, double amount) {
      final hsl = HSLColor.fromColor(color);
      final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
      return hsl.withLightness(lightness).toColor();
    }
    
    final tileColor = baseColor;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Deep shadow for strong 3D effect - bottom-right
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(cellSize * 0.04, cellSize * 0.04),
          ),
          // Medium shadow layer
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: -1,
            offset: Offset(cellSize * 0.02, cellSize * 0.02),
          ),
          // Inner glow with color
          BoxShadow(
            color: tileColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Base glass/ball layer with radial gradient (like color palette balls)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.2,
                  colors: [
                    lightenColor(tileColor, 0.2),
                    tileColor,
                    darkenColor(tileColor, 0.25),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            
            // Subtle border (like glass edge)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
            ),
            
            // Mahjong icon on top
            Center(
              child: MahjongIcon(
                color: Colors.white,
                size: cellSize * 0.55,
                iconType: MahjongIcon.getIconTypeForColor(baseColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

}



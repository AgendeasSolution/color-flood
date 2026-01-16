import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../utils/responsive_utils.dart';
import '../utils/color_utils.dart';
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
  late List<List<bool>> _escapeStates; // Track which tiles are escaping

  @override
  void initState() {
    super.initState();
    // Validate grid before cloning
    if (widget.grid.isEmpty || widget.gridWidth <= 0 || widget.gridHeight <= 0) {
      _previousGrid = _createEmptyGrid();
      _escapeStates = _createEmptyEscapeStates();
    } else {
      _previousGrid = _cloneGrid(widget.grid);
      _escapeStates = _createEmptyEscapeStates();
      _updateEscapeStates();
    }
  }

  @override
  void didUpdateWidget(GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Validate current grid
    if (widget.grid.isEmpty || widget.gridWidth <= 0 || widget.gridHeight <= 0) {
      _previousGrid = _createEmptyGrid();
      _escapeStates = _createEmptyEscapeStates();
      return;
    }
    
    // If grid size changed (new level), update _previousGrid to match new grid
    // Otherwise, keep the old grid for animation purposes
    if (oldWidget.gridWidth != widget.gridWidth || 
        oldWidget.gridHeight != widget.gridHeight ||
        oldWidget.grid.length != widget.grid.length ||
        oldWidget.grid.isEmpty) {
      _previousGrid = _cloneGrid(widget.grid);
      _escapeStates = _createEmptyEscapeStates();
    } else {
      // Update previous grid to the OLD grid state before the change
      try {
        _previousGrid = _cloneGrid(oldWidget.grid);
      } catch (e) {
        // If cloning fails, use current grid
        _previousGrid = _cloneGrid(widget.grid);
      }
    }
    
    // Update escape states when grid changes
    _updateEscapeStates();
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
  
  List<List<bool>> _createEmptyEscapeStates() {
    final width = widget.gridWidth > 0 ? widget.gridWidth : 6;
    final height = widget.gridHeight > 0 ? widget.gridHeight : 6;
    return List.generate(
      height,
      (_) => List.generate(width, (_) => false),
    );
  }
  
  /// Check if a tile should escape (unused tile - all existing neighbors have same color)
  /// A tile is "unused" if it can't help expand the flood area because all adjacent tiles are the same color
  bool _shouldEscape(int row, int col) {
    if (widget.grid.isEmpty) return false;
    if (row < 0 || row >= widget.grid.length) return false;
    if (col < 0 || col >= widget.grid[row].length) return false;
    
    final currentColor = widget.grid[row][col];
    
    // Check all four possible orthogonal neighbors
    final hasTopNeighbor = row > 0;
    final topColor = hasTopNeighbor ? widget.grid[row - 1][col] : null;
    
    final hasBottomNeighbor = row < widget.grid.length - 1;
    final bottomColor = hasBottomNeighbor ? widget.grid[row + 1][col] : null;
    
    final hasLeftNeighbor = col > 0;
    final leftColor = hasLeftNeighbor ? widget.grid[row][col - 1] : null;
    
    final hasRightNeighbor = col < widget.grid[row].length - 1;
    final rightColor = hasRightNeighbor ? widget.grid[row][col + 1] : null;
    
    // PRIMARY RULE: If ANY orthogonal neighbor has different color, don't escape
    if ((hasTopNeighbor && topColor != currentColor) ||
        (hasBottomNeighbor && bottomColor != currentColor) ||
        (hasLeftNeighbor && leftColor != currentColor) ||
        (hasRightNeighbor && rightColor != currentColor)) {
      return false;
    }
    
    // Special case 1: No top and left neighbors
    if (!hasTopNeighbor && !hasLeftNeighbor) {
      // Check if bottom and right both match
      if (hasBottomNeighbor && hasRightNeighbor &&
          bottomColor == currentColor && rightColor == currentColor) {
        return true;
      }
      
      // Also check left bottom diagonal (row+1, col-1)
      final hasLeftBottomDiagonal = (row + 1) < widget.grid.length && (col - 1) >= 0;
      if (hasLeftBottomDiagonal) {
        final leftBottomDiagonalColor = widget.grid[row + 1][col - 1];
        if (leftBottomDiagonalColor == currentColor) {
          return true;
        }
      }
    }
    
    // Special case 2: No top and right neighbors
    if (!hasTopNeighbor && !hasRightNeighbor) {
      // Check if bottom and left both match
      if (hasBottomNeighbor && hasLeftNeighbor &&
          bottomColor == currentColor && leftColor == currentColor) {
        return true;
      }
      
      // Also check right bottom diagonal (row+1, col+1)
      final hasRightBottomDiagonal = (row + 1) < widget.grid.length && 
                                     (col + 1) < widget.grid[row + 1].length;
      if (hasRightBottomDiagonal) {
        final rightBottomDiagonalColor = widget.grid[row + 1][col + 1];
        if (rightBottomDiagonalColor == currentColor) {
          return true;
        }
      }
    }
    
    // Special case 2b: No top neighbor, but right neighbor and right-bottom diagonal both match
    if (!hasTopNeighbor && hasRightNeighbor && rightColor == currentColor) {
      // Check right bottom diagonal (row+1, col+1)
      final hasRightBottomDiagonal = (row + 1) < widget.grid.length && 
                                     (col + 1) < widget.grid[row + 1].length;
      if (hasRightBottomDiagonal) {
        final rightBottomDiagonalColor = widget.grid[row + 1][col + 1];
        if (rightBottomDiagonalColor == currentColor) {
          return true;
        }
      }
    }
    
    // Special case 2c: No top neighbor, but left neighbor and left-bottom diagonal both match
    if (!hasTopNeighbor && hasLeftNeighbor && leftColor == currentColor) {
      // Check left bottom diagonal (row+1, col-1)
      final hasLeftBottomDiagonal = (row + 1) < widget.grid.length && (col - 1) >= 0;
      if (hasLeftBottomDiagonal) {
        final leftBottomDiagonalColor = widget.grid[row + 1][col - 1];
        if (leftBottomDiagonalColor == currentColor) {
          return true;
        }
      }
    }
    
    // Special case 3: No bottom and left neighbors
    if (!hasBottomNeighbor && !hasLeftNeighbor) {
      // Check if top and right both match
      if (hasTopNeighbor && hasRightNeighbor &&
          topColor == currentColor && rightColor == currentColor) {
        return true;
      }
    }
    
    // Special case 4: No bottom and right neighbors
    if (!hasBottomNeighbor && !hasRightNeighbor) {
      // Check if top and left both match
      if (hasTopNeighbor && hasLeftNeighbor &&
          topColor == currentColor && leftColor == currentColor) {
        return true;
      }
      
      // Also check top-right diagonal (row-1, col+1)
      final hasTopRightDiagonal = (row - 1) >= 0 && 
                                   (col + 1) < widget.grid[row - 1].length;
      if (hasTopRightDiagonal) {
        final topRightDiagonalColor = widget.grid[row - 1][col + 1];
        if (topRightDiagonalColor == currentColor) {
          return true;
        }
      }
    }
    
    // Special case 4b: No bottom and left neighbors
    if (!hasBottomNeighbor && !hasLeftNeighbor) {
      // Check top-left diagonal (row-1, col-1)
      final hasTopLeftDiagonal = (row - 1) >= 0 && (col - 1) >= 0;
      if (hasTopLeftDiagonal) {
        final topLeftDiagonalColor = widget.grid[row - 1][col - 1];
        if (topLeftDiagonalColor == currentColor) {
          return true;
        }
      }
    }
    
    // Special case 5: No top, left, or right neighbors
    if (!hasTopNeighbor && !hasLeftNeighbor && !hasRightNeighbor) {
      // Check bottom-left diagonal (row+1, col-1)
      if ((row + 1) < widget.grid.length && (col - 1) >= 0) {
        final bottomLeftDiagonalColor = widget.grid[row + 1][col - 1];
        if (bottomLeftDiagonalColor == currentColor) {
          return true; // Escape if left-bottom diagonal matches
        }
      }
      
      // Check bottom-right diagonal (row+1, col+1)
      if ((row + 1) < widget.grid.length && 
          (col + 1) < widget.grid[row + 1].length) {
        final bottomRightDiagonalColor = widget.grid[row + 1][col + 1];
        if (bottomRightDiagonalColor == currentColor) {
          return true; // Escape if right-bottom diagonal matches
        }
      }
    }
    
    // At this point, all existing orthogonal neighbors match (or don't exist)
    // Check if we have any orthogonal neighbors
    final hasAnyOrthogonalNeighbor = hasTopNeighbor || hasBottomNeighbor || 
                                     hasLeftNeighbor || hasRightNeighbor;
    
    // If no orthogonal neighbors exist, don't escape (isolated tile)
    if (!hasAnyOrthogonalNeighbor) return false;
    
    // Special case: If diagonal has different color, but its top and right/left match current tile
    // Check bottom-right diagonal (row+1, col+1)
    if ((row + 1) < widget.grid.length && 
        (col + 1) < widget.grid[row + 1].length) {
      final bottomRightDiagonalColor = widget.grid[row + 1][col + 1];
      if (bottomRightDiagonalColor != currentColor) {
        // Check the diagonal's top neighbor (row, col+1) - right neighbor of current tile
        final diagonalTopNeighbor = hasRightNeighbor ? rightColor : null;
        // Check the diagonal's right neighbor (row+1, col+2)
        final hasDiagonalRightNeighbor = (col + 2) < widget.grid[row + 1].length;
        final diagonalRightNeighbor = hasDiagonalRightNeighbor 
            ? widget.grid[row + 1][col + 2] 
            : null;
        // Check the diagonal's left neighbor (row+1, col) - bottom neighbor of current tile
        final diagonalLeftNeighbor = hasBottomNeighbor ? bottomColor : null;
        
        // If diagonal's top and right match current tile, escape
        if (diagonalTopNeighbor == currentColor && 
            diagonalRightNeighbor == currentColor) {
          return true;
        }
        // If diagonal's top and left match current tile, escape
        if (diagonalTopNeighbor == currentColor && 
            diagonalLeftNeighbor == currentColor) {
          return true;
        }
      }
    }
    
    // Check bottom-left diagonal (row+1, col-1)
    if ((row + 1) < widget.grid.length && (col - 1) >= 0) {
      final bottomLeftDiagonalColor = widget.grid[row + 1][col - 1];
      if (bottomLeftDiagonalColor != currentColor) {
        // Check the diagonal's top neighbor (row, col-1) - left neighbor of current tile
        final diagonalTopNeighbor = hasLeftNeighbor ? leftColor : null;
        // Check the diagonal's left neighbor (row+1, col-2)
        final hasDiagonalLeftNeighbor = (col - 2) >= 0;
        final diagonalLeftNeighbor = hasDiagonalLeftNeighbor 
            ? widget.grid[row + 1][col - 2] 
            : null;
        // Check the diagonal's right neighbor (row+1, col) - bottom neighbor of current tile
        final diagonalRightNeighbor = hasBottomNeighbor ? bottomColor : null;
        
        // If diagonal's top and left match current tile, escape
        if (diagonalTopNeighbor == currentColor && 
            diagonalLeftNeighbor == currentColor) {
          return true;
        }
        // If diagonal's top and right match current tile, escape
        if (diagonalTopNeighbor == currentColor && 
            diagonalRightNeighbor == currentColor) {
          return true;
        }
      }
    }
    
    // Check top-right diagonal (row-1, col+1)
    if ((row - 1) >= 0 && (col + 1) < widget.grid[row - 1].length) {
      final topRightDiagonalColor = widget.grid[row - 1][col + 1];
      if (topRightDiagonalColor != currentColor) {
        // Check the diagonal's bottom neighbor (row, col+1) - right neighbor of current tile
        final diagonalBottomNeighbor = hasRightNeighbor ? rightColor : null;
        // Check the diagonal's right neighbor (row-1, col+2)
        final hasDiagonalRightNeighbor = (col + 2) < widget.grid[row - 1].length;
        final diagonalRightNeighbor = hasDiagonalRightNeighbor 
            ? widget.grid[row - 1][col + 2] 
            : null;
        // Check the diagonal's left neighbor (row-1, col) - top neighbor of current tile
        final diagonalLeftNeighbor = hasTopNeighbor ? topColor : null;
        
        // If diagonal's bottom and right match current tile, escape
        if (diagonalBottomNeighbor == currentColor && 
            diagonalRightNeighbor == currentColor) {
          return true;
        }
        // If diagonal's bottom and left match current tile, escape
        if (diagonalBottomNeighbor == currentColor && 
            diagonalLeftNeighbor == currentColor) {
          return true;
        }
      }
    }
    
    // Check top-left diagonal (row-1, col-1)
    if ((row - 1) >= 0 && (col - 1) >= 0) {
      final topLeftDiagonalColor = widget.grid[row - 1][col - 1];
      if (topLeftDiagonalColor != currentColor) {
        // Check the diagonal's bottom neighbor (row, col-1) - left neighbor of current tile
        final diagonalBottomNeighbor = hasLeftNeighbor ? leftColor : null;
        // Check the diagonal's left neighbor (row-1, col-2)
        final hasDiagonalLeftNeighbor = (col - 2) >= 0;
        final diagonalLeftNeighbor = hasDiagonalLeftNeighbor 
            ? widget.grid[row - 1][col - 2] 
            : null;
        // Check the diagonal's right neighbor (row-1, col) - top neighbor of current tile
        final diagonalRightNeighbor = hasTopNeighbor ? topColor : null;
        
        // If diagonal's bottom and left match current tile, escape
        if (diagonalBottomNeighbor == currentColor && 
            diagonalLeftNeighbor == currentColor) {
          return true;
        }
        // If diagonal's bottom and right match current tile, escape
        if (diagonalBottomNeighbor == currentColor && 
            diagonalRightNeighbor == currentColor) {
          return true;
        }
      }
    }
    
    // Check diagonal neighbors - if any diagonal has different color, don't escape
    // Top-left diagonal (row-1, col-1)
    if ((row - 1) >= 0 && (col - 1) >= 0) {
      final topLeftDiagonalColor = widget.grid[row - 1][col - 1];
      if (topLeftDiagonalColor != currentColor) {
        return false; // Don't escape if any diagonal has different color
      }
    }
    
    // Top-right diagonal (row-1, col+1)
    if ((row - 1) >= 0 && (col + 1) < widget.grid[row - 1].length) {
      final topRightDiagonalColor = widget.grid[row - 1][col + 1];
      if (topRightDiagonalColor != currentColor) {
        return false; // Don't escape if any diagonal has different color
      }
    }
    
    // Bottom-left diagonal (row+1, col-1)
    if ((row + 1) < widget.grid.length && (col - 1) >= 0) {
      final bottomLeftDiagonalColor = widget.grid[row + 1][col - 1];
      if (bottomLeftDiagonalColor != currentColor) {
        return false; // Don't escape if any diagonal has different color
      }
    }
    
    // Bottom-right diagonal (row+1, col+1)
    if ((row + 1) < widget.grid.length && 
        (col + 1) < widget.grid[row + 1].length) {
      final bottomRightDiagonalColor = widget.grid[row + 1][col + 1];
      if (bottomRightDiagonalColor != currentColor) {
        return false; // Don't escape if any diagonal has different color
      }
    }
    
    // All orthogonal neighbors match and all diagonal neighbors match (or don't exist)
    // Tile should escape
    return true;
  }
  
  /// Update escape states for all tiles
  void _updateEscapeStates() {
    if (widget.grid.isEmpty || widget.gridWidth <= 0 || widget.gridHeight <= 0) {
      _escapeStates = _createEmptyEscapeStates();
      return;
    }
    
    // Reset escape states
    _escapeStates = _createEmptyEscapeStates();
    
    // Check if all tiles have the same color (game solved)
    bool allTilesSameColor = true;
    if (widget.grid.isNotEmpty && widget.grid[0].isNotEmpty) {
      final firstColor = widget.grid[0][0];
      for (int row = 0; row < widget.grid.length; row++) {
        for (int col = 0; col < widget.grid[row].length; col++) {
          if (widget.grid[row][col] != firstColor) {
            allTilesSameColor = false;
            break;
          }
        }
        if (!allTilesSameColor) break;
      }
    }
    
    // If all tiles are the same color, make all tiles escape
    if (allTilesSameColor) {
      for (int row = 0; row < widget.grid.length; row++) {
        for (int col = 0; col < widget.grid[row].length; col++) {
          _escapeStates[row][col] = true;
        }
      }
    } else {
      // Otherwise, check each tile to see if it should escape normally
      for (int row = 0; row < widget.grid.length; row++) {
        for (int col = 0; col < widget.grid[row].length; col++) {
          if (_shouldEscape(row, col)) {
            _escapeStates[row][col] = true;
          }
        }
      }
    }
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
                      
                      // Check if this tile should escape
                      bool isEscaping = false;
                      try {
                        if (row < _escapeStates.length && col < _escapeStates[row].length) {
                          isEscaping = _escapeStates[row][col];
                        }
                      } catch (e) {
                        isEscaping = false;
                      }
                      
                      return _AnimatedCell(
                        color: currentColor,
                        previousColor: previousColor,
                        isChanging: isChanging,
                        isEscaping: isEscaping,
                        row: row,
                        col: col,
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
  final bool isEscaping;
  final int row;
  final int col;

  const _AnimatedCell({
    required this.color,
    required this.previousColor,
    required this.isChanging,
    required this.isEscaping,
    required this.row,
    required this.col,
  });

  @override
  State<_AnimatedCell> createState() => _AnimatedCellState();
}

class _AnimatedCellState extends State<_AnimatedCell>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _escapeController;
  late Animation<double> _animation;
  late Animation<double> _escapeAnimation;
  bool _hasEscaped = false;

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
    
    // Escape animation controller
    _escapeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _escapeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _escapeController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animation if color is changing
    if (widget.isChanging) {
      _controller.forward(from: 0.0);
    } else {
      _controller.value = 1.0; // Already at final state
    }
    
    // Start escape animation if tile should escape
    if (widget.isEscaping && !_hasEscaped) {
      _startEscapeAnimation();
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
    
    // Handle escape animation
    if (widget.isEscaping && !oldWidget.isEscaping && !_hasEscaped) {
      _startEscapeAnimation();
    } else if (!widget.isEscaping && oldWidget.isEscaping) {
      // Reset escape state if tile no longer should escape
      _hasEscaped = false;
      _escapeController.reset();
    }
  }
  
  void _startEscapeAnimation() {
    if (_hasEscaped) return;
    
    // Add delay based on position for staggered effect
    final delay = (widget.row + widget.col) * 30; // 30ms delay per position
    
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted && widget.isEscaping) {
        _escapeController.forward().then((_) {
          if (mounted) {
            setState(() {
              _hasEscaped = true;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _escapeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = constraints.maxWidth;
        
        // If tile has escaped, return empty container
        if (_hasEscaped) {
          return const SizedBox.shrink();
        }
        
        return AnimatedBuilder(
          animation: Listenable.merge([_animation, _escapeAnimation]),
          builder: (context, child) {
            return Opacity(
              opacity: _escapeAnimation.value,
              child: Transform.scale(
                scale: _escapeAnimation.value,
                child: Stack(
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGemCell(Color baseColor, double cellSize) {
    final borderRadius = cellSize * 0.08;
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
                    ColorUtils.lightenColor(tileColor, 0.2),
                    tileColor,
                    ColorUtils.darkenColor(tileColor, 0.25),
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



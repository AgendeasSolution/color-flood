import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../utils/responsive_utils.dart';

/// Game board component that displays the color grid
class GameBoard extends StatefulWidget {
  final List<List<Color>> grid;
  final int gridSize;
  final bool gameStarted;

  const GameBoard({
    super.key,
    required this.grid,
    required this.gridSize,
    required this.gameStarted,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  late List<List<Color>> _previousGrid;

  @override
  void initState() {
    super.initState();
    // Validate grid before cloning
    if (widget.grid.isEmpty || widget.gridSize <= 0) {
      _previousGrid = _createEmptyGrid();
    } else {
      _previousGrid = _cloneGrid(widget.grid);
    }
  }

  @override
  void didUpdateWidget(GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Validate current grid
    if (widget.grid.isEmpty || widget.gridSize <= 0) {
      _previousGrid = _createEmptyGrid();
      return;
    }
    
    // If grid size changed (new level), update _previousGrid to match new grid
    // Otherwise, keep the old grid for animation purposes
    if (oldWidget.gridSize != widget.gridSize || 
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
    final size = widget.gridSize > 0 ? widget.gridSize : 6;
    return List.generate(
      size,
      (_) => List.generate(size, (_) => Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Validate grid and gridSize before building
      if (widget.grid.isEmpty || widget.gridSize <= 0) {
        return _buildErrorPlaceholder();
      }
      
      // Validate grid dimensions match gridSize
      if (widget.grid.length != widget.gridSize ||
          (widget.grid.isNotEmpty && widget.grid[0].length != widget.gridSize)) {
        return _buildErrorPlaceholder();
      }
      
      final boardPadding = ResponsiveUtils.getResponsiveSpacing(
        context,
        smallPhone: 8,
        mediumPhone: 10,
        largePhone: 12,
        tablet: 14,
      );
      
      return AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          padding: EdgeInsets.all(boardPadding),
          decoration: BoxDecoration(
            gradient: widget.gameStarted
                ? LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.gameStarted 
                ? null 
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: widget.gameStarted 
                ? Border.all(color: Colors.white.withOpacity(0.2))
                : null,
          ),
          child: widget.gameStarted
              ? GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.gridSize,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
                  ),
                  itemCount: widget.gridSize * widget.gridSize,
                  itemBuilder: (context, index) {
                    try {
                      final row = index ~/ widget.gridSize;
                      final col = index % widget.gridSize;
                      
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
    return AspectRatio(
      aspectRatio: 1.0,
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Previous color (base layer)
            Container(
              decoration: BoxDecoration(
                color: widget.previousColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            // New color with swipe animation
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: _animation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

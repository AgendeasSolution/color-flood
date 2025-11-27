import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../utils/responsive_utils.dart';

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
          decoration: BoxDecoration(
            gradient: widget.gameStarted
                ? LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.2),
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
                ? Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 2,
                  )
                : null,
            boxShadow: widget.gameStarted
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: widget.gameStarted
              ? GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.gridWidth,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
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
    final bevelSize = cellSize * 0.14; // Optimized bevel size for perfect 3D effect
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cellSize * 0.12),
        boxShadow: [
          // Deep shadow for dramatic 3D effect
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 10,
            spreadRadius: -3,
            offset: const Offset(0, 5),
          ),
          // Medium shadow layer
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: -1,
            offset: const Offset(0, 2),
          ),
          // Inner glow with color
          BoxShadow(
            color: baseColor.withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 1.5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cellSize * 0.12),
        child: CustomPaint(
          painter: _FacetedGemPainter(
            baseColor: baseColor,
            cellSize: cellSize,
            bevelSize: bevelSize,
          ),
          child: Container(),
        ),
      ),
    );
  }

  Color _lightenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Color _darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}

/// Custom painter for faceted 3D gem cells
class _FacetedGemPainter extends CustomPainter {
  final Color baseColor;
  final double cellSize;
  final double bevelSize;

  _FacetedGemPainter({
    required this.baseColor,
    required this.cellSize,
    required this.bevelSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerSize = cellSize - (bevelSize * 2);
    final innerOffset = bevelSize * 0.65; // Inner edge of bevel for 3D perspective
    
    // Helper function to lighten color with saturation boost
    Color lightenColor(Color color, double amount) {
      final hsl = HSLColor.fromColor(color);
      final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
      final saturation = (hsl.saturation * 1.1).clamp(0.0, 1.0); // Boost saturation
      return hsl.withLightness(lightness).withSaturation(saturation).toColor();
    }
    
    // Helper function to darken color
    Color darkenColor(Color color, double amount) {
      final hsl = HSLColor.fromColor(color);
      final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
      return hsl.withLightness(lightness).toColor();
    }
    
    // Helper to blend colors
    Color blendColor(Color c1, Color c2, double ratio) {
      return Color.lerp(c1, c2, ratio)!;
    }

    // Base background with rich gradient for depth
    final baseGradient = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          darkenColor(baseColor, 0.2),
          darkenColor(baseColor, 0.15),
          darkenColor(baseColor, 0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromLTWH(0, 0, cellSize, cellSize),
      );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, cellSize, cellSize),
        Radius.circular(cellSize * 0.12),
      ),
      baseGradient,
    );

    // Central square facet (main raised surface) - the jewel's face
    final centerLeft = bevelSize;
    final centerTop = bevelSize;
    final centerRight = cellSize - bevelSize;
    final centerBottom = cellSize - bevelSize;
    
    // Central facet with rich, multi-stop gradient for realistic depth
    final centerGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          lightenColor(baseColor, 0.3),
          lightenColor(baseColor, 0.15),
          baseColor,
          darkenColor(baseColor, 0.15),
          darkenColor(baseColor, 0.3),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(
        Rect.fromLTWH(centerLeft, centerTop, centerSize, centerSize),
      );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerLeft, centerTop, centerSize, centerSize),
        Radius.circular(cellSize * 0.12),
      ),
      centerGradient,
    );

    // Primary light source highlight (top-left, bright and focused)
    final primaryHighlight = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 0.65,
        colors: [
          Colors.white.withOpacity(0.8),
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.2),
          blendColor(Colors.white, baseColor, 0.3).withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(
        Rect.fromLTWH(centerLeft, centerTop, centerSize * 0.7, centerSize * 0.7),
      );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerLeft, centerTop, centerSize * 0.7, centerSize * 0.7),
        Radius.circular(cellSize * 0.12),
      ),
      primaryHighlight,
    );

    // Secondary highlight (top-right, softer)
    final secondaryHighlight = Paint()
      ..shader = RadialGradient(
        center: Alignment.topRight,
        radius: 0.5,
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromLTWH(centerLeft + centerSize * 0.3, centerTop, centerSize * 0.5, centerSize * 0.5),
      );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerLeft + centerSize * 0.3, centerTop, centerSize * 0.5, centerSize * 0.5),
        Radius.circular(cellSize * 0.12),
      ),
      secondaryHighlight,
    );

    // Inner glow for depth
    final innerGlow = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          Colors.transparent,
          baseColor.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromLTWH(centerLeft, centerTop, centerSize, centerSize),
      );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerLeft, centerTop, centerSize, centerSize),
        Radius.circular(cellSize * 0.12),
      ),
      innerGlow,
    );

    // Top trapezoidal facet (brightest, catches main light)
    final topFacetPath = Path()
      ..moveTo(bevelSize, bevelSize)
      ..lineTo(cellSize - bevelSize, bevelSize)
      ..lineTo(cellSize - innerOffset, innerOffset)
      ..lineTo(innerOffset, innerOffset)
      ..close();
    
    final topFacetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.7),
          Colors.white.withOpacity(0.4),
          blendColor(Colors.white, baseColor, 0.5).withOpacity(0.3),
          lightenColor(baseColor, 0.15).withOpacity(0.5),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(
        Rect.fromLTWH(0, 0, cellSize, bevelSize),
      );
    
    canvas.drawPath(topFacetPath, topFacetPaint);

    // Bottom trapezoidal facet (deepest shadow, most dramatic)
    final bottomFacetPath = Path()
      ..moveTo(innerOffset, cellSize - innerOffset)
      ..lineTo(cellSize - innerOffset, cellSize - innerOffset)
      ..lineTo(cellSize - bevelSize, cellSize - bevelSize)
      ..lineTo(bevelSize, cellSize - bevelSize)
      ..close();
    
    final bottomFacetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          baseColor.withOpacity(0.5),
          darkenColor(baseColor, 0.35).withOpacity(0.85),
          darkenColor(baseColor, 0.5).withOpacity(0.95),
          Colors.black.withOpacity(0.3),
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(
        Rect.fromLTWH(0, cellSize - bevelSize, cellSize, bevelSize),
      );
    
    canvas.drawPath(bottomFacetPath, bottomFacetPaint);

    // Left trapezoidal facet (bright side, catches light)
    final leftFacetPath = Path()
      ..moveTo(bevelSize, bevelSize)
      ..lineTo(innerOffset, innerOffset)
      ..lineTo(innerOffset, cellSize - innerOffset)
      ..lineTo(bevelSize, cellSize - bevelSize)
      ..close();
    
    final leftFacetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.55),
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.1),
          lightenColor(baseColor, 0.1).withOpacity(0.4),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(
        Rect.fromLTWH(0, 0, bevelSize, cellSize),
      );
    
    canvas.drawPath(leftFacetPath, leftFacetPaint);

    // Right trapezoidal facet (shadow side, away from light)
    final rightFacetPath = Path()
      ..moveTo(cellSize - bevelSize, bevelSize)
      ..lineTo(cellSize - bevelSize, cellSize - bevelSize)
      ..lineTo(cellSize - innerOffset, cellSize - innerOffset)
      ..lineTo(cellSize - innerOffset, innerOffset)
      ..close();
    
    final rightFacetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          darkenColor(baseColor, 0.4).withOpacity(0.8),
          darkenColor(baseColor, 0.25).withOpacity(0.65),
          darkenColor(baseColor, 0.1).withOpacity(0.5),
          baseColor.withOpacity(0.4),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(
        Rect.fromLTWH(cellSize - bevelSize, 0, bevelSize, cellSize),
      );
    
    canvas.drawPath(rightFacetPath, rightFacetPaint);
    
    // Professional facet separation lines (subtle but defined)
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    
    // Top facet separation
    canvas.drawLine(
      Offset(bevelSize, bevelSize),
      Offset(cellSize - bevelSize, bevelSize),
      linePaint,
    );
    // Bottom facet separation
    canvas.drawLine(
      Offset(bevelSize, cellSize - bevelSize),
      Offset(cellSize - bevelSize, cellSize - bevelSize),
      linePaint,
    );
    // Left facet separation
    canvas.drawLine(
      Offset(bevelSize, bevelSize),
      Offset(bevelSize, cellSize - bevelSize),
      linePaint,
    );
    // Right facet separation
    canvas.drawLine(
      Offset(cellSize - bevelSize, bevelSize),
      Offset(cellSize - bevelSize, cellSize - bevelSize),
      linePaint,
    );

    // Top-left triangular corner facet (brightest corner, catches primary light)
    final topLeftCornerPath = Path()
      ..moveTo(0, 0)
      ..lineTo(bevelSize, bevelSize)
      ..lineTo(innerOffset, innerOffset)
      ..lineTo(innerOffset, 0)
      ..lineTo(0, innerOffset)
      ..close();
    
    final topLeftCornerPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.1,
        colors: [
          Colors.white.withOpacity(0.85),
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.3),
          blendColor(Colors.white, baseColor, 0.4).withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(
        Rect.fromLTWH(0, 0, bevelSize, bevelSize),
      );
    
    canvas.drawPath(topLeftCornerPath, topLeftCornerPaint);

    // Top-right triangular corner facet (bright, secondary light)
    final topRightCornerPath = Path()
      ..moveTo(cellSize, 0)
      ..lineTo(cellSize, innerOffset)
      ..lineTo(cellSize - innerOffset, innerOffset)
      ..lineTo(cellSize - bevelSize, bevelSize)
      ..lineTo(cellSize - innerOffset, 0)
      ..close();
    
    final topRightCornerPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topRight,
        radius: 1.1,
        colors: [
          Colors.white.withOpacity(0.8),
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.25),
          blendColor(Colors.white, baseColor, 0.3).withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(
        Rect.fromLTWH(cellSize - bevelSize, 0, bevelSize, bevelSize),
      );
    
    canvas.drawPath(topRightCornerPath, topRightCornerPaint);

    // Bottom-left triangular corner facet (medium shadow, some reflected light)
    final bottomLeftCornerPath = Path()
      ..moveTo(0, cellSize)
      ..lineTo(0, cellSize - innerOffset)
      ..lineTo(innerOffset, cellSize - innerOffset)
      ..lineTo(bevelSize, cellSize - bevelSize)
      ..lineTo(innerOffset, cellSize)
      ..close();
    
    final bottomLeftCornerPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomLeft,
        radius: 1.0,
        colors: [
          darkenColor(baseColor, 0.25).withOpacity(0.6),
          darkenColor(baseColor, 0.15).withOpacity(0.4),
          baseColor.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(
        Rect.fromLTWH(0, cellSize - bevelSize, bevelSize, bevelSize),
      );
    
    canvas.drawPath(bottomLeftCornerPath, bottomLeftCornerPaint);

    // Bottom-right triangular corner facet (darkest shadow, deepest corner)
    final bottomRightCornerPath = Path()
      ..moveTo(cellSize, cellSize)
      ..lineTo(cellSize - innerOffset, cellSize)
      ..lineTo(cellSize - bevelSize, cellSize - bevelSize)
      ..lineTo(cellSize - innerOffset, cellSize - innerOffset)
      ..lineTo(cellSize, cellSize - innerOffset)
      ..close();
    
    final bottomRightCornerPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomRight,
        radius: 1.0,
        colors: [
          darkenColor(baseColor, 0.5).withOpacity(0.85),
          darkenColor(baseColor, 0.35).withOpacity(0.7),
          darkenColor(baseColor, 0.2).withOpacity(0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(
        Rect.fromLTWH(cellSize - bevelSize, cellSize - bevelSize, bevelSize, bevelSize),
      );
    
    canvas.drawPath(bottomRightCornerPath, bottomRightCornerPaint);

    // Professional glass effect overlay (frosted glass with diagonal reflection)
    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.12),
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(
        Rect.fromLTWH(0, 0, cellSize, cellSize),
      );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, cellSize, cellSize),
        Radius.circular(cellSize * 0.12),
      ),
      glassPaint,
    );

    // Professional border with subtle highlight
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, cellSize - 2, cellSize - 2),
        Radius.circular(cellSize * 0.12),
      ),
      borderPaint,
    );
    
    // Subtle inner border for extra definition
    final innerBorderPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1.5, 1.5, cellSize - 3, cellSize - 3),
        Radius.circular(cellSize * 0.12),
      ),
      innerBorderPaint,
    );
  }

  @override
  bool shouldRepaint(_FacetedGemPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.bevelSize != bevelSize;
  }
}

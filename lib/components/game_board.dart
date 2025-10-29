import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../utils/responsive_utils.dart';

/// Game board component that displays the color grid
class GameBoard extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
          gradient: gameStarted
              ? LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: gameStarted 
              ? null 
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: gameStarted 
              ? Border.all(color: Colors.white.withOpacity(0.2))
              : null,
        ),
        child: gameStarted
            ? GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                ),
                itemCount: gridSize * gridSize,
                itemBuilder: (context, index) {
                  final row = index ~/ gridSize;
                  final col = index % gridSize;
                  return AnimatedContainer(
                    duration: GameConstants.gameBoardAnimationDuration,
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: grid[row][col],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }
}

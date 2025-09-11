import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../services/level_progression_service.dart';
import 'hexagon_widget.dart';

/// Level selection grid component showing levels 1-14
class LevelSelectionGrid extends StatelessWidget {
  final Function(int level) onLevelSelected;
  final int selectedLevel;
  final Map<int, LevelStatus> levelStatuses;
  final Widget? customHeader;

  const LevelSelectionGrid({
    super.key,
    required this.onLevelSelected,
    required this.selectedLevel,
    required this.levelStatuses,
    this.customHeader,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom Header or Default Title
        customHeader ?? const Text(
          'Select Level',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: GameConstants.mediumSpacing),
        
        // Level Grid - Hexagonal Layout with Scrolling
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 16, // Increased gap between rows
              childAspectRatio: 1.0, // Adjusted for better hexagonal proportions
            ),
            itemCount: GameConstants.maxLevel,
            itemBuilder: (context, index) {
              final level = index + 1;
              final status = levelStatuses[level] ?? LevelStatus.locked;
              return _buildHexagonalLevelButton(level, level == selectedLevel, status);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHexagonalLevelButton(int level, bool isSelected, LevelStatus status) {
    final isLocked = status == LevelStatus.locked;
    final isCompleted = status == LevelStatus.completed;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: HexagonWidget(
        size: 60,
        colors: _getLevelButtonColors(isSelected, status),
        borderColor: _getLevelButtonBorderColor(isSelected, status),
        borderWidth: isSelected ? 3.0 : 1.5,
        shadows: [
          BoxShadow(
            color: _getLevelButtonShadowColor(isSelected, status),
            blurRadius: isSelected ? 25 : 15,
            spreadRadius: isSelected ? 3 : 1,
            offset: const Offset(0, 8),
          ),
          if (isSelected)
            BoxShadow(
              color: _getLevelButtonShadowColor(isSelected, status).withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: -8,
              offset: const Offset(0, 15),
            ),
          // Inner glow effect
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
        onTap: isLocked ? null : () => onLevelSelected(level),
        child: _buildHexagonalLevelContent(level, isSelected, status),
      ),
    );
  }

  Widget _buildLevelButton(int level, bool isSelected, LevelStatus status) {
    final isLocked = status == LevelStatus.locked;
    final isCompleted = status == LevelStatus.completed;
    
    return GestureDetector(
      onTap: isLocked ? null : () => onLevelSelected(level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getLevelButtonColors(isSelected, status),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getLevelButtonBorderColor(isSelected, status),
                  width: isSelected ? 3.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getLevelButtonShadowColor(isSelected, status),
                    blurRadius: isSelected ? 20 : 12,
                    spreadRadius: isSelected ? 2 : 0,
                    offset: const Offset(0, 6),
                  ),
                  if (isSelected)
                    BoxShadow(
                      color: _getLevelButtonShadowColor(isSelected, status).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: -5,
                      offset: const Offset(0, 12),
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // Glowing effect for selected level
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.transparent,
                            ],
                            radius: 0.8,
                          ),
                        ),
                      ),
                    ),
                  
                  // Main content
                  Center(
                    child: _buildLevelButtonContent(level, isSelected, status),
                  ),
                  
                  // Animated border effect for selected level
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getLevelButtonColors(bool isSelected, LevelStatus status) {
    if (isSelected) {
      return [
        const Color(0xFFEF4444).withOpacity(0.9),
        const Color(0xFFEC4899).withOpacity(0.7),
        const Color(0xFF3B82F6).withOpacity(0.9),
        const Color(0xFF8B5CF6).withOpacity(0.8),
      ];
    }
    
    switch (status) {
      case LevelStatus.completed:
        return [
          const Color(0xFF22C55E).withOpacity(0.9),
          const Color(0xFF10B981).withOpacity(0.7),
          const Color(0xFF059669).withOpacity(0.8),
        ];
      case LevelStatus.unlocked:
        return [
          const Color(0xFF6366F1).withOpacity(0.3),
          const Color(0xFF8B5CF6).withOpacity(0.2),
          const Color(0xFFEC4899).withOpacity(0.2),
        ];
      case LevelStatus.locked:
        return [
          const Color(0xFF374151).withOpacity(0.4),
          const Color(0xFF1F2937).withOpacity(0.3),
        ];
    }
  }

  Color _getLevelButtonBorderColor(bool isSelected, LevelStatus status) {
    if (isSelected) {
      return Colors.white.withOpacity(0.9);
    }
    
    switch (status) {
      case LevelStatus.completed:
        return const Color(0xFF22C55E).withOpacity(0.9);
      case LevelStatus.unlocked:
        return const Color(0xFF6366F1).withOpacity(0.5);
      case LevelStatus.locked:
        return const Color(0xFF374151).withOpacity(0.6);
    }
  }

  Color _getLevelButtonShadowColor(bool isSelected, LevelStatus status) {
    if (isSelected) {
      return const Color(0xFFEF4444).withOpacity(0.4);
    }
    
    switch (status) {
      case LevelStatus.completed:
        return const Color(0xFF22C55E).withOpacity(0.4);
      case LevelStatus.unlocked:
        return const Color(0xFF6366F1).withOpacity(0.2);
      case LevelStatus.locked:
        return Colors.black.withOpacity(0.1);
    }
  }

  Widget _buildHexagonalLevelContent(int level, bool isSelected, LevelStatus status) {
    if (status == LevelStatus.locked) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.grey.withOpacity(0.4),
              Colors.grey.withOpacity(0.2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.lock,
          color: Colors.grey,
          size: 18,
        ),
      );
    }
    
    if (status == LevelStatus.completed) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF22C55E),
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            level.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isSelected ? 20 : 18,
              fontWeight: FontWeight.bold,
              shadows: [
                const Shadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
                if (isSelected)
                  const Shadow(
                    color: Colors.white,
                    blurRadius: 8,
                    offset: Offset(0, 0),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    
    // Unlocked but not completed
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        level.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: isSelected ? 22 : 20,
          fontWeight: FontWeight.bold,
          shadows: [
            const Shadow(
              color: Colors.black54,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
            if (isSelected)
              const Shadow(
                color: Colors.white,
                blurRadius: 8,
                offset: Offset(0, 0),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelButtonContent(int level, bool isSelected, LevelStatus status) {
    if (status == LevelStatus.locked) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withOpacity(0.3),
            ),
            child: const Icon(
              Icons.lock,
              color: Colors.grey,
              size: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            level.toString(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    
    if (status == LevelStatus.completed) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF22C55E),
              size: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            level.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isSelected ? 22 : 20,
              fontWeight: FontWeight.bold,
              shadows: [
                const Shadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
                if (isSelected)
                  const Shadow(
                    color: Colors.white,
                    blurRadius: 8,
                    offset: Offset(0, 0),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    
    // Unlocked but not completed
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        level.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: isSelected ? 22 : 20,
          fontWeight: FontWeight.bold,
          shadows: [
            const Shadow(
              color: Colors.black54,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
            if (isSelected)
              const Shadow(
                color: Colors.white,
                blurRadius: 8,
                offset: Offset(0, 0),
              ),
          ],
        ),
      ),
    );
  }
}

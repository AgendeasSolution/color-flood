import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../services/level_progression_service.dart';
import 'hexagon_widget.dart';

/// Level selection grid component showing levels 1-12
class LevelSelectionGrid extends StatelessWidget {
  final Function(int level) onLevelSelected;
  final Map<int, LevelStatus> levelStatuses;
  final Widget? customHeader;

  const LevelSelectionGrid({
    super.key,
    required this.onLevelSelected,
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
              return _buildHexagonalLevelButton(level, status);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHexagonalLevelButton(int level, LevelStatus status) {
    final isLocked = status == LevelStatus.locked;
    final isCompleted = status == LevelStatus.completed;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: HexagonWidget(
        size: 60,
        colors: _getLevelButtonColors(status),
        borderColor: _getLevelButtonBorderColor(status),
        borderWidth: 1.5,
        shadows: [
          BoxShadow(
            color: _getLevelButtonShadowColor(status),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 8),
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
        child: _buildHexagonalLevelContent(level, status),
      ),
    );
  }


  List<Color> _getLevelButtonColors(LevelStatus status) {
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
          const Color(0xFF4B5563).withOpacity(0.6), // Slightly brighter
          const Color(0xFF374151).withOpacity(0.5),
          const Color(0xFF1F2937).withOpacity(0.4),
        ];
    }
  }

  Color _getLevelButtonBorderColor(LevelStatus status) {
    switch (status) {
      case LevelStatus.completed:
        return const Color(0xFF22C55E).withOpacity(0.9);
      case LevelStatus.unlocked:
        return const Color(0xFF6366F1).withOpacity(0.5);
      case LevelStatus.locked:
        return const Color(0xFF6B7280).withOpacity(0.8); // Brighter border
    }
  }

  Color _getLevelButtonShadowColor(LevelStatus status) {
    switch (status) {
      case LevelStatus.completed:
        return const Color(0xFF22C55E).withOpacity(0.4);
      case LevelStatus.unlocked:
        return const Color(0xFF6366F1).withOpacity(0.2);
      case LevelStatus.locked:
        return const Color(0xFF6B7280).withOpacity(0.3); // Subtle glow for locked levels
    }
  }

  Widget _buildHexagonalLevelContent(int level, LevelStatus status) {
    if (status == LevelStatus.locked) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF9CA3AF).withOpacity(0.6), // Brighter grey
              const Color(0xFF6B7280).withOpacity(0.4),
              const Color(0xFF4B5563).withOpacity(0.3),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9CA3AF).withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
            // Inner highlight
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: -1,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: const Icon(
          Icons.lock,
          color: Color(0xFFE5E7EB), // Brighter lock icon
          size: 20, // Slightly larger
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(0, 2),
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
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            const Shadow(
              color: Colors.black54,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

}

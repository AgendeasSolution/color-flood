import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../services/level_progression_service.dart';
import '../utils/responsive_utils.dart';
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
    // Get responsive grid configuration
    final crossAxisCount = ResponsiveUtils.getResponsiveLevelGridCount(context);
    final spacing = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 6.0,
      mediumPhone: 8.0,
      largePhone: 10.0,
      tablet: 12.0,
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom Header or Default Title
        customHeader ?? Text(
          'Select Level',
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              smallPhone: 20,
              mediumPhone: 22,
              largePhone: 24,
              tablet: 28,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
          context,
          smallPhone: 8,
          mediumPhone: 12,
          largePhone: 16,
          tablet: 20,
        )),
        
        // Level Grid - Hexagonal Layout with Scrolling
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.getResponsiveSpacing(
                context,
                smallPhone: 4,
                mediumPhone: 6,
                largePhone: 8,
                tablet: 10,
              ),
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing * 2, // Increased gap between rows
              childAspectRatio: 1.0, // Adjusted for better hexagonal proportions
            ),
            itemCount: GameConstants.maxLevel,
            itemBuilder: (context, index) {
              final level = index + 1;
              final status = levelStatuses[level] ?? LevelStatus.locked;
              return _buildHexagonalLevelButton(context, level, status);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHexagonalLevelButton(BuildContext context, int level, LevelStatus status) {
    final isLocked = status == LevelStatus.locked;
    final isCompleted = status == LevelStatus.completed;
    
    // Get responsive hexagon size
    final hexSize = ResponsiveUtils.getResponsiveLevelButtonSize(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: HexagonWidget(
        size: hexSize,
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
        child: _buildHexagonalLevelContent(context, level, status),
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

  Widget _buildHexagonalLevelContent(BuildContext context, int level, LevelStatus status) {
    // Get responsive sizes
    final iconSize = ResponsiveUtils.getResponsiveIconSize(
      context,
      smallPhone: 16,
      mediumPhone: 18,
      largePhone: 20,
      tablet: 24,
    );
    final textSize = ResponsiveUtils.getResponsiveFontSize(
      context,
      smallPhone: 14,
      mediumPhone: 16,
      largePhone: 18,
      tablet: 22,
    );
    final padding = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 6,
      mediumPhone: 7,
      largePhone: 8,
      tablet: 10,
    );
    
    if (status == LevelStatus.locked) {
      return Container(
        padding: EdgeInsets.all(padding),
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
        child: Icon(
          Icons.lock,
          color: const Color(0xFFE5E7EB), // Brighter lock icon
          size: iconSize,
        ),
      );
    }
    
    if (status == LevelStatus.completed) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(padding - 2),
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
            child: Icon(
              Icons.check_circle,
              color: const Color(0xFF22C55E),
              size: iconSize - 2,
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
            context,
            smallPhone: 4,
            mediumPhone: 6,
            largePhone: 8,
            tablet: 10,
          )),
          Text(
            level.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              shadows: const [
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
      padding: EdgeInsets.all(padding),
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
          fontSize: textSize + 2,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
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

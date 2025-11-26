import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../services/level_progression_service.dart';
import '../utils/responsive_utils.dart';
import 'gem_level_button.dart';

/// Level selection grid component showing levels 1-12
class LevelSelectionGrid extends StatelessWidget {
  final Function(int level) onLevelSelected;
  final Map<int, LevelStatus> levelStatuses;
  final Widget? customHeader;
  final bool compactTopSpacing;

  const LevelSelectionGrid({
    super.key,
    required this.onLevelSelected,
    required this.levelStatuses,
    this.customHeader,
    this.compactTopSpacing = false,
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
      mainAxisSize: MainAxisSize.min,
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
        
        SizedBox(
          height: compactTopSpacing
              ? ResponsiveUtils.getResponsiveSpacing(
                  context,
                  smallPhone: 2,
                  mediumPhone: 3,
                  largePhone: 4,
                  tablet: 6,
                )
              : ResponsiveUtils.getResponsiveSpacing(
                  context,
                  smallPhone: 8,
                  mediumPhone: 12,
                  largePhone: 16,
                  tablet: 20,
                ),
        ),
        
        // Level Grid - 3D Gem Layout with overall page scrolling
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
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
            mainAxisSpacing: spacing * 1.5, // Spacing for 3D gems
            childAspectRatio: 1.0, // Square gems
          ),
          itemCount: GameConstants.maxLevel,
          itemBuilder: (context, index) {
            final level = index + 1;
            final status = levelStatuses[level] ?? LevelStatus.locked;
            return _buildHexagonalLevelButton(context, level, status);
          },
        ),
      ],
    );
  }

  Widget _buildHexagonalLevelButton(BuildContext context, int level, LevelStatus status) {
    final isLocked = status == LevelStatus.locked;
    
    // Get base color based on status
    final baseColor = _getLevelButtonBaseColor(status);
    
    // Custom shadows for different statuses
    final customShadows = _getLevelButtonShadows(status, baseColor);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use the smaller dimension to ensure square gems, with padding for shadows
          final availableSize = constraints.maxWidth < constraints.maxHeight 
              ? constraints.maxWidth 
              : constraints.maxHeight;
          
          // Leave some space for shadows (about 10% on each side)
          final gemSize = availableSize * 0.9;
          
          return Center(
            child: GemLevelButton(
              size: gemSize,
              baseColor: baseColor,
              customShadows: customShadows,
              onTap: isLocked ? null : () => onLevelSelected(level),
              child: _buildGemLevelContent(context, level, status),
            ),
          );
        },
      ),
    );
  }


  Color _getLevelButtonBaseColor(LevelStatus status) {
    switch (status) {
      case LevelStatus.completed:
        // Green gem for completed levels (matching game board green)
        return const Color(0xFF22C55E);
      case LevelStatus.unlocked:
        // Blue gem for unlocked levels (matching game board blue)
        return const Color(0xFF3B82F6);
      case LevelStatus.locked:
        // Grey gem for locked levels
        return const Color(0xFF6B7280);
    }
  }

  List<BoxShadow> _getLevelButtonShadows(LevelStatus status, Color baseColor) {
    switch (status) {
      case LevelStatus.completed:
        return [
          // Deep shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 10,
            spreadRadius: -3,
            offset: const Offset(0, 5),
          ),
          // Medium shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: -1,
            offset: const Offset(0, 2),
          ),
          // Green glow
          BoxShadow(
            color: baseColor.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];
      case LevelStatus.unlocked:
        return [
          // Deep shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 10,
            spreadRadius: -3,
            offset: const Offset(0, 5),
          ),
          // Medium shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: -1,
            offset: const Offset(0, 2),
          ),
          // Blue glow
          BoxShadow(
            color: baseColor.withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 1.5,
            offset: const Offset(0, 1),
          ),
        ];
      case LevelStatus.locked:
        return [
          // Reduced shadow for locked levels
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
          // Subtle grey glow
          BoxShadow(
            color: baseColor.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 0.5,
            offset: const Offset(0, 1),
          ),
        ];
    }
  }

  Widget _buildGemLevelContent(BuildContext context, int level, LevelStatus status) {
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
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.lock,
          color: Colors.white.withOpacity(0.7),
          size: iconSize,
        ),
      );
    }
    
    if (status == LevelStatus.completed) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            level.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: textSize + 2,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
                Shadow(
                  color: const Color(0xFF22C55E).withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
            context,
            smallPhone: 3,
            mediumPhone: 4,
            largePhone: 5,
            tablet: 6,
          )),
          Container(
            padding: EdgeInsets.all(padding - 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.7),
                  const Color(0xFF22C55E).withOpacity(0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.check_circle,
              color: const Color(0xFF22C55E),
              size: iconSize - 3,
            ),
          ),
        ],
      );
    }
    
    // Unlocked but not completed
    return Container(
      padding: EdgeInsets.all(padding + 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        level.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: textSize + 2,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
            Shadow(
              color: const Color(0xFF3B82F6).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
    );
  }

}

import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../services/level_progression_service.dart';
import '../utils/responsive_utils.dart';

/// Level selection carousel component showing levels in cards
/// Each card contains 9 levels in a 3x3 grid (3 columns × 3 rows)
class LevelSelectionCarousel extends StatefulWidget {
  final Function(int level) onLevelSelected;
  final Map<int, LevelStatus> levelStatuses;
  final Widget? customHeader;
  final bool compactTopSpacing;

  const LevelSelectionCarousel({
    super.key,
    required this.onLevelSelected,
    required this.levelStatuses,
    this.customHeader,
    this.compactTopSpacing = false,
  });

  @override
  State<LevelSelectionCarousel> createState() => _LevelSelectionCarouselState();
}

class _LevelSelectionCarouselState extends State<LevelSelectionCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  static const int levelsPerCard = 9; // 3 columns × 3 rows
  late final int totalCards;

  @override
  void initState() {
    super.initState();
    totalCards = (GameConstants.maxLevel / levelsPerCard).ceil();
    _pageController = PageController(viewportFraction: 0.92); // Show 92% of current card, reducing gap between cards
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [

        // Carousel with PageView
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate height based on width for 3x3 grid (square aspect ratio)
            final width = constraints.maxWidth;
            final height = width; // Square grid
            return SizedBox(
              height: height,
              width: width,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: totalCards,
                itemBuilder: (context, pageIndex) {
                  return _buildLevelCard(context, pageIndex);
                },
              ),
            );
          },
        ),

        // Page Indicators

        _buildPageIndicators(context),
      ],
    );
  }

  Widget _buildLevelCard(BuildContext context, int pageIndex) {
    final startLevel = pageIndex * levelsPerCard + 1;
    final endLevel = (startLevel + levelsPerCard - 1).clamp(1, GameConstants.maxLevel);
    
    return Center(
      child: Container(
        padding: EdgeInsets.all(
          ResponsiveUtils.getResponsiveSpacing(
            context,
            smallPhone: 3,
            mediumPhone: 4,
            largePhone: 5,
            tablet: 6,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate grid dimensions for 3 columns × 3 rows
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;
            final crossAxisSpacing = ResponsiveUtils.getResponsiveSpacing(
              context,
              smallPhone: 4.0,
              mediumPhone: 6.0,
              largePhone: 8.0,
              tablet: 10.0,
            );
            final mainAxisSpacing = ResponsiveUtils.getResponsiveSpacing(
              context,
              smallPhone: 0.0,
              mediumPhone: 0.0,
              largePhone: 0.0,
              tablet: 0.0,
            );
            
            // Calculate item size: divide width equally with spacing
            final itemWidth = availableWidth / 3;
            final itemHeight = (availableHeight - (2 * mainAxisSpacing)) / 3;
            
            // Build 3x3 grid using GridView
            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                childAspectRatio: itemWidth / itemHeight,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final level = startLevel + index;
                if (level > GameConstants.maxLevel) {
                  return const SizedBox.shrink();
                }
                final status = widget.levelStatuses[level] ?? LevelStatus.locked;
                return _buildHexagonalLevelButton(context, level, status);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHexagonalLevelButton(BuildContext context, int level, LevelStatus status) {
    final isLocked = status == LevelStatus.locked;
    
    // Get base color based on status
    final baseColor = _getLevelButtonBaseColor(status);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use the smaller dimension to ensure square tiles
          final availableSize = constraints.maxWidth < constraints.maxHeight 
              ? constraints.maxWidth 
              : constraints.maxHeight;
          
          return Center(
            child: GestureDetector(
              onTap: isLocked ? null : () => widget.onLevelSelected(level),
              child: _buildGameboardTile(availableSize, baseColor, level, status),
            ),
          );
        },
      ),
    );
  }

  Color _getLevelButtonBaseColor(LevelStatus status) {
    switch (status) {
      case LevelStatus.completed:
        return const Color(0xFF22C55E);
      case LevelStatus.unlocked:
        return const Color(0xFF3B82F6);
      case LevelStatus.locked:
        return const Color(0xFF6B7280);
    }
  }

  /// Build a tile matching the gameboard tile design
  Widget _buildGameboardTile(double size, Color baseColor, int level, LevelStatus status) {
    final borderRadius = size * 0.08;
    
    // Helper functions for color manipulation (same as gameboard)
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
    
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            // Deep shadow for strong 3D effect - bottom-right
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(size * 0.04, size * 0.04),
            ),
            // Medium shadow layer
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: -1,
              offset: Offset(size * 0.02, size * 0.02),
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
              // Base glass/ball layer with radial gradient (like gameboard tiles)
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
              
              // Level content on top (instead of Mahjong icon)
              Center(
                child: _buildGemLevelContent(context, level, status),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGemLevelContent(BuildContext context, int level, LevelStatus status) {
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

  Widget _buildPageIndicators(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalCards,
        (index) => GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getResponsiveSpacing(
                context,
                smallPhone: 3,
                mediumPhone: 4,
                largePhone: 5,
                tablet: 6,
              ),
            ),
            width: _currentPage == index
                ? ResponsiveUtils.getResponsiveValue(
                    context: context,
                    smallPhone: 24.0,
                    mediumPhone: 28.0,
                    largePhone: 32.0,
                    tablet: 36.0,
                  )
                : ResponsiveUtils.getResponsiveValue(
                    context: context,
                    smallPhone: 8.0,
                    mediumPhone: 10.0,
                    largePhone: 12.0,
                    tablet: 14.0,
                  ),
            height: ResponsiveUtils.getResponsiveValue(
              context: context,
              smallPhone: 8.0,
              mediumPhone: 10.0,
              largePhone: 12.0,
              tablet: 14.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _currentPage == index
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white.withOpacity(0.3),
              boxShadow: _currentPage == index
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

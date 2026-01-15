import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/daily_puzzle_service.dart';
import '../types/game_types.dart';
import '../utils/responsive_utils.dart';

/// Daily Puzzle Card component that displays today's puzzle
class DailyPuzzleCard extends StatefulWidget {
  final VoidCallback onTap;
  
  const DailyPuzzleCard({
    super.key,
    required this.onTap,
  });

  @override
  State<DailyPuzzleCard> createState() => DailyPuzzleCardState();
}

class DailyPuzzleCardState extends State<DailyPuzzleCard> {
  final DailyPuzzleService _dailyPuzzleService = DailyPuzzleService.instance;
  GameConfig? _puzzleConfig;
  bool _isLoading = true;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadDailyPuzzle();
  }

  /// Refresh the daily puzzle status
  void refresh() {
    _loadDailyPuzzle();
  }

  Future<void> _loadDailyPuzzle() async {
    try {
      final puzzle = await _dailyPuzzleService.getTodaysPuzzle();
      final completed = await _dailyPuzzleService.isTodaysPuzzleCompleted();
      
      if (mounted) {
        setState(() {
          _puzzleConfig = puzzle;
          _isCompleted = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_puzzleConfig == null) {
      return const SizedBox.shrink();
    }

    final spacing = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 8,
      mediumPhone: 10,
      largePhone: 12,
      tablet: 14,
    );

    // Border colors matching WoodButton style
    const lightBorderColor = Color(0xFFDBEAFE); // Light blue border
    const embossColor = Color(0xFF93C5FD); // Light blue for embossed edge

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2962FF),
                const Color(0xFF1E88E5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: lightBorderColor,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(spacing),
            child: Row(
              children: [
                // Leading calendar icon with reduced circle size
                Container(
                  width: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    smallPhone: 40,
                    mediumPhone: 44,
                    largePhone: 48,
                    tablet: 52,
                  ),
                  height: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    smallPhone: 40,
                    mediumPhone: 44,
                    largePhone: 48,
                    tablet: 52,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      smallPhone: 26,
                      mediumPhone: 28,
                      largePhone: 30,
                      tablet: 32,
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                // Header with title and description
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Daily Challenge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            smallPhone: 18,
                            mediumPhone: 20,
                            largePhone: 22,
                            tablet: 24,
                          ),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: spacing * 0.3),
                      // Description
                      Text(
                        'Play a new puzzle every day and build your streak.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            smallPhone: 13,
                            mediumPhone: 14,
                            largePhone: 15,
                            tablet: 16,
                          ),
                          fontWeight: FontWeight.normal,
                          letterSpacing: 0.2,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right-pointing chevron icon
                Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    smallPhone: 24,
                    mediumPhone: 26,
                    largePhone: 28,
                    tablet: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


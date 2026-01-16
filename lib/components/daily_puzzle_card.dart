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
      final completed = await _dailyPuzzleService.isDailyPuzzleCompleted();
      
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

    final horizontalPadding = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 12,
      mediumPhone: 14,
      largePhone: 16,
      tablet: 24,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: ResponsiveUtils.getResponsiveSpacing(
          context,
          smallPhone: 24,
          mediumPhone: 28,
          largePhone: 32,
          tablet: 36,
        ),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent, // No background color
                borderRadius: BorderRadius.circular(999), // Full border radius
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
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
                padding: EdgeInsets.symmetric(
                  horizontal: spacing * 2,
                  vertical: spacing * 1.5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Calendar icon
                    Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        smallPhone: 20,
                        mediumPhone: 22,
                        largePhone: 24,
                        tablet: 26,
                      ),
                    ),
                    SizedBox(width: spacing),
                    // Button name
                    Text(
                      'Daily Challenge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          smallPhone: 16,
                          mediumPhone: 18,
                          largePhone: 20,
                          tablet: 22,
                        ),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Badge icon at top-right corner - improved design
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  smallPhone: 22,
                  mediumPhone: 24,
                  largePhone: 26,
                  tablet: 28,
                ),
                height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  smallPhone: 22,
                  mediumPhone: 24,
                  largePhone: 26,
                  tablet: 28,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isCompleted 
                      ? const Color(0xFF22C55E) // Green for completed
                      : const Color(0xFFEF4444), // Red for not completed
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 3,
                      spreadRadius: 0,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Icon(
                  _isCompleted 
                      ? Icons.check 
                      : Icons.priority_high,
                  color: Colors.white,
                  size: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    smallPhone: 14,
                    mediumPhone: 16,
                    largePhone: 18,
                    tablet: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


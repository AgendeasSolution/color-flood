import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/daily_puzzle_service.dart';
import '../types/game_types.dart';
import '../components/game_board.dart';
import '../utils/responsive_utils.dart';
import '../constants/game_constants.dart';

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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isCompleted
                      ? [
                          const Color(0xFF10B981).withOpacity(0.25), // Green
                          const Color(0xFF059669).withOpacity(0.20), // Darker green
                          const Color(0xFF047857).withOpacity(0.25), // Deep green
                        ]
                      : [
                          const Color(0xFFFFA500).withOpacity(0.25), // Orange
                          const Color(0xFFF59E0B).withOpacity(0.20), // Amber
                          const Color(0xFFEF4444).withOpacity(0.25), // Red
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: _isCompleted
                    ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: const Color(0xFF047857).withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: -5,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: const Color(0xFFFFA500).withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: -5,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Padding(
                padding: EdgeInsets.all(spacing),
                child: Row(
                  children: [
                    // Puzzle preview (smaller)
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          smallPhone: 60,
                          mediumPhone: 70,
                          largePhone: 80,
                          tablet: 90,
                        ),
                        maxHeight: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          smallPhone: 60,
                          mediumPhone: 70,
                          largePhone: 80,
                          tablet: 90,
                        ),
                      ),
                      child: AspectRatio(
                        aspectRatio: _puzzleConfig!.gridWidth / _puzzleConfig!.gridHeight,
                        child: GameBoard(
                          grid: _puzzleConfig!.grid,
                          gridWidth: _puzzleConfig!.gridWidth,
                          gridHeight: _puzzleConfig!.gridHeight,
                          gameStarted: true,
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
                          // Title row
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.white.withOpacity(0.9),
                                size: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  smallPhone: 16,
                                  mediumPhone: 17,
                                  largePhone: 18,
                                  tablet: 20,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Today\'s Puzzle',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                                      context,
                                      smallPhone: 14,
                                      mediumPhone: 15,
                                      largePhone: 16,
                                      tablet: 18,
                                    ),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing * 0.5),
                          // Description - catchy text
                          Text(
                            _isCompleted
                                ? 'Challenge completed!'
                                : 'Can you solve it?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                smallPhone: 12,
                                mediumPhone: 13,
                                largePhone: 14,
                                tablet: 15,
                              ),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Done badge - game-like polished design (icon only)
                    if (_isCompleted)
                      Container(
                        width: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          smallPhone: 48,
                          mediumPhone: 52,
                          largePhone: 56,
                          tablet: 60,
                        ),
                        height: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          smallPhone: 48,
                          mediumPhone: 52,
                          largePhone: 56,
                          tablet: 60,
                        ),
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.75),
                              const Color(0xFF10B981).withOpacity(0.85),
                              const Color(0xFF059669).withOpacity(0.9),
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFFFFFF),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check,
                            color: const Color(0xFF047857),
                            size: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              smallPhone: 26,
                              mediumPhone: 28,
                              largePhone: 30,
                              tablet: 32,
                            ),
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


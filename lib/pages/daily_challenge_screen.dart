import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/daily_puzzle_service.dart';
import '../utils/responsive_utils.dart';
import '../components/animated_background.dart';
import '../components/back_button_row.dart';
import 'game_page.dart';

/// Daily Challenge Screen with calendar view and streak stats
class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  final DailyPuzzleService _dailyPuzzleService = DailyPuzzleService.instance;
  
  DateTime _currentMonth = DateTime.now();
  Set<String> _completedDates = {};
  int _currentStreak = 0;
  int _bestStreak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final completedDates = await _dailyPuzzleService.getCompletedDailyPuzzleDates();
      final currentStreak = await _dailyPuzzleService.getCompletionStreak();
      final bestStreak = await _dailyPuzzleService.getBestStreak();
      
      if (mounted) {
        setState(() {
          _completedDates = completedDates;
          _currentStreak = currentStreak;
          _bestStreak = bestStreak;
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

  void _navigateToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _navigateToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isAtSameMomentAs(today);
  }

  bool _isFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isAfter(today);
  }

  bool _isCompleted(String dateKey) {
    return _completedDates.contains(dateKey);
  }

  Future<void> _navigateToDailyPuzzle() async {
    try {
      if (!mounted || !context.mounted) return;
      
      // Mark puzzle as started
      await _dailyPuzzleService.startDailyPuzzle();
      
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const GamePage(initialLevel: 0), // Level 0 = daily puzzle
        ),
      );
      
      // Reload data when returning
      if (mounted) {
        await _loadData();
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          const AnimatedBackground(),
          
          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Back Button Row
                BackButtonRow(
                  onBack: () => Navigator.of(context).pop(),
                  centerWidget: Text(
                    'Daily Challenge',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        smallPhone: 18,
                        mediumPhone: 20,
                        largePhone: 22,
                        tablet: 24,
                      ),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                
                // Stats Display
                if (!_isLoading) _buildStatsDisplay(),
                
                // Calendar View
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _buildCalendarView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDisplay() {
    final spacing = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 12,
      mediumPhone: 14,
      largePhone: 16,
      tablet: 20,
    );
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing * 0.75),
      child: Row(
        children: [
          // Current Streak Card
          Expanded(
            child: _buildStreakCard(
              icon: Icons.local_fire_department,
              value: _currentStreak,
              label: 'Current',
              color: const Color(0xFF00D9FF), // Cyan
            ),
          ),
          SizedBox(width: spacing),
          // Best Streak Card
          Expanded(
            child: _buildStreakCard(
              icon: Icons.emoji_events,
              value: _bestStreak,
              label: 'Best',
              color: const Color(0xFFFFB84D), // Amber/Orange
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard({
    required IconData icon,
    required int value,
    required String label,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(
            context,
            smallPhone: 12,
            mediumPhone: 14,
            largePhone: 16,
            tablet: 20,
          )),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.6),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  smallPhone: 28,
                  mediumPhone: 32,
                  largePhone: 36,
                  tablet: 40,
                ),
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(
                context,
                smallPhone: 8,
                mediumPhone: 10,
                largePhone: 12,
                tablet: 14,
              )),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          smallPhone: 24,
                          mediumPhone: 28,
                          largePhone: 32,
                          tablet: 36,
                        ),
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          smallPhone: 12,
                          mediumPhone: 13,
                          largePhone: 14,
                          tablet: 16,
                        ),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    final spacing = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 12,
      mediumPhone: 14,
      largePhone: 16,
      tablet: 20,
    );
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing),
      child: Column(
        children: [
          // Month Navigation
          _buildMonthNavigation(),
          
          SizedBox(height: spacing * 0.75),
          
          // Days of Week Header
          _buildDaysOfWeekHeader(),
          
          SizedBox(height: spacing * 0.5),
          
          // Calendar Grid with lighter background
          Expanded(
            child: _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final monthName = monthNames[_currentMonth.month - 1];
    final year = _currentMonth.year;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous Month Button - Left side
        _buildMonthNavButton(
          icon: Icons.chevron_left,
          onTap: _navigateToPreviousMonth,
        ),
        
        // Month and Year - Center
        Expanded(
          child: Center(
            child: Text(
              '$monthName $year',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  smallPhone: 18,
                  mediumPhone: 20,
                  largePhone: 22,
                  tablet: 24,
                ),
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        // Next Month Button - Right side
        _buildMonthNavButton(
          icon: Icons.chevron_right,
          onTap: _navigateToNextMonth,
        ),
      ],
    );
  }

  Widget _buildMonthNavButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: ResponsiveUtils.getResponsiveSpacing(
              context,
              smallPhone: 36,
              mediumPhone: 40,
              largePhone: 44,
              tablet: 48,
            ),
            height: ResponsiveUtils.getResponsiveSpacing(
              context,
              smallPhone: 36,
              mediumPhone: 40,
              largePhone: 44,
              tablet: 48,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: ResponsiveUtils.getResponsiveFontSize(
                context,
                smallPhone: 20,
                mediumPhone: 22,
                largePhone: 24,
                tablet: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaysOfWeekHeader() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Row(
      children: days.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  smallPhone: 11,
                  mediumPhone: 12,
                  largePhone: 13,
                  tablet: 14,
                ),
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    
    // Find the first Monday (or the first day of the month if it's Monday)
    int firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    if (firstWeekday == 7) firstWeekday = 0; // Convert Sunday to 0 for easier calculation
    
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = ((firstWeekday + daysInMonth + 6) / 7).ceil() * 7;
    
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: totalCells.toInt(),
      itemBuilder: (context, index) {
        final dayIndex = index - firstWeekday;
        
        if (dayIndex < 0 || dayIndex >= daysInMonth) {
          // Empty cell for days outside the month
          return const SizedBox.shrink();
        }
        
        final date = DateTime(_currentMonth.year, _currentMonth.month, dayIndex + 1);
        final dateKey = _dateToKey(date);
        final isToday = _isToday(date);
        final isFuture = _isFuture(date);
        final isCompleted = _isCompleted(dateKey);
        
        return _buildCalendarDay(
          date: date,
          dateKey: dateKey,
          isToday: isToday,
          isFuture: isFuture,
          isCompleted: isCompleted,
        );
      },
    );
  }

  Widget _buildCalendarDay({
    required DateTime date,
    required String dateKey,
    required bool isToday,
    required bool isFuture,
    required bool isCompleted,
  }) {
    final dayNumber = date.day;
    final isClickable = isToday && !isFuture;
    
    Widget dayContent;
    
    if (isCompleted) {
      // Completed date - show solid bright star icon (fully opaque, no glow)
      dayContent = Icon(
        Icons.star,
        color: const Color(0xFFFFA500), // Fully opaque bright orange/amber
        size: ResponsiveUtils.getResponsiveFontSize(
          context,
          smallPhone: 28,
          mediumPhone: 32,
          largePhone: 36,
          tablet: 40,
        ),
      );
    } else {
      // Not completed - show day number
      dayContent = Text(
        '$dayNumber',
        style: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(
            context,
            smallPhone: 14,
            mediumPhone: 16,
            largePhone: 18,
            tablet: 20,
          ),
          fontWeight: FontWeight.w600,
          color: isFuture 
              ? Colors.white.withOpacity(0.5) // Lighter gray for future dates
              : Colors.white,
        ),
      );
    }
    
    return GestureDetector(
      onTap: isClickable ? _navigateToDailyPuzzle : null,
      child: Container(
        decoration: BoxDecoration(
          // Lighter backgrounds for better visibility
          color: isCompleted
              ? Colors.transparent // No background for completed dates with star
              : (isFuture 
                  ? Colors.white.withOpacity(0.12) // Lighter background for future dates
                  : Colors.white.withOpacity(0.18)), // Brighter background for active dates
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? const Color(0xFF00D9FF).withOpacity(0.9) // Brighter cyan border for today
                : (isCompleted
                    ? Colors.transparent // No border for completed dates
                    : Colors.white.withOpacity(0.35)), // Brighter border for regular dates
            width: isToday ? 2.0 : (isCompleted ? 0.0 : 1.5),
          ),
          boxShadow: isToday && !isCompleted
              ? [
                  BoxShadow(
                    color: const Color(0xFF00D9FF).withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ]
              : (!isCompleted && !isToday
                  ? [
                      // Subtle shadow for all dates for better visibility
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null), // No shadow for completed dates
        ),
        child: Center(
          child: dayContent,
        ),
      ),
    );
  }
}

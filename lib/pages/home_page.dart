import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../constants/game_constants.dart';
import '../components/how_to_play_dialog.dart';
import '../components/ad_banner.dart';
import '../components/animated_background.dart';
import '../components/glass_button.dart';
import '../components/update_popup.dart';
import '../components/settings_dialog.dart';
import '../components/daily_puzzle_card.dart';
import '../components/wood_button.dart';
import '../services/level_progression_service.dart';
import '../services/audio_service.dart';
import '../services/daily_puzzle_service.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';
import '../utils/color_utils.dart';
import 'game_page.dart';
import 'other_games_screen.dart';
import 'daily_challenge_screen.dart';


/// Home page of the Color Flood game
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  Map<int, LevelStatus> _levelStatuses = {}; // Track level unlock status
  int _currentLevel = 1; // Track current level to display
  final LevelProgressionService _levelService = LevelProgressionService.instance;
  final AudioService _audioService = AudioService();
  final DailyPuzzleService _dailyPuzzleService = DailyPuzzleService.instance;
  bool _hasEnsuredMusic = false; // Track if we've ensured music is playing
  final GlobalKey<DailyPuzzleCardState> _dailyPuzzleCardKey = GlobalKey<DailyPuzzleCardState>();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadLevelStatuses();
    _hasEnsuredMusic = false;
    // Start background music when home page loads
    _audioService.playBackgroundMusic();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh level statuses and daily puzzle when returning to home screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadLevelStatuses();
        // Refresh daily puzzle card to show updated completion status
        _dailyPuzzleCardKey.currentState?.refresh();
        // Start background music when returning to home screen
        // Add a small delay to ensure navigation is complete
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _audioService.backgroundMusicEnabled) {
            _hasEnsuredMusic = false; // Reset flag to ensure music plays
            _audioService.playBackgroundMusic();
          }
        });
      }
    });
  }

  void _initializeAnimations() {
    // Initialize fade animation
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    );

    // Start animation
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    // Don't stop background music in dispose - just pause it
    // This allows it to resume when returning
    _audioService.pauseBackgroundMusic();
    super.dispose();
  }

  void _navigateToLevel(int level) async {
    try {
      // Validate level before navigation
      if (level < 1 || level > GameConstants.maxLevel) {
        return;
      }
      
      if (!mounted || !context.mounted) return;
      
      // Pause background music when navigating to game
      _audioService.pauseBackgroundMusic();
      _hasEnsuredMusic = false; // Reset flag so music will resume when returning
      
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GamePage(initialLevel: level),
        ),
      );
      // Refresh level statuses when returning from game
      if (mounted) {
        await _loadLevelStatuses();
        // Start background music when returning to home
        // Add a small delay to ensure navigation animation is complete
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _audioService.backgroundMusicEnabled) {
            _hasEnsuredMusic = false; // Reset flag to ensure music plays
            _audioService.playBackgroundMusic();
          }
        });
      }
    } catch (e) {
      // App should continue working even if navigation fails
    }
  }

  void _onLevelSelected(int level) {
    // Navigate directly to game for any level (all levels unlocked)
    _audioService.playClickSound();
    _navigateToLevel(level);
  }

  void _navigateToDailyPuzzle() async {
    try {
      if (!mounted || !context.mounted) return;
      
      // Play click sound
      _audioService.playClickSound();
      
      // Mark puzzle as started when navigating from home
      await _dailyPuzzleService.startDailyPuzzle();
      
      // Navigate to Daily Challenge Screen (calendar view)
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const DailyChallengeScreen(),
        ),
      );
      
      // Refresh level statuses and daily puzzle when returning
      if (mounted) {
        await _loadLevelStatuses();
        // Refresh daily puzzle card to show updated completion status
        _dailyPuzzleCardKey.currentState?.refresh();
        // Start background music when returning to home
        // Add a small delay to ensure navigation animation is complete
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _audioService.backgroundMusicEnabled) {
            _hasEnsuredMusic = false; // Reset flag to ensure music plays
            _audioService.playBackgroundMusic();
          }
        });
      }
    } catch (e) {
      // App should continue working even if navigation fails
    }
  }

  Future<void> _loadLevelStatuses() async {
    try {
      final statuses = await _levelService.getAllLevelStatuses();
      final currentLevel = await _levelService.getHighestUnlockedLevel();
      if (mounted) {
        setState(() {
          // Validate statuses map before setting
          _levelStatuses = statuses.isNotEmpty ? statuses : <int, LevelStatus>{};
          // Set current level (highest unlocked level)
          _currentLevel = currentLevel;
        });
      }
    } catch (e) {
      // Silently handle errors - app should continue working
      if (mounted) {
        setState(() {
          // Set empty statuses as fallback
          _levelStatuses = <int, LevelStatus>{};
          _currentLevel = 1; // Default to level 1
        });
      }
    }
  }


  void _showHowToPlay() {
    _audioService.playClickSound();
    HowToPlayDialog.show(context);
  }

  Widget _buildCurrentLevelDisplay() {
    // Get status for current level
    final status = _levelStatuses[_currentLevel] ?? LevelStatus.unlocked;
    final effectiveStatus = status == LevelStatus.locked ? LevelStatus.unlocked : status;
    
    return Center(
      child: _buildSingleLevelButton(_currentLevel, effectiveStatus),
    );
  }

  Widget _buildSingleLevelButton(int level, LevelStatus status) {
    // Get base color based on status
    Color baseColor;
    switch (status) {
      case LevelStatus.completed:
        baseColor = const Color(0xFF22C55E);
        break;
      case LevelStatus.unlocked:
        baseColor = const Color(0xFF3B82F6);
        break;
      case LevelStatus.locked:
        baseColor = const Color(0xFF6B7280);
        break;
    }
    
    // Calculate size based on screen width - make it larger to accommodate "Level X" text
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 12,
      mediumPhone: 14,
      largePhone: 16,
      tablet: 24,
    );
    final availableWidth = screenWidth - (horizontalPadding * 2);
    final buttonSize = (availableWidth * 0.42).clamp(130.0, 220.0);
    
    return GestureDetector(
      onTap: () => _onLevelSelected(level),
      child: _buildGameboardTile(buttonSize, baseColor, level, status),
    );
  }

  Widget _buildGameboardTile(double size, Color baseColor, int level, LevelStatus status) {
    final borderRadius = size * 0.08;
    final tileColor = baseColor;
    
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(size * 0.04, size * 0.04),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: -1,
              offset: Offset(size * 0.02, size * 0.02),
            ),
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
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.2,
                    colors: [
                      ColorUtils.lightenColor(tileColor, 0.2),
                      tileColor,
                      ColorUtils.darkenColor(tileColor, 0.25),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
              ),
              Center(
                child: _buildLevelContent(level, status),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreMoreGamesSection(double horizontalPadding, double buttonSpacing) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: ResponsiveUtils.getResponsiveSpacing(
          context,
          smallPhone: 90,
          mediumPhone: 100,
          largePhone: 110,
          tablet: 120,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white.withOpacity(0.85),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                AppConstants.exploreMoreGamesLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          SizedBox(height: buttonSpacing * 0.75),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildExternalNavigationButton(
                icon: Icons.phone_android,
                label: AppConstants.mobileGamesLabel,
                onTap: _navigateToOtherGames,
                iconColor: const Color(0xFF93C5FD),
                gradientColors: [
                  const Color(0xFF3B82F6).withOpacity(0.5),
                  const Color(0xFF2563EB).withOpacity(0.35),
                ],
              ),
              SizedBox(width: buttonSpacing),
              _buildExternalNavigationButton(
                icon: Icons.laptop,
                label: AppConstants.webGamesLabel,
                onTap: _openWebGames,
                iconColor: const Color(0xFF6EE7B7),
                gradientColors: [
                  const Color(0xFF10B981).withOpacity(0.5),
                  const Color(0xFF059669).withOpacity(0.35),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelContent(int level, LevelStatus status) {
    final iconSize = ResponsiveUtils.getResponsiveIconSize(
      context,
      smallPhone: 20,
      mediumPhone: 24,
      largePhone: 28,
      tablet: 32,
    );
    final titleTextSize = ResponsiveUtils.getResponsiveFontSize(
      context,
      smallPhone: 24,
      mediumPhone: 28,
      largePhone: 32,
      tablet: 36,
    );
    final levelTextSize = ResponsiveUtils.getResponsiveFontSize(
      context,
      smallPhone: 32,
      mediumPhone: 36,
      largePhone: 40,
      tablet: 48,
    );
    final padding = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 8,
      mediumPhone: 10,
      largePhone: 12,
      tablet: 14,
    );
    
    if (status == LevelStatus.completed) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Level',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: titleTextSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(height: padding * 0.3),
          Text(
            level.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: levelTextSize,
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
          SizedBox(height: padding * 0.5),
          Container(
            padding: EdgeInsets.all(padding - 4),
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
              size: iconSize * 0.6,
            ),
          ),
        ],
      );
    }
    
    // Unlocked but not completed
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Level',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: titleTextSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        SizedBox(height: padding * 0.3),
        Text(
          level.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: levelTextSize,
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
      ],
    );
  }

  void _showSettings() {
    _audioService.playClickSound();
    SettingsDialog.show(context);
  }

  void _navigateToOtherGames() {
    _audioService.playClickSound();
    // Pause background music when navigating away
    _audioService.pauseBackgroundMusic();
    _hasEnsuredMusic = false; // Reset flag so music will resume when returning
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OtherGamesScreen(),
      ),
    ).then((_) {
      // Start background music when returning to home
      // Add a small delay to ensure navigation animation is complete
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && _audioService.backgroundMusicEnabled) {
          _hasEnsuredMusic = false; // Reset flag to ensure music plays
          _audioService.playBackgroundMusic();
        }
      });
    });
  }

  Future<void> _onBackPressed() async {
    final shouldExit = await _showExitConfirmationDialog();
    if (shouldExit == true && mounted) {
      SystemNavigator.pop();
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    if (!mounted || !context.mounted) return false;
    _audioService.playClickSound();
    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.3),
        builder: (dialogContext) => _ExitAppDialog(
          onConfirm: () {
            _audioService.playClickSound();
            Navigator.of(dialogContext).pop(true);
          },
          onCancel: () {
            _audioService.playClickSound();
            Navigator.of(dialogContext).pop(false);
          },
        ),
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _openWebGames() async {
    _audioService.playClickSound();
    final Uri webUri = Uri.parse('https://www.freegametoplay.com');

    try {
      final launched = await launchUrl(
        webUri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open freegametoplay.com'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open freegametoplay.com'),
        ),
      );
    }
  }

  Widget _buildHowToPlayButton() {
    final buttonSize = ResponsiveUtils.getResponsiveButtonSize(context) * 0.8;
    
    return WoodButton(
      onTap: _showHowToPlay,
      size: buttonSize,
      icon: Icon(
        Icons.help_outline,
        color: Colors.white,
        size: buttonSize * 0.5,
      ),
    );
  }

  Widget _buildSettingsButton() {
    final buttonSize = ResponsiveUtils.getResponsiveButtonSize(context) * 0.8;
    
    return WoodButton(
      onTap: _showSettings,
      size: buttonSize,
      icon: Icon(
        Icons.settings,
        color: Colors.white,
        size: buttonSize * 0.5,
      ),
    );
  }

  Widget _buildExternalNavigationButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    List<Color>? gradientColors,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: GlassButton(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            gradientColors: gradientColors ?? [
              AppColors.surfaceLight.withOpacity(0.9),
              AppColors.surface.withOpacity(0.95),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: iconColor ?? Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get responsive spacing values
    final horizontalPadding = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 12,
      mediumPhone: 14,
      largePhone: 16,
      tablet: 24,
    );
    final buttonSpacing = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 8,
      mediumPhone: 10,
      largePhone: 12,
      tablet: 16,
    );
    // Start background music when screen is visible
    // Check on every build if music should be playing
    if (_audioService.backgroundMusicEnabled && !_hasEnsuredMusic) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _audioService.backgroundMusicEnabled) {
          // Small delay to ensure everything is ready
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _audioService.backgroundMusicEnabled) {
              _audioService.playBackgroundMusic();
              _hasEnsuredMusic = true;
            }
          });
        }
      });
    }
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _onBackPressed();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Animated Background
            const AnimatedBackground(),
          
          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Top spacing for logo
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    smallPhone: 40,
                    mediumPhone: 50,
                    largePhone: 60,
                    tablet: 70,
                  )),
                  
                  // Color Flood Logo
                  Image.asset(
                    'assets/img/color_flood_logo.png',
                    width: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      smallPhone: 215.0,
                      mediumPhone: 265.0,
                      largePhone: 315.0,
                      tablet: 415.0,
                    ),
                    fit: BoxFit.contain,
                  ),
                  
                  // Spacing after logo
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                    context,
                    smallPhone: 12,
                    mediumPhone: 16,
                    largePhone: 20,
                    tablet: 24,
                  )),
                  
                  // Content area with proper layout structure
                  Expanded(
                    child: Column(
                      children: [
                        // Flexible top spacer to push content up (reduced to move level card up)
                        Spacer(flex: 1),
                        
                        // Top gap for level card
                        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          smallPhone: 4,
                          mediumPhone: 8,
                          largePhone: 12,
                          tablet: 16,
                        )),
                        
                        // Level Card - Positioned higher up
                        _buildCurrentLevelDisplay(),
                        
                        // Spacing between level card and daily challenge
                        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          smallPhone: 38,
                          mediumPhone: 42,
                          largePhone: 46,
                          tablet: 50,
                        )),
                        
                        // Daily Challenge Button - Positioned higher from bottom
                        DailyPuzzleCard(
                          key: _dailyPuzzleCardKey,
                          onTap: _navigateToDailyPuzzle,
                        ),
                        
                        // Flexible bottom spacer (less than top to keep content higher)
                        Spacer(flex: 3),
                      ],
                    ),
                  ),
                  
                  // Explore More Games Section - Fixed at bottom
                  _buildExploreMoreGamesSection(horizontalPadding, buttonSpacing),
                ],
              ),
            ),
          ),
          
          // How to Play Button - Top Left
          Positioned(
            top: 0,
            left: ResponsiveUtils.getResponsiveSpacing(
              context,
              smallPhone: 12,
              mediumPhone: 14,
              largePhone: 16,
              tablet: 20,
            ),
            child: SafeArea(
              child: _buildHowToPlayButton(),
            ),
          ),
          
          // Settings Button - Top Right
          Positioned(
            top: 0,
            right: ResponsiveUtils.getResponsiveSpacing(
              context,
              smallPhone: 12,
              mediumPhone: 14,
              largePhone: 16,
              tablet: 20,
            ),
            child: SafeArea(
              child: _buildSettingsButton(),
            ),
          ),
          
          // Fixed Ad Banner at bottom of screen (behind pop-up)
          // Positioned above the Explore More Games section
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const AdBanner(
              height: 90,
            ),
          ),
          
          // Update Pop-up (appears on top of ad banner when update is available)
          const UpdatePopup(),
        ],
      ),
    ),
    );
  }
}

/// Exit app confirmation dialog shown when user presses back on home screen
class _ExitAppDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ExitAppDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: (400.0.clamp(0.0, MediaQuery.of(context).size.width * 0.85)).toDouble(),
              padding: ResponsiveUtils.getResponsivePadding(
                context,
                smallPhone: const EdgeInsets.all(20),
                mediumPhone: const EdgeInsets.all(22),
                largePhone: const EdgeInsets.all(24),
                tablet: const EdgeInsets.all(28),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surface.withOpacity(0.95),
                    AppColors.background.withOpacity(0.98),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.surfaceLight.withOpacity(0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Quit game?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          smallPhone: 22,
                          mediumPhone: 24,
                          largePhone: 26,
                          tablet: 30,
                        ),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      smallPhone: 10,
                      mediumPhone: 12,
                      largePhone: 14,
                      tablet: 16,
                    )),
                    Text(
                      'Are you sure you want to exit?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          smallPhone: 14,
                          mediumPhone: 15,
                          largePhone: 16,
                          tablet: 18,
                        ),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      smallPhone: 20,
                      mediumPhone: 24,
                      largePhone: 28,
                      tablet: 32,
                    )),
                    Row(
                      children: [
                        Expanded(
                          child: _ExitDialogButton(
                            onTap: onCancel,
                            text: 'Cancel',
                            isPrimary: false,
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          smallPhone: 12,
                          mediumPhone: 14,
                          largePhone: 16,
                          tablet: 18,
                        )),
                        Expanded(
                          child: _ExitDialogButton(
                            onTap: onConfirm,
                            text: 'Exit',
                            isPrimary: true,
                            icon: Icons.exit_to_app,
                          ),
                        ),
                      ],
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

class _ExitDialogButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final bool isPrimary;
  final IconData? icon;

  const _ExitDialogButton({
    required this.onTap,
    required this.text,
    required this.isPrimary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: ResponsiveUtils.getResponsivePadding(
          context,
          smallPhone: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          mediumPhone: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          largePhone: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          tablet: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        ),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.surfaceLight
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: Colors.white,
                  size: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    smallPhone: 16,
                    mediumPhone: 18,
                    largePhone: 18,
                    tablet: 20,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  smallPhone: 6,
                  mediumPhone: 8,
                  largePhone: 8,
                  tablet: 10,
                )),
              ],
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

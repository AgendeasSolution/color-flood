import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../constants/game_constants.dart';
import '../components/color_flood_logo.dart';
import '../components/level_selection_grid.dart';
import '../components/how_to_play_dialog.dart';
import '../components/ad_banner.dart';
import '../components/animated_background.dart';
import '../components/glass_button.dart';
import '../components/update_popup.dart';
import '../services/level_progression_service.dart';
import '../services/audio_service.dart';
import '../utils/responsive_utils.dart';
import 'game_page.dart';
import 'other_games_screen.dart';


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
  final LevelProgressionService _levelService = LevelProgressionService.instance;
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Unlock all levels for testing purposes
    _levelService.unlockAllLevels();
    _loadLevelStatuses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh level statuses when returning to home screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLevelStatuses();
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
    super.dispose();
  }


  void _navigateToLevel(int level) async {
    try {
      // Validate level before navigation
      if (level < 1 || level > GameConstants.maxLevel) {
        debugPrint('Invalid level: $level');
        return;
      }
      
      if (!mounted || !context.mounted) return;
      
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GamePage(initialLevel: level),
        ),
      );
      // Refresh level statuses when returning from game
      if (mounted) {
        await _loadLevelStatuses();
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      // App should continue working even if navigation fails
    }
  }

  void _onLevelSelected(int level) {
    // Navigate directly to game for unlocked levels
    if (_levelStatuses[level] != LevelStatus.locked) {
      _audioService.playClickSound();
      _navigateToLevel(level);
    }
  }

  Future<void> _loadLevelStatuses() async {
    try {
      final statuses = await _levelService.getAllLevelStatuses();
      if (mounted) {
        setState(() {
          // Validate statuses map before setting
          _levelStatuses = statuses.isNotEmpty ? statuses : <int, LevelStatus>{};
        });
      }
    } catch (e) {
      // Silently handle errors - app should continue working
      debugPrint('Error loading level statuses: $e');
      if (mounted) {
        setState(() {
          // Set empty statuses as fallback
          _levelStatuses = <int, LevelStatus>{};
        });
      }
    }
  }


  void _showHowToPlay() {
    _audioService.playClickSound();
    HowToPlayDialog.show(context);
  }

  Widget _buildLevelSectionHeader() {
    return const SizedBox.shrink(); // Remove the "Select Level" label
  }

  void _toggleSound() {
    _audioService.playClickSound();
    setState(() {
      _audioService.setEnabled(!_audioService.isEnabled);
    });
  }

  void _navigateToOtherGames() {
    _audioService.playClickSound();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OtherGamesScreen(),
      ),
    );
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

  Widget _buildSoundToggleButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                child: Material(
                  color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleSound,
                      borderRadius: BorderRadius.circular(10),
                      splashColor: Colors.white.withOpacity(0.2),
                      highlightColor: Colors.white.withOpacity(0.1),
                      child: Container(
                        height: 36,
                        width: 36,
                        padding: const EdgeInsets.all(0),
                        child: Center(
                          child: Icon(
                            _audioService.isEnabled ? Icons.volume_up : Icons.volume_off,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmallHowToPlayButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF059669).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.9),
                        const Color(0xFF059669).withOpacity(0.8),
                        const Color(0xFF047857).withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                      child: InkWell(
                      onTap: _showHowToPlay,
                      borderRadius: BorderRadius.circular(10),
                      splashColor: Colors.white.withOpacity(0.2),
                      highlightColor: Colors.white.withOpacity(0.1),
                      child: Container(
                        height: 36,
                        width: 36,
                        padding: const EdgeInsets.all(0),
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1500),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, rotationValue, child) {
                              return Transform.rotate(
                                angle: rotationValue * 0.1,
                                child: const Icon(
                                  Icons.help_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
              Colors.white.withOpacity(0.18),
              Colors.white.withOpacity(0.08),
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
    final verticalPadding = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 12,
      mediumPhone: 14,
      largePhone: 16,
      tablet: 20,
    );
    final logoSpacing = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 4,
      mediumPhone: 6,
      largePhone: 8,
      tablet: 12,
    );
    final buttonSpacing = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 8,
      mediumPhone: 10,
      largePhone: 12,
      tablet: 16,
    );
    final bottomSpacing = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 12,
      mediumPhone: 16,
      largePhone: 20,
      tablet: 24,
    );
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          const AnimatedBackground(),
          
          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Color Flood Logo
                    const ColorFloodLogo(),
                    
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      smallPhone: 2,
                      mediumPhone: 3,
                      largePhone: 4,
                      tablet: 6,
                    )),
                    
                    // Level Selection Grid - Scrollable area only
                    Expanded(
                      child: LevelSelectionGrid(
                        onLevelSelected: _onLevelSelected,
                        levelStatuses: _levelStatuses,
                        customHeader: _buildLevelSectionHeader(),
                        compactTopSpacing: true,
                      ),
                    ),
                    
                    SizedBox(height: buttonSpacing * 2),
                    
                    // How to Play, Sound Toggle, and Test Update Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSmallHowToPlayButton(),
                        SizedBox(width: buttonSpacing),
                        _buildSoundToggleButton(),
                      ],
                    ),
                    
                    SizedBox(height: buttonSpacing * 3),
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
                          iconColor: const Color(0xFF60A5FA), // Light blue for mobile
                          gradientColors: [
                            const Color(0xFF3B82F6).withOpacity(0.25), // Blue
                            const Color(0xFF2563EB).withOpacity(0.15), // Darker blue
                          ],
                        ),
                        SizedBox(width: buttonSpacing),
                        _buildExternalNavigationButton(
                          icon: Icons.laptop,
                          label: AppConstants.webGamesLabel,
                          onTap: _openWebGames,
                          iconColor: const Color(0xFF34D399), // Light green for laptop
                          gradientColors: [
                            const Color(0xFF10B981).withOpacity(0.25), // Green
                            const Color(0xFF059669).withOpacity(0.15), // Darker green
                          ],
                        ),
                      ],
                    ),

                    // Add bottom padding to account for ad banner (90px height)
                    SizedBox(height: 30 + bottomSpacing),
                  ],
                ),
              ),
            ),
          ),
          
          // Fixed Ad Banner at bottom of screen (behind pop-up)
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
    );
  }




}

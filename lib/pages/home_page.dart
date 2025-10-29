import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../components/color_flood_logo.dart';
import '../components/level_selection_grid.dart';
import '../components/how_to_play_dialog.dart';
import '../components/ad_banner.dart';
import '../components/animated_background.dart';
import '../services/level_progression_service.dart';
import '../services/audio_service.dart';
import 'game_page.dart';


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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GamePage(initialLevel: level),
      ),
    );
    // Refresh level statuses when returning from game
    print('Returned from game, refreshing level statuses...');
    await _loadLevelStatuses();
  }

  void _onLevelSelected(int level) {
    // Navigate directly to game for unlocked levels
    if (_levelStatuses[level] != LevelStatus.locked) {
      _audioService.playClickSound();
      _navigateToLevel(level);
    }
  }

  Future<void> _loadLevelStatuses() async {
    print('Loading level statuses...');
    final statuses = await _levelService.getAllLevelStatuses();
    print('Loaded level statuses: $statuses');
    if (mounted) {
      setState(() {
        _levelStatuses = statuses;
      });
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleSound,
                    borderRadius: BorderRadius.circular(10),
                    splashColor: Colors.white.withOpacity(0.2),
                    highlightColor: Colors.white.withOpacity(0.1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _audioService.isEnabled ? Icons.volume_up : Icons.volume_off,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _audioService.isEnabled ? 'Sound On' : 'Sound Off',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Animated icon with rotation
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1500),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, rotationValue, child) {
                                return Transform.rotate(
                                  angle: rotationValue * 0.1,
                                  child: const Text(
                                    '✨',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            
                            // Beautiful text with gradient
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.white, Color(0xFFE5E7EB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: const Text(
                                'How to Play',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
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
            ),
          ),
        );
      },
    );
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GameConstants.mediumSpacing,
                vertical: GameConstants.mediumSpacing,
              ),
              child: Column(
                children: [
                  // Color Flood Logo
                  const ColorFloodLogo(),
                  
                  const SizedBox(height: GameConstants.smallSpacing),
                  
                  // Level Section with Grid and How to Play Button
                  Expanded(
                    child: Column(
                      children: [
                        // Level Selection Grid
                        Expanded(
                          child: LevelSelectionGrid(
                            onLevelSelected: _onLevelSelected,
                            levelStatuses: _levelStatuses,
                            customHeader: _buildLevelSectionHeader(),
                          ),
                        ),
                        
                        const SizedBox(height: GameConstants.smallSpacing),
                        
                        // How to Play and Sound Toggle Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: _buildSmallHowToPlayButton()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildSoundToggleButton()),
                          ],
                        ),
                        
                        const SizedBox(height: GameConstants.mediumSpacing),
                      ],
                    ),
                  ),
                  
                  // Add spacing to ensure content is above ad banner
                  const SizedBox(height: 60),
                ],
              ),
              ),
            ),
          ),
          
          // Fixed Ad Banner at bottom of screen
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const AdBanner(
              height: 90,
            ),
          ),
        ],
      ),
    );
  }




}

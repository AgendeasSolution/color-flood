import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../components/color_flood_logo.dart';
import '../components/level_selection_grid.dart';
import '../components/how_to_play_dialog.dart';
import '../components/ad_banner.dart';
import '../services/level_progression_service.dart';
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
  int _selectedLevel = 1; // Track the currently selected level
  Map<int, LevelStatus> _levelStatuses = {}; // Track level unlock status
  final LevelProgressionService _levelService = LevelProgressionService.instance;

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

    // Start fade animation only
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  void _navigateToGame() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GamePage(initialLevel: _selectedLevel),
      ),
    );
    // Refresh level statuses when returning from game
    print('Returned from game, refreshing level statuses...');
    await _loadLevelStatuses();
  }

  void _navigateToLevel(int level) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GamePage(initialLevel: level),
      ),
    );
    // Refresh level statuses when returning from game
    print('Returned from game, refreshing level statuses...');
    await _loadLevelStatuses();
  }

  void _onLevelSelected(int level) {
    // Only allow selection of unlocked levels
    if (_levelStatuses[level] != LevelStatus.locked) {
      setState(() {
        _selectedLevel = level;
      });
    }
  }

  Future<void> _loadLevelStatuses() async {
    print('Loading level statuses...');
    final statuses = await _levelService.getAllLevelStatuses();
    print('Loaded level statuses: $statuses');
    if (mounted) {
      setState(() {
        _levelStatuses = statuses;
        // Auto-select the last unlocked level
        _selectedLevel = _getLastUnlockedLevel(statuses);
      });
    }
  }

  /// Find the highest unlocked level from the level statuses
  int _getLastUnlockedLevel(Map<int, LevelStatus> statuses) {
    int lastUnlocked = 1; // Default to level 1
    
    for (int level = 1; level <= GameConstants.maxLevel; level++) {
      final status = statuses[level];
      if (status == LevelStatus.unlocked || status == LevelStatus.completed) {
        lastUnlocked = level;
      }
    }
    
    print('Auto-selected level: $lastUnlocked');
    return lastUnlocked;
  }

  void _showHowToPlay() {
    HowToPlayDialog.show(context);
  }

  Widget _buildCombinedHeader() {
    return Row(
      children: [
        const Text(
          'Select Level',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        _buildSmallHowToPlayButton(),
      ],
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


  Widget _buildStartPlayingButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _navigateToGame,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.5),
        ),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFEC4899), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            constraints: const BoxConstraints(minWidth: 88.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Start Level $_selectedLevel',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '🚀',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),
          
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
                    const SizedBox(height: GameConstants.mediumSpacing),
                  
                  // Color Flood Logo
                  const ColorFloodLogo(),
                  
                    const SizedBox(height: GameConstants.mediumSpacing),
                  
                  // Level Selection Grid with Combined Header
                  Expanded(
                    child: LevelSelectionGrid(
                      onLevelSelected: _onLevelSelected,
                      selectedLevel: _selectedLevel,
                      levelStatuses: _levelStatuses,
                      customHeader: _buildCombinedHeader(),
                    ),
                  ),
                  
                  const SizedBox(height: GameConstants.largeSpacing),
                  
                  // Start Playing Button
                  _buildStartPlayingButton(),
                  
                  // Add spacing to ensure button is above ad banner but not too far
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
            child: const AdBannerWithState(
              height: 90,
              margin: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  /// Creates a beautiful static background with floating particles and gradients
  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
            const Color(0xFF0F3460),
            const Color(0xFF533A7B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Floating particles - static random positions
          ...List.generate(16, (index) => _buildFloatingParticle(index)),
          
          // Glowing orbs - static random positions
          ...List.generate(10, (index) => _buildGlowingOrb(index)),
          
          // Color swatches - static random positions
          ...List.generate(8, (index) => _buildFloatingColorSwatch(index)),
          
          // Subtle overlay for depth
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  Colors.black.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Creates floating particles at random fixed positions
  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = 2.0 + random.nextDouble() * 3.0;
    
    // Fixed random positions - no movement
    final x = random.nextDouble();
    final y = random.nextDouble();
    
    return Positioned(
      left: x * MediaQuery.of(context).size.width,
      top: y * MediaQuery.of(context).size.height,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: [
            const Color(0xFFEF4444),
            const Color(0xFFEC4899),
            const Color(0xFF3B82F6),
            const Color(0xFF10B981),
            const Color(0xFFF59E0B),
          ][index % 5].withOpacity(0.6),
          boxShadow: [
            BoxShadow(
              color: [
                const Color(0xFFEF4444),
                const Color(0xFFEC4899),
                const Color(0xFF3B82F6),
                const Color(0xFF10B981),
                const Color(0xFFF59E0B),
              ][index % 5].withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  /// Creates glowing orbs at random fixed positions
  Widget _buildGlowingOrb(int index) {
    final random = math.Random(index + 100);
    final size = 40.0 + random.nextDouble() * 60.0;
    
    // Fixed random positions - no movement
    final x = random.nextDouble();
    final y = random.nextDouble();
    
    return Positioned(
      left: x * MediaQuery.of(context).size.width,
      top: y * MediaQuery.of(context).size.height,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              [
                const Color(0xFFEF4444),
                const Color(0xFFEC4899),
                const Color(0xFF3B82F6),
                const Color(0xFF10B981),
                const Color(0xFFF59E0B),
              ][index % 5].withOpacity(0.15),
              [
                const Color(0xFFEF4444),
                const Color(0xFFEC4899),
                const Color(0xFF3B82F6),
                const Color(0xFF10B981),
                const Color(0xFFF59E0B),
              ][index % 5].withOpacity(0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: [
                const Color(0xFFEF4444),
                const Color(0xFFEC4899),
                const Color(0xFF3B82F6),
                const Color(0xFF10B981),
                const Color(0xFFF59E0B),
              ][index % 5].withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
      ),
    );
  }

  /// Creates floating color swatches at random fixed positions
  Widget _buildFloatingColorSwatch(int index) {
    final random = math.Random(index + 200);
    final size = 20.0 + random.nextDouble() * 15.0;
    
    // Fixed random positions - no movement
    final x = random.nextDouble();
    final y = random.nextDouble();
    final rotation = random.nextDouble() * 2 * math.pi; // Random rotation angle
    
    return Positioned(
      left: x * MediaQuery.of(context).size.width,
      top: y * MediaQuery.of(context).size.height,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                [
                  const Color(0xFFEF4444),
                  const Color(0xFFEC4899),
                  const Color(0xFF3B82F6),
                  const Color(0xFF10B981),
                  const Color(0xFFF59E0B),
                ][index % 5].withOpacity(0.3),
                [
                  const Color(0xFFEF4444),
                  const Color(0xFFEC4899),
                  const Color(0xFF3B82F6),
                  const Color(0xFF10B981),
                  const Color(0xFFF59E0B),
                ][index % 5].withOpacity(0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: [
                  const Color(0xFFEF4444),
                  const Color(0xFFEC4899),
                  const Color(0xFF3B82F6),
                  const Color(0xFF10B981),
                  const Color(0xFFF59E0B),
                ][index % 5].withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Creates an amazing and beautiful How to Play button with modern design
  Widget _buildAmazingHowToPlayButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF059669).withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: -10,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showHowToPlay,
                      borderRadius: BorderRadius.circular(12),
                      splashColor: Colors.white.withOpacity(0.2),
                      highlightColor: Colors.white.withOpacity(0.1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
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
                                    style: TextStyle(fontSize: 16),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
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

}

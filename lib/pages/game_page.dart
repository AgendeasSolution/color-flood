import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/game_constants.dart';
import '../types/game_types.dart';
import '../services/game_service.dart';
import '../services/level_progression_service.dart';
import '../services/interstitial_ad_service.dart';
import '../services/audio_service.dart';
import '../components/game_board.dart';
import '../components/color_palette.dart';
import '../components/hud_card.dart';
import '../components/glass_button.dart';
import '../components/ad_banner.dart';
import '../components/animated_background.dart';
import '../utils/responsive_utils.dart';

/// Main game page where the Color Flood game is played
class GamePage extends StatefulWidget {
  final int? initialLevel;

  const GamePage({super.key, this.initialLevel});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  // Game state
  late GameConfig _gameConfig;
  int _moves = 0;
  bool _isGameOver = false;
  GameState _gameState = GameState.notStarted;
  final GameService _gameService = GameService();
  final LevelProgressionService _levelService =
      LevelProgressionService.instance;
  final AudioService _audioService = AudioService();

  // Animation controllers
  late AnimationController _popupAnimationController;
  late Animation<double> _popupScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startNewGame();
    _preloadInterstitialAd();
  }

  void _preloadInterstitialAd() {
    // Preload interstitial ad for better user experience
    InterstitialAdService.instance.preloadAd();
  }

  Future<void> _handleExit() async {
    _audioService.playClickSound();
    // Show interstitial ad with 50% probability when exiting
    final adShown = await InterstitialAdService.instance
        .showAdWithProbability();

    // Navigate back to home page immediately after ad (or if no ad shown)
    if (mounted) {
      Navigator.of(context).pop();
    }

    // Preload next ad for future use
    if (adShown) {
      InterstitialAdService.instance.preloadAd();
    }
  }

  void _initializeAnimations() {
    _popupAnimationController = AnimationController(
      vsync: this,
      duration: GameConstants.popupAnimationDuration,
    );
    _popupScaleAnimation = CurvedAnimation(
      parent: _popupAnimationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _popupAnimationController.dispose();
    super.dispose();
  }

  void _startNewGame() {
    setState(() {
      final level = widget.initialLevel ?? 1;
      _gameConfig = _gameService.createGameConfig(level);
      _moves = 0;
      _isGameOver = false;
      _gameState = GameState.playing;
    });
  }

  Future<void> _restartCurrentLevel() async {
    _audioService.playClickSound();
    // Show interstitial ad with 50% probability for restart (user-friendly)
    final adShown = await InterstitialAdService.instance
        .showAdWithProbability();

    setState(() {
      _gameConfig = _gameConfig.copyWith(
        grid: _gameService.cloneGrid(_gameConfig.originalGrid),
      );
      _moves = 0;
      _isGameOver = false;
      _gameState = GameState.playing;
    });

    // Preload next ad for future use
    if (adShown) {
      InterstitialAdService.instance.preloadAd();
    }
  }

  Future<void> _nextLevel() async {
    _audioService.playClickSound();
    // Show interstitial ad with 100% probability when advancing to next level
    // Since there are only a few levels, show ad every time
    final adShown = await InterstitialAdService.instance.showAdAlways();

    final nextLevel = _gameConfig.level + 1;
    if (nextLevel <= GameConstants.maxLevel) {
      setState(() {
        _gameConfig = _gameService.createGameConfig(nextLevel);
        _moves = 0;
        _isGameOver = false;
        _gameState = GameState.playing;
      });
    } else {
      // Game completed - all levels finished
      _showGameCompletedDialog();
    }

    // Preload next ad for future use
    if (adShown) {
      InterstitialAdService.instance.preloadAd();
    }
  }

  void _handleColorSelection(Color newColor) {
    if (_isGameOver || _gameState != GameState.playing) return;

    if (!_gameService.isValidMove(_gameConfig.grid, newColor)) return;

    _audioService.playSwipeSound();

    setState(() {
      _moves++;
      _gameConfig = _gameConfig.copyWith(
        grid: _gameService.applyMove(_gameConfig.grid, newColor),
      );
    });

    _checkWinCondition();
  }

  void _checkWinCondition() {
    if (_gameService.isGridSolved(_gameConfig.grid)) {
      _audioService.playWinSound();
      _endGame(GameResult.win);
      _markLevelCompleted(); // Move this after _endGame to ensure it's called
    } else if (_moves >= _gameConfig.maxMoves) {
      _audioService.playFailSound();
      _endGame(GameResult.lose);
    }
  }

  Future<void> _markLevelCompleted() async {
    try {
      await _levelService.completeLevel(_gameConfig.level);
    } catch (e) {
      // Silently handle errors
    }
  }

  void _endGame(GameResult result) {
    setState(() {
      _isGameOver = true;
      _gameState = GameState.gameOver;
    });

    Future.delayed(GameConstants.gameOverDelay, () {
      if (mounted) {
        _showGameOverDialog(result);
      }
    });
  }

  void _showGameOverDialog(GameResult result) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) => _GameOverDialog(
        didWin: result == GameResult.win,
        level: _gameConfig.level,
        moves: _moves,
        maxMoves: _gameConfig.maxMoves,
        onNextLevel: () async {
          Navigator.of(context).pop();
          await _nextLevel();
        },
        onRestart: () async {
          Navigator.of(context).pop();
          await _restartCurrentLevel();
        },
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        _popupAnimationController.forward(from: 0.0);
        return ScaleTransition(
          scale: _popupScaleAnimation,
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  void _showGameCompletedDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) => _GameCompletedDialog(
        onPlayAgain: () {
          _audioService.playClickSound();
          Navigator.of(context).pop();
          _startNewGame();
        },
        onExit: () {
          _audioService.playClickSound();
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        _popupAnimationController.forward(from: 0.0);
        return ScaleTransition(
          scale: _popupScaleAnimation,
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _handleExit();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Animated Background
            const AnimatedBackground(),

            // Main Content
            SafeArea(
              child: Stack(
                children: [
                  // Main game content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Moves Display (Above Game Board - with background)
                        HudCard(
                          padding: ResponsiveUtils.getResponsivePadding(
                            context,
                            smallPhone: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            mediumPhone: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            largePhone: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            tablet: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppConstants.movesLabel,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                                    context,
                                    smallPhone: 10,
                                    mediumPhone: 11,
                                    largePhone: 12,
                                    tablet: 14,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(
                                context,
                                smallPhone: 4,
                                mediumPhone: 5,
                                largePhone: 6,
                                tablet: 8,
                              )),
                              Text(
                                '$_moves',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                                    context,
                                    smallPhone: 20,
                                    mediumPhone: 22,
                                    largePhone: 24,
                                    tablet: 28,
                                  ),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                ' / ',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                                    context,
                                    smallPhone: 20,
                                    mediumPhone: 22,
                                    largePhone: 24,
                                    tablet: 28,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white60,
                                ),
                              ),
                              Text(
                                '${_gameConfig.maxMoves}',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                                    context,
                                    smallPhone: 20,
                                    mediumPhone: 22,
                                    largePhone: 24,
                                    tablet: 28,
                                  ),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          smallPhone: 12,
                          mediumPhone: 16,
                          largePhone: 20,
                          tablet: 30,
                        )),
                        // Game Board - Moved down slightly
                        GameBoard(
                          grid: _gameConfig.grid,
                          gridSize: _gameConfig.gridSize,
                          gameStarted: true, // Always show the game board
                        ),

                        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          smallPhone: 12,
                          mediumPhone: 16,
                          largePhone: 20,
                          tablet: 40,
                        )),

                        // Color Palette
                        ColorPalette(
                          colors: GameConstants.gameColors,
                          onColorSelected: _handleColorSelection,
                          isDisabled: _isGameOver,
                        ),
                      ],
                    ),
                  ),

                  // HUD Elements
                  _buildHud(),
                ],
              ),
            ),

            // Fixed Ad Banner at bottom of screen
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: const AdBanner(height: 90),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHud() {
    return Stack(
      children: [
        // Top Row Container (Exit, Level, Reset)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GameConstants.mediumSpacing,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Exit Button (Left)
                GlassButton(
                  onTap: _handleExit,
                  padding: ResponsiveUtils.getResponsivePadding(
                    context,
                    smallPhone: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    mediumPhone: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    largePhone: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tablet: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: ResponsiveUtils.getResponsiveIconSize(context),
                  ),
                ),

                // Level Display (Center)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppConstants.levelLabel,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          smallPhone: 20,
                          mediumPhone: 22,
                          largePhone: 24,
                          tablet: 28,
                        ),
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      smallPhone: 4,
                      mediumPhone: 5,
                      largePhone: 6,
                      tablet: 8,
                    )),
                    Text(
                      '${_gameConfig.level}',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          smallPhone: 20,
                          mediumPhone: 22,
                          largePhone: 24,
                          tablet: 28,
                        ),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                // Reset Button (Right)
                GlassButton(
                  onTap: _restartCurrentLevel,
                  padding: ResponsiveUtils.getResponsivePadding(
                    context,
                    smallPhone: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    mediumPhone: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    largePhone: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tablet: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: ResponsiveUtils.getResponsiveIconSize(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Game over dialog widget
class _GameOverDialog extends StatelessWidget {
  final bool didWin;
  final int level;
  final int moves;
  final int maxMoves;
  final VoidCallback onNextLevel;
  final VoidCallback onRestart;

  const _GameOverDialog({
    required this.didWin,
    required this.level,
    required this.moves,
    required this.maxMoves,
    required this.onNextLevel,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              width: min(500, MediaQuery.of(context).size.width * 0.9),
              padding: const EdgeInsets.all(GameConstants.largeSpacing),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      didWin ? "🎉" : "😔",
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          smallPhone: 40,
                          mediumPhone: 45,
                          largePhone: 50,
                          tablet: 60,
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      smallPhone: 12,
                      mediumPhone: 14,
                      largePhone: 16,
                      tablet: 20,
                    )),
                    Text(
                      didWin
                          ? AppConstants.levelCompleteText
                          : AppConstants.gameOverText,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          smallPhone: 24,
                          mediumPhone: 26,
                          largePhone: 28,
                          tablet: 36,
                        ),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      smallPhone: 6,
                      mediumPhone: 8,
                      largePhone: 10,
                      tablet: 12,
                    )),
                    Text(
                      didWin
                          ? "Amazing work! You solved it in $moves moves!"
                          : "You used all $maxMoves moves. Try again!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
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
                      smallPhone: 16,
                      mediumPhone: 20,
                      largePhone: 24,
                      tablet: 32,
                    )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          label: AppConstants.levelStatLabel,
                          value: "$level",
                          context: context,
                        ),
                        _StatItem(
                          label: AppConstants.movesUsedStatLabel,
                          value: "$moves",
                          context: context,
                        ),
                        _StatItem(
                          label: AppConstants.maxMovesStatLabel,
                          value: "$maxMoves",
                          context: context,
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      smallPhone: 20,
                      mediumPhone: 24,
                      largePhone: 28,
                      tablet: 36,
                    )),
                    if (didWin)
                      _PopupButton(
                        context: context,
                        onTap: onNextLevel,
                        text: AppConstants.nextLevelText,
                        isPrimary: true,
                      )
                    else
                      _PopupButton(
                        context: context,
                        onTap: onRestart,
                        text: AppConstants.playAgainText,
                        isPrimary: false,
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

/// Stat item widget for game over dialog
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;

  const _StatItem({required this.label, required this.value, required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white70,
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              this.context,
              smallPhone: 10,
              mediumPhone: 11,
              largePhone: 12,
              tablet: 14,
            ),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
          this.context,
          smallPhone: 2,
          mediumPhone: 3,
          largePhone: 4,
          tablet: 6,
        )),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              this.context,
              smallPhone: 20,
              mediumPhone: 24,
              largePhone: 28,
              tablet: 36,
            ),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Game completed dialog widget
class _GameCompletedDialog extends StatelessWidget {
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const _GameCompletedDialog({required this.onPlayAgain, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              width: ResponsiveUtils.getResponsiveDialogWidth(context),
              padding: ResponsiveUtils.getResponsivePadding(
                context,
                smallPhone: const EdgeInsets.all(16),
                mediumPhone: const EdgeInsets.all(18),
                largePhone: const EdgeInsets.all(20),
                tablet: const EdgeInsets.all(24),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "🏆",
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          smallPhone: 40,
                          mediumPhone: 45,
                          largePhone: 50,
                          tablet: 60,
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      smallPhone: 12,
                      mediumPhone: 14,
                      largePhone: 16,
                      tablet: 20,
                    )),
                    Text(
                      "Congratulations!",
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          smallPhone: 24,
                          mediumPhone: 26,
                          largePhone: 28,
                          tablet: 36,
                        ),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      smallPhone: 6,
                      mediumPhone: 8,
                      largePhone: 10,
                      tablet: 12,
                    )),
                    Text(
                      "You've completed all 14 levels!\nYou are a Color Flood master!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
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
                      smallPhone: 16,
                      mediumPhone: 20,
                      largePhone: 24,
                      tablet: 32,
                    )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _PopupButton(
                          context: context,
                          onTap: onPlayAgain,
                          text: "Play Again",
                          isPrimary: true,
                        ),
                        _PopupButton(
                          context: context,
                          onTap: onExit,
                          text: "Exit",
                          isPrimary: false,
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

/// Popup button widget
class _PopupButton extends StatelessWidget {
  final BuildContext context;
  final VoidCallback onTap;
  final String text;
  final bool isPrimary;

  const _PopupButton({
    required this.context,
    required this.onTap,
    required this.text,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isPrimary
        ? const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFEC4899), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFF22C55E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: ResponsiveUtils.getResponsivePadding(
            context,
            smallPhone: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            mediumPhone: const EdgeInsets.symmetric(vertical: 14, horizontal: 26),
            largePhone: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
            tablet: const EdgeInsets.symmetric(vertical: 18, horizontal: 36),
          ),
          constraints: BoxConstraints(
            minWidth: ResponsiveUtils.getResponsiveValue(
              context: context,
              smallPhone: 88.0,
              mediumPhone: 100.0,
              largePhone: 110.0,
              tablet: 120.0,
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.getResponsiveFontSize(
                context,
                smallPhone: 16,
                mediumPhone: 17,
                largePhone: 18,
                tablet: 22,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

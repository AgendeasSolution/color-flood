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
      print('Attempting to mark level ${_gameConfig.level} as completed...');
      await _levelService.completeLevel(_gameConfig.level);
      print('Level ${_gameConfig.level} successfully marked as completed');
    } catch (e) {
      print('Error marking level as completed: $e');
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                AppConstants.movesLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(width: GameConstants.smallSpacing),
                              Text(
                                '$_moves',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                ' / ',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white60,
                                ),
                              ),
                              Text(
                                '${_gameConfig.maxMoves}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30), // Increased gap below moves
                        // Game Board - Moved down slightly
                        GameBoard(
                          grid: _gameConfig.grid,
                          gridSize: _gameConfig.gridSize,
                          gameStarted: true, // Always show the game board
                        ),

                        const SizedBox(height: 40),

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 18,
                  ),
                ),

                // Level Display (Center)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      AppConstants.levelLabel,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(width: GameConstants.smallSpacing),
                    Text(
                      '${_gameConfig.level}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                // Reset Button (Right)
                GlassButton(
                  onTap: _restartCurrentLevel,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 18,
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
                      style: const TextStyle(fontSize: 50),
                    ),
                    const SizedBox(height: GameConstants.mediumSpacing),
                    Text(
                      didWin
                          ? AppConstants.levelCompleteText
                          : AppConstants.gameOverText,
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: GameConstants.smallSpacing),
                    Text(
                      didWin
                          ? "Amazing work! You solved it in $moves moves!"
                          : "You used all $maxMoves moves. Try again!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: GameConstants.largeSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          label: AppConstants.levelStatLabel,
                          value: "$level",
                        ),
                        _StatItem(
                          label: AppConstants.movesUsedStatLabel,
                          value: "$moves",
                        ),
                        _StatItem(
                          label: AppConstants.maxMovesStatLabel,
                          value: "$maxMoves",
                        ),
                      ],
                    ),
                    const SizedBox(height: GameConstants.extraLargeSpacing),
                    if (didWin)
                      _PopupButton(
                        onTap: onNextLevel,
                        text: AppConstants.nextLevelText,
                        isPrimary: true,
                      )
                    else
                      _PopupButton(
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

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
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
                    const Text("🏆", style: TextStyle(fontSize: 50)),
                    const SizedBox(height: GameConstants.mediumSpacing),
                    const Text(
                      "Congratulations!",
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: GameConstants.smallSpacing),
                    const Text(
                      "You've completed all 14 levels!\nYou are a Color Flood master!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: GameConstants.largeSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _PopupButton(
                          onTap: onPlayAgain,
                          text: "Play Again",
                          isPrimary: true,
                        ),
                        _PopupButton(
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
  final VoidCallback onTap;
  final String text;
  final bool isPrimary;

  const _PopupButton({
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          constraints: const BoxConstraints(minWidth: 88.0),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

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
import '../services/rewarded_ad_service.dart';
import '../services/audio_service.dart';
import '../services/daily_puzzle_service.dart';
import '../components/game_board.dart';
import '../components/color_palette.dart';
import '../components/back_button_row.dart';
import '../components/ad_banner.dart';
import '../components/animated_background.dart';
import '../utils/responsive_utils.dart';
import 'daily_challenge_screen.dart';

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
  bool _isLoadingExtraMoves = false; // Loading state for extra moves button
  bool _isSolving = false; // Track if auto-solving is in progress
  final GameService _gameService = GameService();
  final LevelProgressionService _levelService =
      LevelProgressionService.instance;
  final AudioService _audioService = AudioService();
  final DailyPuzzleService _dailyPuzzleService = DailyPuzzleService.instance;
  bool _isDailyPuzzle = false;

  // Animation controllers
  late AnimationController _popupAnimationController;
  late Animation<double> _popupScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startNewGame();
    _preloadInterstitialAd();
    _preloadRewardedAd();
    _showEntryAd();
  }

  void _preloadInterstitialAd() {
    // Preload interstitial ad for better user experience
    InterstitialAdService.instance.preloadAd();
  }

  void _preloadRewardedAd() {
    // Preload rewarded ad for better user experience
    RewardedAdService.instance.preloadAd();
  }

  void _showEntryAd() {
    // Show interstitial ad with 50% probability when entering game screen
    // Wait for the frame to build first
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          final adShown = await InterstitialAdService.instance.showAdWithProbability();
          // Preload next ad for future use
          if (adShown) {
            InterstitialAdService.instance.preloadAd();
          }
        } catch (e) {
          // Silently handle ad failures - don't interrupt user experience
          // Still try to preload for next time
          InterstitialAdService.instance.preloadAd();
        }
      }
    });
  }

  Future<void> _handleExit() async {
    _audioService.playClickSound();
    
    // Show confirmation dialog
    final shouldExit = await _showExitConfirmationDialog();
    if (!shouldExit || !mounted) {
      return; // User cancelled or widget is disposed
    }
    
    // Show interstitial ad with 100% probability when exiting (always show)
    try {
      final adShown = await InterstitialAdService.instance.showAdAlways();
      // Preload next ad for future use
      if (adShown) {
        InterstitialAdService.instance.preloadAd();
      }
    } catch (e) {
      // Silently handle ad failures - still allow user to exit
      InterstitialAdService.instance.preloadAd();
    }

    // Navigate back to home page immediately after ad (or if ad failed)
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    if (!mounted || !context.mounted) return false;
    
    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => _ExitConfirmationDialog(
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

  Future<void> _startNewGame() async {
    if (!mounted) return;
    try {
      // Check if this is a daily puzzle (level 0)
      if (widget.initialLevel == 0) {
        _isDailyPuzzle = true;
        try {
          final puzzle = await _dailyPuzzleService.getTodaysPuzzle();
          if (mounted && puzzle.grid.isNotEmpty) {
            setState(() {
              _gameConfig = puzzle;
              _moves = 0;
              _isGameOver = false;
              _gameState = GameState.playing;
            });
            return;
          }
        } catch (e) {
          // Fall through to regular level if daily puzzle fails
          _isDailyPuzzle = false;
        }
      }
      
      // Regular level game
      _isDailyPuzzle = false;
      // Validate initial level
      final requestedLevel = widget.initialLevel ?? 1;
      final validLevel = requestedLevel.clamp(1, GameConstants.maxLevel);
      
      // Create game config with error handling
      GameConfig? config;
      try {
        config = _gameService.createGameConfig(validLevel);
        // Validate config before using
        if (config.grid.isEmpty || config.gridSize <= 0) {
          throw Exception('Invalid game config');
        }
      } catch (e) {
        // Retry with level 1 as fallback
        try {
          config = _gameService.createGameConfig(1);
          if (config.grid.isEmpty || config.gridSize <= 0) {
            throw Exception('Fallback config also invalid');
          }
        } catch (e2) {
          // Create minimal valid config as last resort
          config = _gameService.createGameConfig(1);
        }
      }
      
      if (mounted) {
        setState(() {
          _gameConfig = config!;
          _moves = 0;
          _isGameOver = false;
          _gameState = GameState.playing;
        });
      }
    } catch (e) {
      // If everything fails, try to create a basic game
      if (mounted) {
        try {
          setState(() {
            _gameConfig = _gameService.createGameConfig(1);
            _moves = 0;
            _isGameOver = false;
            _gameState = GameState.playing;
          });
        } catch (e2) {
          // App should continue even if game can't start
        }
      }
    }
  }

  Future<void> _restartCurrentLevel() async {
    _audioService.playClickSound();
    // Show interstitial ad with 50% probability for restart (user-friendly)
    try {
      final adShown = await InterstitialAdService.instance
          .showAdWithProbability();
      // Preload next ad for future use
      if (adShown) {
        InterstitialAdService.instance.preloadAd();
      }
    } catch (e) {
      // Silently handle ad failures - don't interrupt user experience
      InterstitialAdService.instance.preloadAd();
    }

    setState(() {
      _gameConfig = _gameConfig.copyWith(
        grid: _gameService.cloneGrid(_gameConfig.originalGrid),
      );
      _moves = 0;
      _isGameOver = false;
      _gameState = GameState.playing;
    });
  }

  Future<void> _nextLevel() async {
    _audioService.playClickSound();
    // Show interstitial ad with 100% probability when advancing to next level
    // Since there are only a few levels, show ad every time
    try {
      final adShown = await InterstitialAdService.instance.showAdAlways();
      // Preload next ad for future use
      if (adShown) {
        InterstitialAdService.instance.preloadAd();
      }
    } catch (e) {
      // Silently handle ad failures - don't interrupt user experience
      InterstitialAdService.instance.preloadAd();
    }

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
  }

  /// Auto-solve the puzzle step by step
  Future<void> _autoSolve() async {
    if (!mounted) return;
    if (_isGameOver || _gameState != GameState.playing || _isSolving) return;
    
    setState(() {
      _isSolving = true;
    });
    
    _audioService.playClickSound();
    
    // Solve the puzzle automatically
    while (!_isGameOver && _gameState == GameState.playing && mounted) {
      // Check if already solved
      if (_gameService.isGridSolved(_gameConfig.grid)) {
        break;
      }
      
      // Check if we've run out of moves
      if (_moves >= _gameConfig.maxMoves) {
        break;
      }
      
      // Find the best move
      final bestColor = _gameService.findBestMove(_gameConfig.grid);
      
      // Check if move is valid
      if (!_gameService.isValidMove(_gameConfig.grid, bestColor)) {
        // If no valid move found, try any available color
        bool foundValidMove = false;
        for (final color in GameConstants.gameColors) {
          if (_gameService.isValidMove(_gameConfig.grid, color)) {
            await _applyAutoMove(color);
            foundValidMove = true;
            break;
          }
        }
        if (!foundValidMove) {
          break; // No valid moves available
        }
      } else {
        await _applyAutoMove(bestColor);
      }
      
      // Wait between moves so user can see the solution
      await Future.delayed(const Duration(milliseconds: 600));
      
      // Check win condition after each move
      _checkWinCondition();
      
      if (_isGameOver) {
        break;
      }
    }
    
    if (mounted) {
      setState(() {
        _isSolving = false;
      });
    }
  }
  
  /// Apply a move automatically (without user interaction)
  Future<void> _applyAutoMove(Color newColor) async {
    if (!mounted) return;
    if (_isGameOver || _gameState != GameState.playing) return;
    
    // Validate game config exists and is valid
    if (_gameConfig.grid.isEmpty || _gameConfig.gridWidth <= 0 || _gameConfig.gridHeight <= 0) {
      return;
    }

    try {
      // Validate move before applying
      if (!_gameService.isValidMove(_gameConfig.grid, newColor)) {
        return;
      }

      // Play sound with error handling
      try {
        _audioService.playSwipeSound();
      } catch (e) {
        // Continue even if audio fails
      }

      // Apply move with validation
      final newGrid = _gameService.applyMove(_gameConfig.grid, newColor);
      
      // Validate new grid before updating state
      if (newGrid.isEmpty || 
          newGrid.length != _gameConfig.gridHeight ||
          (newGrid.isNotEmpty && newGrid[0].length != _gameConfig.gridWidth)) {
        return;
      }
      
      if (mounted) {
        setState(() {
          _moves++;
          _gameConfig = _gameConfig.copyWith(grid: newGrid);
        });
      }
    } catch (e) {
      // Silently handle errors - don't interrupt gameplay
    }
  }

  void _handleColorSelection(Color newColor) {
    if (!mounted) return;
    if (_isGameOver || _gameState != GameState.playing || _isSolving) return;
    
    // Validate game config exists and is valid
    if (_gameConfig.grid.isEmpty || _gameConfig.gridWidth <= 0 || _gameConfig.gridHeight <= 0) {
      return;
    }

    try {
      // Validate move before applying
      if (!_gameService.isValidMove(_gameConfig.grid, newColor)) {
        return;
      }

      // Play sound with error handling
      try {
        _audioService.playSwipeSound();
      } catch (e) {
        // Continue even if audio fails
      }

      // Apply move with validation
      final newGrid = _gameService.applyMove(_gameConfig.grid, newColor);
      
      // Validate new grid before updating state
      if (newGrid.isEmpty || 
          newGrid.length != _gameConfig.gridHeight ||
          (newGrid.isNotEmpty && newGrid[0].length != _gameConfig.gridWidth)) {
        return;
      }
      
      if (mounted) {
        setState(() {
          _moves++;
          _gameConfig = _gameConfig.copyWith(grid: newGrid);
        });
      }

      _checkWinCondition();
    } catch (e) {
      // Silently handle errors - don't interrupt gameplay
    }
  }

  /// Check if extra moves button should be shown (when 2 moves remaining)
  bool _shouldShowExtraMovesButton() {
    if (_isGameOver || _gameState != GameState.playing) return false;
    final movesRemaining = _gameConfig.maxMoves - _moves;
    return movesRemaining <= 2 && movesRemaining > 0;
  }

  /// Handle extra moves button tap - show rewarded ad
  Future<void> _handleExtraMovesButton() async {
    if (!_shouldShowExtraMovesButton() || _isLoadingExtraMoves) {
      return;
    }
    
    if (mounted) {
      setState(() {
        _isLoadingExtraMoves = true;
      });
    }
    
    try {
      _audioService.playClickSound();
      
      final rewardEarned = await RewardedAdService.instance.showAd(
        onRewarded: (reward) {
          // Get reward amount from ad, default to 3 if not found
          final rewardAmount = reward.amount > 0 ? reward.amount.toInt() : 3;
          
          // Add extra moves based on reward amount
          if (mounted) {
            setState(() {
              _gameConfig = _gameConfig.copyWith(
                maxMoves: _gameConfig.maxMoves + rewardAmount,
              );
              _isLoadingExtraMoves = false;
            });
            // Show success message with actual reward amount
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('+$rewardAmount Extra Moves Added!'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
            // Preload next ad for future use
            RewardedAdService.instance.preloadAd();
          }
        },
        onAdFailedToShow: () {
          if (mounted) {
            setState(() {
              _isLoadingExtraMoves = false;
            });
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ad not available. Please try again later.'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.orange,
              ),
            );
            // Preload next ad for next time
            RewardedAdService.instance.preloadAd();
          }
        },
      );
      
      // If ad wasn't shown, try to preload for next time
      if (!rewardEarned) {
        if (mounted) {
          setState(() {
            _isLoadingExtraMoves = false;
          });
        }
        RewardedAdService.instance.preloadAd();
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoadingExtraMoves = false;
        });
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Preload for next time
      RewardedAdService.instance.preloadAd();
    }
  }

  void _checkWinCondition() {
    if (!mounted) return;
    
    // Validate game config before checking win condition
    if (_gameConfig.grid.isEmpty || _gameConfig.gridSize <= 0) {
      return;
    }
    
    try {
      // Check if grid is solved
      final isSolved = _gameService.isGridSolved(_gameConfig.grid);
      
      if (isSolved) {
        try {
          _audioService.playWinSound();
        } catch (e) {
          // Continue even if audio fails
        }
        _endGame(GameResult.win);
        _markLevelCompleted(); // Move this after _endGame to ensure it's called
      } else if (_moves >= _gameConfig.maxMoves) {
        try {
          _audioService.playFailSound();
        } catch (e) {
          // Continue even if audio fails
        }
        _endGame(GameResult.lose);
      }
    } catch (e) {
      // Silently handle errors - game should continue
    }
  }

  Future<void> _markLevelCompleted() async {
    try {
      if (_isDailyPuzzle) {
        // Mark daily puzzle as completed using the new system
        final today = DateTime.now();
        await _dailyPuzzleService.completeDailyPuzzleForDate(today);
      } else {
        // Mark regular level as completed
        await _levelService.completeLevel(_gameConfig.level);
      }
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
    if (!mounted || !context.mounted) return;
    
    try {
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (dialogContext, anim1, anim2) => _GameOverDialog(
          didWin: result == GameResult.win,
          level: _gameConfig.level,
          moves: _moves,
          maxMoves: _gameConfig.maxMoves,
          isDailyPuzzle: _isDailyPuzzle,
          onNextLevel: _isDailyPuzzle ? null : () async {
            try {
              _audioService.playClickSound();
            } catch (e) {
              // Continue even if audio fails
            }
            if (dialogContext.mounted) {
              try {
                Navigator.of(dialogContext).pop();
              } catch (e) {
                // Continue even if navigation fails
              }
            }
            await _nextLevel();
          },
          onRestart: () async {
            try {
              _audioService.playClickSound();
            } catch (e) {
              // Continue even if audio fails
            }
            if (dialogContext.mounted) {
              try {
                Navigator.of(dialogContext).pop();
              } catch (e) {
                // Continue even if navigation fails
              }
            }
            await _restartCurrentLevel();
          },
          onBackToHome: _isDailyPuzzle ? () async {
            try {
              _audioService.playClickSound();
            } catch (e) {
              // Continue even if audio fails
            }
            // Close dialog first
            if (dialogContext.mounted) {
              try {
                Navigator.of(dialogContext).pop();
              } catch (e) {
                // Continue even if dialog pop fails
              }
            }
            
            // Show 100% interstitial ad before navigating
            try {
              final adShown = await InterstitialAdService.instance.showAdAlways();
              // Preload next ad for future use
              if (adShown) {
                InterstitialAdService.instance.preloadAd();
              }
            } catch (e) {
              // Silently handle ad failures - still allow navigation
              InterstitialAdService.instance.preloadAd();
            }
            
            // Navigate back to Daily Challenge Screen (not home)
            if (mounted && context.mounted) {
              try {
                // Pop game page, then navigate to daily challenge screen
                Navigator.of(context).pop();
                await Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const DailyChallengeScreen(),
                  ),
                );
              } catch (e) {
                // If navigation fails, just pop to home
                try {
                  Navigator.of(context).pop();
                } catch (e2) {
                  // Continue even if navigation fails
                }
              }
            }
          } : null,
        ),
        transitionBuilder: (context, anim1, anim2, child) {
          try {
            _popupAnimationController.forward(from: 0.0);
          } catch (e) {
            // Continue even if animation fails
          }
          return ScaleTransition(
            scale: _popupScaleAnimation,
            child: FadeTransition(opacity: anim1, child: child),
          );
        },
      );
    } catch (e) {
      // App should continue even if dialog fails to show
    }
  }

  void _showGameCompletedDialog() {
    if (!mounted || !context.mounted) return;
    
    try {
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: '',
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, anim1, anim2) => _GameCompletedDialog(
          onPlayAgain: () {
            try {
              _audioService.playClickSound();
            } catch (e) {
              // Continue even if audio fails
            }
            if (context.mounted) {
              try {
                Navigator.of(context).pop();
              } catch (e) {
                // Continue even if navigation fails
              }
            }
            _startNewGame();
          },
          onExit: () {
            try {
              _audioService.playClickSound();
            } catch (e) {
              // Continue even if audio fails
            }
            if (context.mounted) {
              try {
                Navigator.of(context).pop();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                // Continue even if navigation fails
              }
            }
          },
        ),
        transitionBuilder: (context, anim1, anim2, child) {
          try {
            _popupAnimationController.forward(from: 0.0);
          } catch (e) {
            // Continue even if animation fails
          }
          return ScaleTransition(
            scale: _popupScaleAnimation,
            child: FadeTransition(opacity: anim1, child: child),
          );
        },
      );
    } catch (e) {
      // App should continue even if dialog fails
    }
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
                        // Game Board - Moved down slightly
                        GameBoard(
                          grid: _gameConfig.grid,
                          gridWidth: _gameConfig.gridWidth,
                          gridHeight: _gameConfig.gridHeight,
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
                          isDisabled: _isGameOver || _isSolving,
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
        // Back Button Row with Level Number (Top)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: BackButtonRow(
            onBack: _handleExit,
            onReset: _restartCurrentLevel,
            centerWidget: _isDailyPuzzle
                ? Text(
                    AppConstants.todaysChallengeLabel,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        smallPhone: 14,
                        mediumPhone: 15,
                        largePhone: 16,
                        tablet: 18,
                      ),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppConstants.levelLabel.toUpperCase(),
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
          ),
        ),

        // Moves Counter (Below Back Button Row)
        Positioned(
          top: ResponsiveUtils.getResponsiveValue(
            context: context,
            smallPhone: 60.0,
            mediumPhone: 65.0,
            largePhone: 70.0,
            tablet: 80.0,
          ),
          left: 0,
          right: 0,
          child: Center(
            child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: ResponsiveUtils.getResponsivePadding(
                        context,
                        smallPhone: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        mediumPhone: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        largePhone: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        tablet: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFDBEAFE), // Light blue border
                          width: 2.0,
                        ),
                        boxShadow: [
                          // Main shadow for depth
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                          // Soft outer glow
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            spreadRadius: -2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              smallPhone: 24,
                              mediumPhone: 26,
                              largePhone: 28,
                              tablet: 30,
                            ),
                            color: Colors.black87,
                          ),
                          SizedBox(width: ResponsiveUtils.getResponsiveSpacing(
                            context,
                            smallPhone: 8,
                            mediumPhone: 10,
                            largePhone: 12,
                            tablet: 14,
                          )),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$_moves',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                                    context,
                                    smallPhone: 20,
                                    mediumPhone: 22,
                                    largePhone: 24,
                                    tablet: 26,
                                  ),
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                ' / ',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                                    context,
                                    smallPhone: 18,
                                    mediumPhone: 20,
                                    largePhone: 22,
                                    tablet: 24,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black54,
                                  letterSpacing: 0.5,
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
                                    tablet: 26,
                                  ),
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          // Extra Moves Button (appears when 2 moves remaining)
                          if (_shouldShowExtraMovesButton()) ...[
                            SizedBox(width: ResponsiveUtils.getResponsiveSpacing(
                              context,
                              smallPhone: 8,
                              mediumPhone: 10,
                              largePhone: 12,
                              tablet: 14,
                            )),
                            Opacity(
                              opacity: _isLoadingExtraMoves ? 0.7 : 1.0,
                              child: GestureDetector(
                                onTap: _isLoadingExtraMoves ? () {} : _handleExtraMovesButton,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                    child: Container(
                                      padding: ResponsiveUtils.getResponsivePadding(
                                        context,
                                        smallPhone: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        mediumPhone: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        largePhone: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        tablet: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                      ),
                                      margin: EdgeInsets.zero,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(0xFF60A5FA), // Light blue
                                            const Color(0xFF3B82F6), // Base blue
                                            const Color(0xFF2563EB), // Dark blue
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.9),
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          // Outer glow with blue tint
                                          BoxShadow(
                                            color: const Color(0xFF3B82F6).withOpacity(0.5),
                                            blurRadius: 12,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 0),
                                          ),
                                          // Main shadow for depth
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.4),
                                            blurRadius: 10,
                                            spreadRadius: -1,
                                            offset: const Offset(0, 5),
                                          ),
                                          // Soft outer glow
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 15,
                                            spreadRadius: -2,
                                            offset: const Offset(0, 7),
                                          ),
                                        ],
                                      ),
                                      child: _isLoadingExtraMoves
                                          ? SizedBox(
                                              width: ResponsiveUtils.getResponsiveFontSize(
                                                context,
                                                smallPhone: 18,
                                                mediumPhone: 20,
                                                largePhone: 22,
                                                tablet: 24,
                                              ),
                                              height: ResponsiveUtils.getResponsiveFontSize(
                                                context,
                                                smallPhone: 18,
                                                mediumPhone: 20,
                                                largePhone: 22,
                                                tablet: 24,
                                              ),
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add_circle,
                                                      size: ResponsiveUtils.getResponsiveFontSize(
                                                        context,
                                                        smallPhone: 18,
                                                        mediumPhone: 20,
                                                        largePhone: 22,
                                                        tablet: 24,
                                                      ),
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                                                      context,
                                                      smallPhone: 2,
                                                      mediumPhone: 3,
                                                      largePhone: 4,
                                                      tablet: 5,
                                                    )),
                                                    Text(
                                                      'Watch Ad',
                                                      style: TextStyle(
                                                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                                                          context,
                                                          smallPhone: 8,
                                                          mediumPhone: 9,
                                                          largePhone: 10,
                                                          tablet: 11,
                                                        ),
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.white.withOpacity(0.9),
                                                        letterSpacing: 0.2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
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
  final bool isDailyPuzzle;
  final VoidCallback? onNextLevel;
  final VoidCallback onRestart;
  final VoidCallback? onBackToHome;

  const _GameOverDialog({
    required this.didWin,
    required this.level,
    required this.moves,
    required this.maxMoves,
    this.isDailyPuzzle = false,
    this.onNextLevel,
    required this.onRestart,
    this.onBackToHome,
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
                    // Special message for daily puzzle win
                    if (isDailyPuzzle && didWin) ...[
                      Text(
                        "SYNCED",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            smallPhone: 20,
                            mediumPhone: 22,
                            largePhone: 24,
                            tablet: 28,
                          ),
                          color: const Color(0xFF00D9FF), // Cyan
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                        context,
                        smallPhone: 8,
                        mediumPhone: 10,
                        largePhone: 12,
                        tablet: 14,
                      )),
                      Text(
                        "Today's Challenge Completed!",
                        textAlign: TextAlign.center,
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
                        "Amazing work! You solved it in $moves moves!",
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
                    ] else ...[
                      Text(
                        isDailyPuzzle
                            ? (didWin ? "Daily Puzzle Complete!" : "Daily Puzzle Failed")
                            : (didWin
                                ? AppConstants.levelCompleteText
                                : AppConstants.gameOverText),
                        textAlign: TextAlign.center,
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
                    ],
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
                        if (!isDailyPuzzle)
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
                    if (didWin && onNextLevel != null)
                      _PopupButton(
                        context: context,
                        onTap: onNextLevel!,
                        text: AppConstants.nextLevelText,
                        isPrimary: true,
                      )
                    else if (didWin && isDailyPuzzle && onBackToHome != null)
                      _PopupButton(
                        context: context,
                        onTap: onBackToHome!,
                        text: "Back to Home",
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
                      "You've completed all 30 levels!\nYou are a Color Flood master!",
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

/// Exit confirmation dialog widget
class _ExitConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ExitConfirmationDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.6),
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: min(400, MediaQuery.of(context).size.width * 0.85),
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
                    const Color(0xFF1F2937).withOpacity(0.95),
                    const Color(0xFF111827).withOpacity(0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.6),
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
                      'Exit Game?',
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
                      'You will lose your current progress in this game.',
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
                      smallPhone: 20,
                      mediumPhone: 24,
                      largePhone: 28,
                      tablet: 32,
                    )),
                    Row(
                      children: [
                        // Cancel button - full width
                        Expanded(
                          child: _PopupButton(
                            context: context,
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
                        // Exit button - full width
                        Expanded(
                          child: _PopupButton(
                            context: context,
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

/// Popup button widget
class _PopupButton extends StatelessWidget {
  final BuildContext context;
  final VoidCallback onTap;
  final String text;
  final bool isPrimary;
  final IconData? icon;

  const _PopupButton({
    required this.context,
    required this.onTap,
    required this.text,
    this.isPrimary = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: ResponsiveUtils.getResponsivePadding(
          context,
          smallPhone: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          mediumPhone: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          largePhone: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          tablet: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPrimary
                ? [
                    const Color(0xFF60A5FA), // Light blue
                    const Color(0xFF3B82F6), // Base blue
                    const Color(0xFF2563EB), // Dark blue
                  ]
                : [
                    const Color(0xFF4B5563), // Dark gray
                    const Color(0xFF374151), // Darker gray
                    const Color(0xFF1F2937), // Darkest gray
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.9),
            width: 2,
          ),
          boxShadow: [
            // Outer glow with color tint
            BoxShadow(
              color: (isPrimary ? const Color(0xFF3B82F6) : const Color(0xFF4B5563)).withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
            // Main shadow for depth
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: -1,
              offset: const Offset(0, 5),
            ),
            // Soft outer glow
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              spreadRadius: -2,
              offset: const Offset(0, 7),
            ),
          ],
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
                    smallPhone: 18,
                    mediumPhone: 19,
                    largePhone: 20,
                    tablet: 22,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  smallPhone: 6,
                  mediumPhone: 7,
                  largePhone: 8,
                  tablet: 10,
                )),
              ],
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    smallPhone: 16,
                    mediumPhone: 17,
                    largePhone: 18,
                    tablet: 20,
                  ),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

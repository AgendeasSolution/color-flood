import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../services/audio_service.dart';

/// How to Play popup dialog component
class HowToPlayDialog extends StatefulWidget {
  const HowToPlayDialog({super.key});

  static void show(BuildContext context) {
    // Force background music to play when dialog opens
    final audioService = AudioService();
    if (audioService.backgroundMusicEnabled) {
      // Use multiple attempts to ensure music plays
      audioService.ensureBackgroundMusicPlaying();
      // Also try force start as backup
      Future.delayed(const Duration(milliseconds: 100), () {
        if (audioService.backgroundMusicEnabled) {
          audioService.forceStartBackgroundMusic();
        }
      });
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const HowToPlayDialog(),
    ).then((_) {
      // Ensure music continues after dialog closes
      if (audioService.backgroundMusicEnabled) {
        Future.delayed(const Duration(milliseconds: 100), () {
          audioService.ensureBackgroundMusicPlaying();
        });
      }
    });
  }

  @override
  State<HowToPlayDialog> createState() => _HowToPlayDialogState();
}

class _HowToPlayDialogState extends State<HowToPlayDialog> {
  @override
  void initState() {
    super.initState();
    // Force background music to play when dialog is shown
    final audioService = AudioService();
    if (audioService.backgroundMusicEnabled) {
      // Multiple attempts to ensure music plays
      WidgetsBinding.instance.addPostFrameCallback((_) {
        audioService.ensureBackgroundMusicPlaying();
        // Backup attempt
        Future.delayed(const Duration(milliseconds: 200), () {
          if (audioService.backgroundMusicEnabled) {
            audioService.forceStartBackgroundMusic();
          }
        });
        // Another backup attempt
        Future.delayed(const Duration(milliseconds: 500), () {
          if (audioService.backgroundMusicEnabled) {
            audioService.ensureBackgroundMusicPlaying();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GameConstants.popupBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
              borderRadius: BorderRadius.circular(GameConstants.popupBorderRadius),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: GameConstants.mediumSpacing,
                    right: GameConstants.mediumSpacing,
                    top: GameConstants.smallSpacing,
                    bottom: GameConstants.mediumSpacing,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Goal Section with Close Button in top right
                      _buildGoalSectionWithClose(context),
                      
                      const SizedBox(height: GameConstants.largeSpacing),
                      
                      // How to Play Section
                      _buildHowToPlaySection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSectionWithClose(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Goal and Close button in same row (no container)
        Row(
          children: [
            // Spacer to push Goal to center
            Expanded(
              child: Container(),
            ),
            // Goal section (centered)
            Row(
              children: [
                const Text(
                  '🎯',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(width: GameConstants.smallSpacing),
                const Text(
                  'Goal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            // Spacer to balance the close button
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: GameConstants.smallSpacing),
        const Text(
          'Fill the entire board with the same color by strategically selecting colors from the palette. Complete each level within the move limit!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🎯',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(width: GameConstants.smallSpacing),
            const Text(
              'Goal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: GameConstants.smallSpacing),
        const Text(
          'Fill the entire board with the same color by strategically selecting colors from the palette. Complete each level within the move limit!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHowToPlaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎮',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(width: GameConstants.smallSpacing),
            const Text(
              'How to Play',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: GameConstants.mediumSpacing),
        _buildTutorialStep(1, 'Tap any color from the palette below'),
        const SizedBox(height: GameConstants.smallSpacing),
        _buildTutorialStep(2, 'The top-left area will flood with that color'),
        const SizedBox(height: GameConstants.smallSpacing),
        _buildTutorialStep(3, 'Connect adjacent cells of the same color'),
        const SizedBox(height: GameConstants.smallSpacing),
        _buildTutorialStep(4, 'Fill the entire board to win!'),
      ],
    );
  }

  Widget _buildTutorialStep(int stepNumber, String description) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    stepNumber.toString(),
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: GameConstants.mediumSpacing),
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

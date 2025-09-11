import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/game_constants.dart';

/// Tutorial card component showing how to play the game
class HowToPlayCard extends StatelessWidget {
  final VoidCallback onStartPlaying;

  const HowToPlayCard({
    super.key,
    required this.onStartPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Goal Section
        _buildGoalSection(),
        
        const SizedBox(height: GameConstants.largeSpacing),
        
        // How to Play Section
        _buildHowToPlaySection(),
        
        const SizedBox(height: GameConstants.largeSpacing),
        
        // Start Playing Button
        _buildStartPlayingButton(),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🎮',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(width: GameConstants.smallSpacing),
            const Text(
              'How to Play',
              style: TextStyle(
                fontSize: 22,
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
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    stepNumber.toString(),
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
                    fontSize: 18,
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

  Widget _buildStartPlayingButton() {
    return Center(
      child: ElevatedButton(
        onPressed: onStartPlaying,
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
                const Text(
                  'Start Playing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
}

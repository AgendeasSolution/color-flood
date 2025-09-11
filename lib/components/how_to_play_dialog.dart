import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/game_constants.dart';

/// How to Play popup dialog component
class HowToPlayDialog extends StatelessWidget {
  const HowToPlayDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const HowToPlayDialog(),
    );
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
                maxWidth: MediaQuery.of(context).size.width * 0.98,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    GameConstants.largeSpacing,
                    GameConstants.mediumSpacing,
                    GameConstants.largeSpacing,
                    GameConstants.largeSpacing,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Goal Section with Close Button
                      _buildGoalSectionWithClose(context),
                      
                      const SizedBox(height: GameConstants.largeSpacing),
                      
                      // How to Play Section
                      _buildHowToPlaySection(),
                      
                      const SizedBox(height: GameConstants.largeSpacing),
                      
                      // Close Button
                      _buildCloseButton(context),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildCloseButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.5),
        ),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: const Text(
              'Got it!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

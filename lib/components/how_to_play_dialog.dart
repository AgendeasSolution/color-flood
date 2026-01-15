import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../services/audio_service.dart';
import '../utils/responsive_utils.dart';

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
      backgroundColor: Colors.black.withOpacity(0.6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: ResponsiveUtils.getResponsivePadding(
                    context,
                    smallPhone: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    mediumPhone: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    largePhone: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Goal Section with Close Button in top right
                      _buildGoalSectionWithClose(context),
                      
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                        context,
                        smallPhone: 20,
                        mediumPhone: 22,
                        largePhone: 24,
                        tablet: 28,
                      )),
                      
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
                Text(
                  '🎯',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      smallPhone: 16,
                      mediumPhone: 17,
                      largePhone: 18,
                      tablet: 20,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  smallPhone: 6,
                  mediumPhone: 7,
                  largePhone: 8,
                  tablet: 10,
                )),
                Text(
                  'Goal',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      smallPhone: 18,
                      mediumPhone: 19,
                      largePhone: 20,
                      tablet: 22,
                    ),
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
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: ResponsiveUtils.getResponsiveIconSize(
                      context,
                      smallPhone: 20,
                      mediumPhone: 22,
                      largePhone: 24,
                      tablet: 26,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
          context,
          smallPhone: 6,
          mediumPhone: 7,
          largePhone: 8,
          tablet: 10,
        )),
        Text(
          'Fill the entire board with the same color by strategically selecting colors from the palette. Complete each level within the move limit!',
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
    );
  }

  Widget _buildHowToPlaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🎮',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  smallPhone: 16,
                  mediumPhone: 17,
                  largePhone: 18,
                  tablet: 20,
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.getResponsiveSpacing(
              context,
              smallPhone: 6,
              mediumPhone: 7,
              largePhone: 8,
              tablet: 10,
            )),
            Text(
              'How to Play',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  smallPhone: 18,
                  mediumPhone: 19,
                  largePhone: 20,
                  tablet: 22,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
          context,
          smallPhone: 12,
          mediumPhone: 14,
          largePhone: 16,
          tablet: 20,
        )),
        _buildTutorialStep(1, 'Tap any color from the palette below'),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
          context,
          smallPhone: 6,
          mediumPhone: 7,
          largePhone: 8,
          tablet: 10,
        )),
        _buildTutorialStep(2, 'The top-left area will flood with that color'),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
          context,
          smallPhone: 6,
          mediumPhone: 7,
          largePhone: 8,
          tablet: 10,
        )),
        _buildTutorialStep(3, 'Connect adjacent cells of the same color'),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
          context,
          smallPhone: 6,
          mediumPhone: 7,
          largePhone: 8,
          tablet: 10,
        )),
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
          padding: ResponsiveUtils.getResponsivePadding(
            context,
            smallPhone: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            mediumPhone: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            largePhone: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            tablet: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                width: ResponsiveUtils.getResponsiveValue(
                  context: context,
                  smallPhone: 20.0,
                  mediumPhone: 22.0,
                  largePhone: 24.0,
                  tablet: 28.0,
                ),
                height: ResponsiveUtils.getResponsiveValue(
                  context: context,
                  smallPhone: 20.0,
                  mediumPhone: 22.0,
                  largePhone: 24.0,
                  tablet: 28.0,
                ),
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
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        smallPhone: 10,
                        mediumPhone: 11,
                        largePhone: 12,
                        tablet: 14,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(
                context,
                smallPhone: 12,
                mediumPhone: 14,
                largePhone: 16,
                tablet: 20,
              )),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      smallPhone: 12,
                      mediumPhone: 13,
                      largePhone: 14,
                      tablet: 16,
                    ),
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

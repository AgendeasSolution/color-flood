import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';

/// Settings dialog component for managing audio settings
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

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
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => const SettingsDialog(),
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
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final AudioService _audioService = AudioService();
  late bool _soundEffectsEnabled;
  late bool _backgroundMusicEnabled;

  @override
  void initState() {
    super.initState();
    _soundEffectsEnabled = _audioService.soundEffectsEnabled;
    _backgroundMusicEnabled = _audioService.backgroundMusicEnabled;
    
    // Force background music to play when dialog is shown
    if (_audioService.backgroundMusicEnabled) {
      // Multiple attempts to ensure music plays
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _audioService.ensureBackgroundMusicPlaying();
        // Backup attempt
        Future.delayed(const Duration(milliseconds: 200), () {
          if (_audioService.backgroundMusicEnabled) {
            _audioService.forceStartBackgroundMusic();
          }
        });
        // Another backup attempt
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_audioService.backgroundMusicEnabled) {
            _audioService.ensureBackgroundMusicPlaying();
          }
        });
      });
    }
  }

  void _onSoundEffectsChanged(bool value) {
    setState(() {
      _soundEffectsEnabled = value;
    });
    _audioService.setSoundEffectsEnabled(value);
    // Play a test sound if enabling
    if (value) {
      _audioService.playClickSound();
    }
  }

  void _onBackgroundMusicChanged(bool value) {
    setState(() {
      _backgroundMusicEnabled = value;
    });
    _audioService.setBackgroundMusicEnabled(value);
    // If enabling, start the music (with a small delay to ensure state is updated)
    if (value) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _audioService.playBackgroundMusic();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            padding: ResponsiveUtils.getResponsivePadding(
              context,
              smallPhone: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              mediumPhone: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              largePhone: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surface.withOpacity(0.95),
                  AppColors.background.withOpacity(0.98),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.surfaceLight.withOpacity(0.6),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          smallPhone: 20,
                          mediumPhone: 22,
                          largePhone: 24,
                          tablet: 28,
                        ),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    IconButton(
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
                  ],
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  smallPhone: 12,
                  mediumPhone: 14,
                  largePhone: 16,
                  tablet: 20,
                )),
                
                // Sound Effects Toggle
                _buildSettingTile(
                  icon: Icons.volume_up,
                  title: 'Sound Effects',
                  subtitle: 'Button clicks, win sounds, and game effects',
                  value: _soundEffectsEnabled,
                  onChanged: _onSoundEffectsChanged,
                ),
                
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                  context,
                  smallPhone: 6,
                  mediumPhone: 7,
                  largePhone: 8,
                  tablet: 10,
                )),
                
                // Background Music Toggle
                _buildSettingTile(
                  icon: Icons.music_note,
                  title: 'Background Music',
                  subtitle: 'Ambient music on home screen',
                  value: _backgroundMusicEnabled,
                  onChanged: _onBackgroundMusicChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: ResponsiveUtils.getResponsivePadding(
            context,
            smallPhone: const EdgeInsets.all(12),
            mediumPhone: const EdgeInsets.all(14),
            largePhone: const EdgeInsets.all(16),
            tablet: const EdgeInsets.all(20),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surfaceLight.withOpacity(0.5),
                AppColors.surface.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: ResponsiveUtils.getResponsivePadding(
                  context,
                  smallPhone: const EdgeInsets.all(8),
                  mediumPhone: const EdgeInsets.all(9),
                  largePhone: const EdgeInsets.all(10),
                  tablet: const EdgeInsets.all(12),
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceLight.withOpacity(0.5)),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: ResponsiveUtils.getResponsiveIconSize(
                    context,
                    smallPhone: 20,
                    mediumPhone: 22,
                    largePhone: 24,
                    tablet: 26,
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
              
              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          smallPhone: 14,
                          mediumPhone: 15,
                          largePhone: 16,
                          tablet: 18,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(
                      context,
                      smallPhone: 3,
                      mediumPhone: 4,
                      largePhone: 4,
                      tablet: 5,
                    )),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          smallPhone: 11,
                          mediumPhone: 12,
                          largePhone: 13,
                          tablet: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Toggle Switch
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.surfaceLight,
                activeThumbColor: Colors.white,
                inactiveThumbColor: Colors.white.withOpacity(0.5),
                inactiveTrackColor: AppColors.surface.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }

}


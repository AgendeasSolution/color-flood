import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/game_constants.dart';
import '../services/audio_service.dart';

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
        borderRadius: BorderRadius.circular(GameConstants.popupBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            padding: EdgeInsets.only(
              left: GameConstants.mediumSpacing,
              right: GameConstants.mediumSpacing,
              top: GameConstants.smallSpacing,
              bottom: GameConstants.mediumSpacing,
            ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: GameConstants.mediumSpacing),
                
                // Sound Effects Toggle
                _buildSettingTile(
                  icon: Icons.volume_up,
                  title: 'Sound Effects',
                  subtitle: 'Button clicks, win sounds, and game effects',
                  value: _soundEffectsEnabled,
                  onChanged: _onSoundEffectsChanged,
                ),
                
                const SizedBox(height: GameConstants.smallSpacing),
                
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
          padding: const EdgeInsets.all(16),
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
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Toggle Switch
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF3B82F6),
                activeTrackColor: const Color(0xFF60A5FA),
                inactiveThumbColor: Colors.white.withOpacity(0.5),
                inactiveTrackColor: Colors.white.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

}


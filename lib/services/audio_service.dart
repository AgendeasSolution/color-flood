import 'package:audioplayers/audioplayers.dart';

/// Service class to handle all audio functionality
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  /// Get the singleton instance
  static AudioService get instance => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  bool _soundEffectsEnabled = true;
  bool _backgroundMusicEnabled = true;
  bool _isBgMusicPlaying = false;
  
  AudioService._internal() {
    // Configure players for parallel playback
    // Separate AudioPlayer instances automatically play in parallel
    // No additional configuration needed - each player is independent
  }

  /// Enable or disable all audio (for backward compatibility)
  void setEnabled(bool enabled) {
    _soundEffectsEnabled = enabled;
    _backgroundMusicEnabled = enabled;
    if (!enabled) {
      stopBackgroundMusic();
    }
  }

  /// Check if audio is enabled (for backward compatibility)
  bool get isEnabled => _soundEffectsEnabled || _backgroundMusicEnabled;

  /// Enable or disable sound effects (click sounds, win sounds, etc.)
  void setSoundEffectsEnabled(bool enabled) {
    _soundEffectsEnabled = enabled;
  }

  /// Check if sound effects are enabled
  bool get soundEffectsEnabled => _soundEffectsEnabled;

  /// Enable or disable background music
  void setBackgroundMusicEnabled(bool enabled) {
    _backgroundMusicEnabled = enabled;
    if (!enabled) {
      stopBackgroundMusic();
    }
  }

  /// Check if background music is enabled
  bool get backgroundMusicEnabled => _backgroundMusicEnabled;

  /// Play click sound for buttons
  Future<void> playClickSound() async {
    if (!_soundEffectsEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource('audio/mouse_click_3.mp3'));
    } catch (e) {
      // Silently handle audio errors to prevent crashes
    }
  }

  /// Play win sound when level is completed
  Future<void> playWinSound() async {
    if (!_soundEffectsEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource('audio/win_2.mp3'));
    } catch (e) {
      // Silently handle audio errors to prevent crashes
    }
  }

  /// Play fail sound when level is failed
  Future<void> playFailSound() async {
    if (!_soundEffectsEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource('audio/fail_1.mp3'));
    } catch (e) {
      // Silently handle audio errors to prevent crashes
    }
  }

  /// Play swipe sound for color palette clicks
  Future<void> playSwipeSound() async {
    if (!_soundEffectsEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource('audio/swipe_1.mp3'));
    } catch (e) {
      // Silently handle audio errors to prevent crashes
    }
  }

  /// Play mouse click sound (alias for playClickSound)
  Future<void> playMouseClickSound() async {
    await playClickSound();
  }

  /// Play background music at lower volume so it doesn't disturb other sounds
  Future<void> playBackgroundMusic() async {
    if (!_backgroundMusicEnabled) return;
    
    try {
      // Check current state first
      final currentState = _bgMusicPlayer.state;
      if (currentState == PlayerState.playing) {
        _isBgMusicPlaying = true;
        return; // Already playing
      }
      
      // Stop any existing playback to start fresh
      await _bgMusicPlayer.stop();
      
      // Set volume to 0.3 (30%) so it doesn't disturb other sounds
      await _bgMusicPlayer.setVolume(0.3);
      // Set release mode to loop for continuous playback
      await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
      // Play the background music
      await _bgMusicPlayer.play(AssetSource('audio/bg_music.mp3'));
      _isBgMusicPlaying = true;
    } catch (e) {
      // Silently handle audio errors to prevent crashes
      _isBgMusicPlaying = false;
    }
  }

  /// Stop background music
  Future<void> stopBackgroundMusic() async {
    try {
      await _bgMusicPlayer.stop();
      _isBgMusicPlaying = false;
    } catch (e) {
      // Silently handle audio errors to prevent crashes
      _isBgMusicPlaying = false;
    }
  }

  /// Pause background music
  Future<void> pauseBackgroundMusic() async {
    try {
      await _bgMusicPlayer.pause();
      // Keep _isBgMusicPlaying as true so we know to resume later
    } catch (e) {
      // Silently handle audio errors to prevent crashes
    }
  }

  /// Resume background music - ensures music plays regardless of current state
  Future<void> resumeBackgroundMusic() async {
    if (!_backgroundMusicEnabled) return;
    
    try {
      // Try to resume first
      await _bgMusicPlayer.resume();
      _isBgMusicPlaying = true;
    } catch (e) {
      // If resume fails (music was stopped or never started), start fresh
      try {
        // Reset the flag and start fresh
        _isBgMusicPlaying = false;
        await playBackgroundMusic();
      } catch (e2) {
        // Silently handle audio errors
        _isBgMusicPlaying = false;
      }
    }
  }

  /// Ensure background music is playing (will start if not playing, resume if paused)
  /// This is a robust method that forces music to play regardless of current state
  Future<void> ensureBackgroundMusicPlaying() async {
    if (!_backgroundMusicEnabled) return;
    
    try {
      // Get current state
      final state = _bgMusicPlayer.state;
      
      // If already playing, verify it's actually playing
      if (state == PlayerState.playing) {
        _isBgMusicPlaying = true;
        // Double-check by trying to get the state again after a small delay
        await Future.delayed(const Duration(milliseconds: 50));
        final verifyState = _bgMusicPlayer.state;
        if (verifyState == PlayerState.playing) {
          return; // Confirmed playing
        }
        // If state changed, fall through to restart
      }
      
      // If paused, try to resume
      if (state == PlayerState.paused) {
        try {
          await _bgMusicPlayer.resume();
          await Future.delayed(const Duration(milliseconds: 100));
          final verifyState = _bgMusicPlayer.state;
          if (verifyState == PlayerState.playing) {
            _isBgMusicPlaying = true;
            return; // Successfully resumed
          }
        } catch (e) {
          // Resume failed, will start fresh below
        }
      }
      
      // If stopped, not started, or resume failed - start fresh
      _isBgMusicPlaying = false;
      await playBackgroundMusic();
      
    } catch (e) {
      // If anything fails, try to start fresh
      try {
        _isBgMusicPlaying = false;
        await playBackgroundMusic();
      } catch (e2) {
        // Silently handle audio errors
        _isBgMusicPlaying = false;
      }
    }
  }

  /// Force start background music - always starts fresh (for dialogs)
  Future<void> forceStartBackgroundMusic() async {
    if (!_backgroundMusicEnabled) return;
    
    try {
      // Always start fresh - stop any existing playback first
      try {
        await _bgMusicPlayer.stop();
      } catch (e) {
        // Ignore stop errors
      }
      
      // Small delay to ensure stop completes
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Now start fresh
      await playBackgroundMusic();
    } catch (e) {
      // Silently handle audio errors
      _isBgMusicPlaying = false;
    }
  }

  /// Dispose the audio players
  void dispose() {
    _audioPlayer.dispose();
    _bgMusicPlayer.dispose();
  }
}

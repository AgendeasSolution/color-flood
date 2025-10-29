import 'package:audioplayers/audioplayers.dart';

/// Service class to handle all audio functionality
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isEnabled = true;

  /// Enable or disable audio
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if audio is enabled
  bool get isEnabled => _isEnabled;

  /// Play click sound for buttons
  Future<void> playClickSound() async {
    if (!_isEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource('audio/mouse_click_3.mp3'));
    } catch (e) {
      // Silently handle audio errors to prevent crashes
      print('Audio error: $e');
    }
  }

  /// Play win sound when level is completed
  Future<void> playWinSound() async {
    if (!_isEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource('audio/win_2.mp3'));
    } catch (e) {
      // Silently handle audio errors to prevent crashes
      print('Audio error: $e');
    }
  }

  /// Play fail sound when level is failed
  Future<void> playFailSound() async {
    if (!_isEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource('audio/fail_1.mp3'));
    } catch (e) {
      // Silently handle audio errors to prevent crashes
      print('Audio error: $e');
    }
  }

  /// Play swipe sound for color palette clicks
  Future<void> playSwipeSound() async {
    if (!_isEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource('audio/swipe_1.mp3'));
    } catch (e) {
      // Silently handle audio errors to prevent crashes
      print('Audio error: $e');
    }
  }

  /// Dispose the audio player
  void dispose() {
    _audioPlayer.dispose();
  }
}

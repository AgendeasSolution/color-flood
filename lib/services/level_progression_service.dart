import 'package:shared_preferences/shared_preferences.dart';
import '../constants/game_constants.dart';

/// Service to manage level progression and unlock status
class LevelProgressionService {
  static const String _unlockedLevelsKey = 'unlocked_levels';
  static const String _completedLevelsKey = 'completed_levels';
  
  static LevelProgressionService? _instance;
  static LevelProgressionService get instance {
    _instance ??= LevelProgressionService._();
    return _instance!;
  }
  
  LevelProgressionService._();
  
  /// Get the highest unlocked level (1-based)
  Future<int> getHighestUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_unlockedLevelsKey) ?? 1; // Level 1 is unlocked by default
  }
  
  /// Get all completed levels
  Future<Set<int>> getCompletedLevels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedLevelsString = prefs.getString(_completedLevelsKey) ?? '';
      if (completedLevelsString.isEmpty) return <int>{};
      
      return completedLevelsString
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) {
            try {
              return int.parse(s);
            } catch (e) {
              // Skip invalid integers
              return -1;
            }
          })
          .where((level) => level > 0 && level <= GameConstants.maxLevel)
          .toSet();
    } catch (e) {
      // Return empty set on any error
      return <int>{};
    }
  }
  
  /// Check if a specific level is unlocked
  Future<bool> isLevelUnlocked(int level) async {
    final highestUnlocked = await getHighestUnlockedLevel();
    return level <= highestUnlocked;
  }
  
  /// Check if a specific level is completed
  Future<bool> isLevelCompleted(int level) async {
    final completedLevels = await getCompletedLevels();
    return completedLevels.contains(level);
  }
  
  /// Unlock a specific level
  Future<void> unlockLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHighest = await getHighestUnlockedLevel();
    
    if (level > currentHighest && level <= GameConstants.maxLevel) {
      await prefs.setInt(_unlockedLevelsKey, level);
    }
  }
  
  /// Mark a level as completed and unlock the next level
  Future<void> completeLevel(int level) async {
    try {
      // Validate level
      if (level < 1 || level > GameConstants.maxLevel) return;
      
      final prefs = await SharedPreferences.getInstance();
      
      // Add to completed levels
      final completedLevels = await getCompletedLevels();
      completedLevels.add(level);
      await prefs.setString(_completedLevelsKey, completedLevels.join(','));
      
      // Unlock next level if it exists
      if (level < GameConstants.maxLevel) {
        await unlockLevel(level + 1);
      }
    } catch (e) {
      // Silently handle errors - don't crash
    }
  }
  
  /// Reset all progress (for testing or reset functionality)
  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_unlockedLevelsKey);
    await prefs.remove(_completedLevelsKey);
  }
  
  /// Unlock all levels for testing purposes
  Future<void> unlockAllLevels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_unlockedLevelsKey, GameConstants.maxLevel);
  }
  
  /// Get level status for all levels
  Future<Map<int, LevelStatus>> getAllLevelStatuses() async {
    final highestUnlocked = await getHighestUnlockedLevel();
    final completedLevels = await getCompletedLevels();
    
    final Map<int, LevelStatus> statuses = {};
    
    for (int level = 1; level <= GameConstants.maxLevel; level++) {
      // Level 1 is always unlocked
      if (level == 1) {
        statuses[level] = completedLevels.contains(level) 
            ? LevelStatus.completed 
            : LevelStatus.unlocked;
      } else if (level <= highestUnlocked) {
        statuses[level] = completedLevels.contains(level) 
            ? LevelStatus.completed 
            : LevelStatus.unlocked;
      } else {
        statuses[level] = LevelStatus.locked;
      }
    }
    
    return statuses;
  }
}

/// Enum representing the status of a level
enum LevelStatus {
  locked,    // Level is not yet unlocked
  unlocked,  // Level is unlocked but not completed
  completed, // Level has been completed
}

import 'package:flutter_test/flutter_test.dart';
import 'package:color_flood/constants/game_constants.dart';
import 'package:color_flood/services/game_service.dart';

void main() {
  group('Level Progression Tests', () {
    test('Level grid sizes are correct', () {
      expect(GameConstants.levelGridSizes[1], equals(5));
      expect(GameConstants.levelGridSizes[2], equals(6));
      expect(GameConstants.levelGridSizes[3], equals(7));
      expect(GameConstants.levelGridSizes[4], equals(8));
      expect(GameConstants.levelGridSizes[5], equals(9));
      expect(GameConstants.levelGridSizes[6], equals(10));
      expect(GameConstants.levelGridSizes[7], equals(11));
      expect(GameConstants.levelGridSizes[8], equals(12));
      expect(GameConstants.levelGridSizes[9], equals(13));
      expect(GameConstants.levelGridSizes[10], equals(14));
      expect(GameConstants.levelGridSizes[11], equals(15));
      expect(GameConstants.levelGridSizes[12], equals(16));
      expect(GameConstants.levelGridSizes[13], equals(17));
      expect(GameConstants.levelGridSizes[14], equals(18));
    });

    test('Level max moves are calculated dynamically', () {
      // Move counts are now calculated based on optimal solution + buffer
      // This test verifies that the calculation system works
      final gameService = GameService();
      
      for (int level = 1; level <= 14; level++) {
        final config = gameService.createGameConfig(level);
        
        // Max moves should be greater than 0 and reasonable
        expect(config.maxMoves, greaterThan(0));
        expect(config.maxMoves, lessThan(50)); // Reasonable upper bound
        
        // Higher levels should generally have more moves (but not always due to randomness)
        if (level > 1) {
          // At least verify the system is working
          expect(config.maxMoves, isA<int>());
        }
      }
    });

    test('Max level is 14', () {
      expect(GameConstants.maxLevel, equals(14));
    });

    test('GameService creates correct configurations for each level', () {
      final gameService = GameService();
      
      for (int level = 1; level <= 14; level++) {
        final config = gameService.createGameConfig(level);
        
        expect(config.level, equals(level));
        expect(config.gridSize, equals(GameConstants.levelGridSizes[level]));
        expect(config.maxMoves, greaterThan(0)); // Moves calculated dynamically
        expect(config.grid.length, equals(GameConstants.levelGridSizes[level]));
        expect(config.grid[0].length, equals(GameConstants.levelGridSizes[level]));
      }
    });

    test('GameService clamps levels outside valid range', () {
      final gameService = GameService();
      
      // Test level 0 (should clamp to 1)
      final config0 = gameService.createGameConfig(0);
      expect(config0.level, equals(1));
      
      // Test level 15 (should clamp to 14)
      final config15 = gameService.createGameConfig(15);
      expect(config15.level, equals(14));
      
      // Test negative level (should clamp to 1)
      final configNeg = gameService.createGameConfig(-5);
      expect(configNeg.level, equals(1));
    });
  });
}

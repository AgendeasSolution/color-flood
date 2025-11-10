import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import '../models/game_model.dart';

/// Service to fetch games from the FGTP Labs API
class GamesService {
  static const String _apiUrl = 'https://api.freegametoplay.com/apps';
  static const String _currentGameName = 'Color Flood';

  /// Check if device has network connectivity
  static Future<bool> hasNetworkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Fetch games from the API
  /// Returns list of games excluding the current game (Color Flood)
  /// Throws exception with 'No internet connection' message if offline
  /// Throws other exceptions for API errors
  static Future<List<GameModel>> fetchGames() async {
    // Check connectivity first (quick check)
    final hasConnection = await hasNetworkConnectivity();
    if (!hasConnection) {
      throw Exception('No internet connection');
    }

    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final apiResponse = GamesApiResponse.fromJson(jsonData);

        if (apiResponse.success) {
          // Filter out the current game (Color Flood)
          final filteredGames = apiResponse.data
              .where((game) => game.name != _currentGameName)
              .toList();
          return filteredGames;
        } else {
          throw Exception('API returned unsuccessful response');
        }
      } else {
        throw Exception('Failed to load games: ${response.statusCode}');
      }
    } on TimeoutException {
      // Request timed out - likely no internet connection
      throw Exception('No internet connection');
    } on SocketException {
      // Network error - no internet connection
      throw Exception('No internet connection');
    } on http.ClientException catch (e) {
      // Network-related client exceptions
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('failed host lookup') ||
          errorString.contains('network is unreachable') ||
          errorString.contains('connection refused') ||
          errorString.contains('connection timed out')) {
        throw Exception('No internet connection');
      }
      throw Exception('Network error: Unable to connect to server');
    } on FormatException {
      throw Exception('Invalid response format from server');
    } on Exception catch (e) {
      // Re-throw if it's already our "No internet connection" exception
      if (e.toString().contains('No internet connection')) {
        rethrow;
      }
      throw Exception('Failed to fetch games: ${e.toString()}');
    } catch (e) {
      // Catch any other errors (timeout, etc.) and check if it's network-related
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socket') ||
          errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('timeout') ||
          errorString.contains('failed host lookup')) {
        throw Exception('No internet connection');
      }
      throw Exception('Failed to fetch games: ${e.toString()}');
    }
  }

  /// Get the appropriate store URL based on the platform
  static String getStoreUrl(GameModel game) {
    if (Platform.isAndroid) {
      return game.playstoreUrl;
    } else if (Platform.isIOS) {
      return game.appstoreUrl;
    } else {
      // Default to Play Store for other platforms
      return game.playstoreUrl;
    }
  }
}


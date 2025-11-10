import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fgtp_app_model.dart';

/// Exception thrown when there's no internet connection
class NoInternetException implements Exception {
  final String message;
  NoInternetException([this.message = 'No internet connection']);
  
  @override
  String toString() => message;
}

/// Service to fetch games from the FGTP Labs API with caching
class FgtpGamesService {
  static const String _apiUrl = 'https://api.freegametoplay.com/apps';
  static const String _currentGameName = 'Color Flood';
  static const String _cacheKey = 'fgtp_games_cache';
  static const String _cacheTimestampKey = 'fgtp_games_cache_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 24);

  /// Check if device has network connectivity
  Future<bool> hasNetworkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      // connectivity_plus v7.0.0 returns List<ConnectivityResult>
      // Check if we have any active connection (not "none")
      return connectivityResult.isNotEmpty &&
          connectivityResult.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  /// Get cached games from local storage
  Future<List<FgtpApp>?> getCachedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (cacheJson != null && timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        
        // Check if cache is still valid
        if (now.difference(cacheTime) < _cacheExpiry) {
          final List<dynamic> jsonList = json.decode(cacheJson);
          return jsonList.map((json) => FgtpApp.fromJson(json)).toList();
        }
      }
    } catch (e) {
      // If cache read fails, return null
    }
    return null;
  }

  /// Save games to local cache
  Future<void> saveGamesToCache(List<FgtpApp> games) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = games.map((game) => game.toJson()).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // If cache write fails, silently continue
    }
  }

  /// Fetch games from the API
  /// Returns list of games excluding the current game (Color Flood)
  /// Throws NoInternetException if offline
  /// Returns cached games if available and forceRefresh is false
  Future<List<FgtpApp>> fetchMobileGames({bool forceRefresh = false}) async {
    // Check connectivity first
    final hasConnection = await hasNetworkConnectivity();
    
    if (!forceRefresh) {
      // Try to return cached games if available
      final cachedGames = await getCachedGames();
      if (cachedGames != null && cachedGames.isNotEmpty) {
        if (!hasConnection) {
          // No internet and we have cache, return cached games
          return cachedGames;
        }
        // We have internet, but return cache immediately and fetch in background
        // For now, we'll fetch fresh data if online
      }
    }

    if (!hasConnection) {
      // No internet and no cache (or force refresh), throw exception
      final cachedGames = await getCachedGames();
      if (cachedGames != null && cachedGames.isNotEmpty) {
        // Return cached games even on force refresh if offline
        return cachedGames;
      }
      throw NoInternetException();
    }

    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final bool success = jsonData['success'] as bool? ?? false;
        
        if (success) {
          final List<dynamic> data = jsonData['data'] as List<dynamic>;
          final games = data
              .map((item) => FgtpApp.fromJson(item as Map<String, dynamic>))
              .where((app) => app.name != _currentGameName)
              .toList();
          
          // Save to cache
          await saveGamesToCache(games);
          
          return games;
        } else {
          throw Exception('API returned unsuccessful response');
        }
      } else {
        throw Exception('Failed to load games: ${response.statusCode}');
      }
    } on TimeoutException {
      throw NoInternetException();
    } on SocketException {
      throw NoInternetException();
    } on http.ClientException catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('failed host lookup') ||
          errorString.contains('network is unreachable') ||
          errorString.contains('connection refused') ||
          errorString.contains('connection timed out')) {
        throw NoInternetException();
      }
      throw Exception('Network error: Unable to connect to server');
    } on FormatException {
      throw Exception('Invalid response format from server');
    } catch (e) {
      if (e is NoInternetException) {
        rethrow;
      }
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socket') ||
          errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('timeout') ||
          errorString.contains('failed host lookup')) {
        throw NoInternetException();
      }
      throw Exception('Failed to fetch games: ${e.toString()}');
    }
  }
}


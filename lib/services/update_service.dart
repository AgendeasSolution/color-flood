import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to check for app updates from App Store and Play Store
class UpdateService {
  static UpdateService? _instance;
  static UpdateService get instance => _instance ??= UpdateService._();
  
  UpdateService._();
  
  // Store URLs
  static const String _iosAppStoreUrl = 'https://apps.apple.com/us/app/color-flood-splash-puzzle/id6754686796';
  static const String _androidPlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.fgtp.color_flood';
  
  // Cache keys
  static const String _lastUpdateCheckKey = 'last_update_check_timestamp';
  static const String _hasUpdateAvailableKey = 'has_update_available';
  static const String _lastKnownStoreVersionKey = 'last_known_store_version';
  static const String _lastPopupShownKey = 'last_popup_shown_timestamp';
  
  // Cache duration - check once per day
  static const Duration _cacheDuration = Duration(hours: 24);
  
  // Popup show duration - show once per day
  static const Duration _popupShowDuration = Duration(hours: 24);
  
  /// Check if an update is available
  /// Returns true if update is available, false otherwise
  Future<bool> checkForUpdate({bool forceCheck = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // Check cache first (unless force check)
      if (!forceCheck) {
        final lastCheckTimestamp = prefs.getInt(_lastUpdateCheckKey);
        final hasUpdate = prefs.getBool(_hasUpdateAvailableKey);
        
        if (lastCheckTimestamp != null) {
          final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheckTimestamp);
          final now = DateTime.now();
          
          // If cache is still valid, return cached result
          if (now.difference(lastCheckTime) < _cacheDuration) {
            return hasUpdate ?? false;
          }
        }
      }
      
      // Perform actual check
      String? storeVersion;
      if (Platform.isIOS) {
        storeVersion = await _getIOSStoreVersion();
      } else if (Platform.isAndroid) {
        storeVersion = await _getAndroidStoreVersion();
      } else {
        // For other platforms, assume no update
        return false;
      }
      
      if (storeVersion == null) {
        // If we couldn't fetch version, return cached result if available
        final hasUpdate = prefs.getBool(_hasUpdateAvailableKey);
        return hasUpdate ?? false;
      }
      
      // Compare versions
      final updateAvailable = _isVersionNewer(storeVersion, currentVersion);
      
      // Cache the result
      await prefs.setInt(_lastUpdateCheckKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool(_hasUpdateAvailableKey, updateAvailable);
      await prefs.setString(_lastKnownStoreVersionKey, storeVersion);
      
      return updateAvailable;
    } catch (e) {
      // On error, return cached result if available
      try {
        final prefs = await SharedPreferences.getInstance();
        final hasUpdate = prefs.getBool(_hasUpdateAvailableKey);
        return hasUpdate ?? false;
      } catch (_) {
        return false;
      }
    }
  }
  
  /// Get iOS App Store version by parsing the store page
  Future<String?> _getIOSStoreVersion() async {
    try {
      final response = await http.get(Uri.parse(_iosAppStoreUrl)).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final html = response.body;
        
        // Try to find version in the HTML
        // Look for patterns like "Version 1.1.2" or similar
        final versionPattern = RegExp(r'Version\s+(\d+\.\d+\.\d+)', caseSensitive: false);
        final match = versionPattern.firstMatch(html);
        
        if (match != null && match.groupCount >= 1) {
          return match.group(1);
        }
        
        // Alternative pattern for version history
        final versionHistoryPattern = RegExp(r'####\s+(\d+\.\d+\.\d+)', caseSensitive: false);
        final historyMatch = versionHistoryPattern.firstMatch(html);
        
        if (historyMatch != null && historyMatch.groupCount >= 1) {
          return historyMatch.group(1);
        }
      }
    } catch (e) {
      // Silently handle errors
    }
    return null;
  }
  
  /// Get Android Play Store version by parsing the store page
  Future<String?> _getAndroidStoreVersion() async {
    try {
      final response = await http.get(Uri.parse(_androidPlayStoreUrl)).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final html = response.body;
        
        // Try to find version in the HTML
        // Play Store often has version in metadata
        final versionPatterns = [
          RegExp(r'"version"\s*:\s*"(\d+\.\d+\.\d+)"', caseSensitive: false),
          RegExp(r'Version\s+(\d+\.\d+\.\d+)', caseSensitive: false),
          RegExp(r'Current Version.*?(\d+\.\d+\.\d+)', caseSensitive: false),
        ];
        
        for (final pattern in versionPatterns) {
          final match = pattern.firstMatch(html);
          if (match != null && match.groupCount >= 1) {
            return match.group(1);
          }
        }
      }
    } catch (e) {
      // Silently handle errors
    }
    return null;
  }
  
  /// Compare two version strings
  /// Returns true if newVersion is newer than currentVersion
  bool _isVersionNewer(String newVersion, String currentVersion) {
    try {
      final newParts = newVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      
      // Ensure both have same length (pad with zeros if needed)
      while (newParts.length < currentParts.length) {
        newParts.add(0);
      }
      while (currentParts.length < newParts.length) {
        currentParts.add(0);
      }
      
      for (int i = 0; i < newParts.length; i++) {
        if (newParts[i] > currentParts[i]) {
          return true;
        } else if (newParts[i] < currentParts[i]) {
          return false;
        }
      }
      
      // Versions are equal
      return false;
    } catch (e) {
      // If parsing fails, assume no update
      return false;
    }
  }
  
  /// Get the store URL for the current platform
  String getStoreUrl() {
    if (Platform.isIOS) {
      return _iosAppStoreUrl;
    } else if (Platform.isAndroid) {
      return _androidPlayStoreUrl;
    }
    return '';
  }
  
  /// Check if popup should be shown (only once per day)
  /// Returns true if popup should be shown, false otherwise
  Future<bool> shouldShowPopup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // First check if there's an update available
      final hasUpdate = await checkForUpdate();
      if (!hasUpdate) {
        return false;
      }
      
      // Check when popup was last shown
      final lastShownTimestamp = prefs.getInt(_lastPopupShownKey);
      if (lastShownTimestamp == null) {
        // Never shown before, so show it
        return true;
      }
      
      final lastShownTime = DateTime.fromMillisecondsSinceEpoch(lastShownTimestamp);
      final now = DateTime.now();
      
      // Check if 24 hours have passed since last shown
      final timeSinceLastShown = now.difference(lastShownTime);
      if (timeSinceLastShown >= _popupShowDuration) {
        // 24 hours have passed, show again
        return true;
      }
      
      // Less than 24 hours since last shown, don't show
      return false;
    } catch (e) {
      // On error, don't show popup
      return false;
    }
  }
  
  /// Mark popup as shown (record current timestamp)
  Future<void> markPopupShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastPopupShownKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silently handle errors
    }
  }
  
  /// Mark update pop-up as dismissed (but allow showing again tomorrow if update still available)
  Future<void> dismissUpdate() async {
    // Don't change hasUpdateAvailableKey - we want to keep checking
    // Just mark that popup was shown for today
    await markPopupShown();
  }
  
  /// Get last known store version
  Future<String?> getLastKnownStoreVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastKnownStoreVersionKey);
  }
}


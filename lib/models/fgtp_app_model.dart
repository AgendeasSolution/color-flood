import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Model representing an FGTP Labs app/game
class FgtpApp {
  final String name;
  final String imageUrl;
  final String playstoreUrl;
  final String appstoreUrl;

  const FgtpApp({
    required this.name,
    required this.imageUrl,
    required this.playstoreUrl,
    required this.appstoreUrl,
  });

  /// Create an FgtpApp from JSON
  factory FgtpApp.fromJson(Map<String, dynamic> json) {
    return FgtpApp(
      name: json['name'] as String,
      imageUrl: json['image'] as String,
      playstoreUrl: json['playstore_url'] as String,
      appstoreUrl: json['appstore_url'] as String,
    );
  }

  /// Convert FgtpApp to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image': imageUrl,
      'playstore_url': playstoreUrl,
      'appstore_url': appstoreUrl,
    };
  }

  /// Get all available store URLs
  List<String> get availableStoreUrls => [playstoreUrl, appstoreUrl];

  /// Get the primary store URL for the given platform
  String? primaryStoreUrl(TargetPlatform platform) {
    if (platform == TargetPlatform.android) {
      return playstoreUrl;
    } else if (platform == TargetPlatform.iOS) {
      return appstoreUrl;
    }
    // For other platforms, default to Play Store
    return playstoreUrl;
  }
}


/// Model representing a game from the FGTP Labs API
class GameModel {
  final String name;
  final String image;
  final String playstoreUrl;
  final String appstoreUrl;

  GameModel({
    required this.name,
    required this.image,
    required this.playstoreUrl,
    required this.appstoreUrl,
  });

  /// Create a GameModel from JSON
  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      name: json['name'] as String,
      image: json['image'] as String,
      playstoreUrl: json['playstore_url'] as String,
      appstoreUrl: json['appstore_url'] as String,
    );
  }

  /// Convert GameModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image': image,
      'playstore_url': playstoreUrl,
      'appstore_url': appstoreUrl,
    };
  }
}

/// Response model for the games API
class GamesApiResponse {
  final bool success;
  final int count;
  final List<GameModel> data;

  GamesApiResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  /// Create a GamesApiResponse from JSON
  factory GamesApiResponse.fromJson(Map<String, dynamic> json) {
    return GamesApiResponse(
      success: json['success'] as bool,
      count: json['count'] as int,
      data: (json['data'] as List<dynamic>)
          .map((item) => GameModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}


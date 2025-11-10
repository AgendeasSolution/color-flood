import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/common/animated_background.dart';
import '../components/common/banner_ad_widget.dart';
import '../constants/app_constants.dart';
import '../models/fgtp_app_model.dart';
import '../services/audio_service.dart';
import '../services/fgtp_games_service.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';

/// Screen to showcase other FGTP Labs games.
class OtherGamesScreen extends StatefulWidget {
  const OtherGamesScreen({super.key});

  @override
  State<OtherGamesScreen> createState() => _OtherGamesScreenState();
}

class _OtherGamesScreenState extends State<OtherGamesScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AudioService _audioService;
  late final FgtpGamesService _gamesService;

  List<FgtpApp> _games = const [];
  List<FgtpApp>? _cachedGames;
  bool _isLoading = true;
  bool _isOffline = false;
  bool _showingCachedData = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration:
          Duration(seconds: AppConstants.backgroundAnimationDuration),
    )..repeat();
    _audioService = AudioService.instance;
    _gamesService = FgtpGamesService();
    _loadGames();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _loadGames({bool forceRefresh = false}) async {
    setState(() {
      if (!_isLoading) {
        _isLoading = true;
      }
      _errorMessage = null;
      _isOffline = false;
      if (forceRefresh) {
        _showingCachedData = false;
      }
    });

    try {
      final games = await _gamesService.fetchMobileGames(
        forceRefresh: forceRefresh,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _games = games;
        _cachedGames = games;
        _isLoading = false;
        _showingCachedData = false;
        _isOffline = false;
        _errorMessage = null;
      });
    } on NoInternetException {
      if (!mounted) {
        return;
      }
      if ((_cachedGames ?? const []).isNotEmpty) {
        setState(() {
          _games = _cachedGames!;
          _isLoading = false;
          _isOffline = true;
          _showingCachedData = true;
          _errorMessage =
              'No internet connection. Showing the last available games.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _isOffline = true;
          _showingCachedData = false;
          _errorMessage = 'No internet connection. Please try again.';
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      if ((_cachedGames ?? const []).isNotEmpty) {
        setState(() {
          _games = _cachedGames!;
          _isLoading = false;
          _showingCachedData = true;
          _errorMessage =
              'We had trouble loading new games. Showing cached data.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _showingCachedData = false;
          _errorMessage = 'Unable to load games right now. Please retry.';
        });
      }
    }
  }

  Future<void> _openStore(FgtpApp app) async {
    _audioService.playMouseClickSound();

    try {
      // Use Platform directly for more reliable platform detection
      final String? storeUrl;
      if (Platform.isIOS) {
        storeUrl = app.appstoreUrl;
      } else if (Platform.isAndroid) {
        storeUrl = app.playstoreUrl;
      } else {
        // Fallback to Play Store for other platforms
        storeUrl = app.playstoreUrl;
      }

      if (storeUrl == null || storeUrl.isEmpty) {
        throw Exception('Store URL is not available');
      }

      final uri = Uri.parse(storeUrl);

      // For iOS, App Store URLs (https://apps.apple.com) should work directly
      // For Android, Play Store URLs (https://play.google.com) should work directly
      // Try to launch the URL - on iOS/Android, HTTPS store URLs will open in the store app
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // If external launch failed, try with platform default
        await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open store. ${Platform.isIOS ? 'Please check your App Store connection.' : 'Please check your Play Store connection.'}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          AnimatedBackground(controller: _bgController),
          SafeArea(
            child: Column(  
              children: [
                _buildHeader(context),
                if (_showingCachedData) _buildCachedBanner(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BannerAdWidget(
              onAdLoaded: null,
              onAdFailedToLoad: null,
              onAdClicked: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final buttonSize = ResponsiveUtils.getResponsiveSpacing(context, baseValue: 44);
    final titleStyle = ResponsiveUtils.getResponsiveTextStyle(
      context,
      baseFontSize: 22,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
      letterSpacing: 1.1,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: ElevatedButton(
              onPressed: () {
                AudioService.instance.playMouseClickSound();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface.withOpacity(0.7),
                foregroundColor: AppColors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: AppColors.black.withOpacity(0.3),
              ),
              child: const Icon(Icons.chevron_left, size: 26),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'FGTP Labs',
              style: titleStyle,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: buttonSize),
        ],
      ),
    );
  }

  Widget _buildCachedBanner() {
    final bannerColor = _isOffline
        ? AppColors.accent.withOpacity(0.2)
        : AppColors.secondary.withOpacity(0.2);
    final borderColor = _isOffline
        ? AppColors.accent.withOpacity(0.4)
        : AppColors.secondary.withOpacity(0.4);
    final textColor = _isOffline ? AppColors.accent : AppColors.secondary;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            _isOffline ? Icons.wifi_off : Icons.cloud_download,
            size: 18,
            color: textColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage ?? 'Showing cached data',
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!_isLoading)
            TextButton(
              onPressed: () => _loadGames(forceRefresh: true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.secondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null && !_showingCachedData) {
      return _buildErrorState();
    }

    if (_games.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => _loadGames(forceRefresh: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final crossAxisCount = _getCrossAxisCount(maxWidth);
          final horizontalSpacing = ResponsiveUtils.getResponsiveSpacing(
            context,
            baseValue: 16,
          );
          final verticalSpacing = ResponsiveUtils.getResponsiveSpacing(
            context,
            baseValue: 14,
          );

          final totalHorizontalSpacing =
              horizontalSpacing * (crossAxisCount - 1);
          final cardWidth = (maxWidth - totalHorizontalSpacing) / crossAxisCount;
          final aspectRatio = _calculateCardAspectRatio(context, cardWidth);

          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: 0,
              right: 0,
              bottom: ResponsiveUtils.getResponsiveSpacing(context, baseValue: 120),
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: horizontalSpacing,
              mainAxisSpacing: verticalSpacing,
              childAspectRatio: aspectRatio,
            ),
            itemCount: _games.length,
            itemBuilder: (context, index) {
              final app = _games[index];
              return _GameCard(
                app: app,
                onTap: () => _openStore(app),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Icon(
              _isOffline ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: _isOffline ? AppColors.accent : AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong.',
              style: ResponsiveUtils.getResponsiveTextStyle(
                context,
                baseFontSize: 16,
                color: AppColors.textSecondary,
              ),
                textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadGames(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'More games coming soon!',
        style: ResponsiveUtils.getResponsiveTextStyle(
          context,
          baseFontSize: 18,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  int _getCrossAxisCount(double maxWidth) {
    if (maxWidth > 1000) {
      return 4;
    }
    if (maxWidth > 720) {
      return 3;
    }
    return 2;
  }

  double _calculateCardAspectRatio(BuildContext context, double cardWidth) {
    final cardPadding = ResponsiveUtils.getResponsiveSpacing(context, baseValue: 6);
    final spacing = ResponsiveUtils.getResponsiveSpacing(context, baseValue: 2);
    final buttonHeight = ResponsiveUtils.getResponsiveSpacing(context, baseValue: 36);

    final textStyle = ResponsiveUtils.getResponsiveTextStyle(
      context,
      baseFontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
    final fontSize = textStyle.fontSize ?? 16;
    final lineHeight = (textStyle.height ?? 1) * fontSize;
    final textHeight = lineHeight * 2;

    final totalHeight = ((cardPadding * 2) +
            cardWidth +
            (spacing * 2) +
            buttonHeight +
            textHeight -
            ResponsiveUtils.getResponsiveSpacing(context, baseValue: 12))
        .clamp(1, double.infinity);
    return cardWidth / totalHeight;
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.app, required this.onTap});

  final FgtpApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardRadius = BorderRadius.circular(
      ResponsiveUtils.getResponsiveBorderRadius(context, 18),
    );
    final cardPadding = ResponsiveUtils.getResponsiveSpacing(context, baseValue: 10);
    final spacing = ResponsiveUtils.getResponsiveSpacing(context, baseValue: 6);
    final buttonHeight = ResponsiveUtils.getResponsiveSpacing(context, baseValue: 36);

    return ClipRRect(
      borderRadius: cardRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: cardRadius,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getResponsiveBorderRadius(
                        context,
                        14,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: app.imageUrl.isNotEmpty
                          ? Image.network(
                              app.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _PlaceholderArtwork(name: app.name),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                );
                              },
                            )
                          : _PlaceholderArtwork(name: app.name),
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                Text(
                  app.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ResponsiveUtils.getResponsiveTextStyle(
                    context,
                    baseFontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: spacing),
                SizedBox(
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.transparent,
                      shadowColor: AppColors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveBorderRadius(context, 10),
                        ),
                      ),
                    ).copyWith(
                      elevation: ButtonStyleButton.allOrNull(0.0),
                      overlayColor: MaterialStateProperty.resolveWith(
                        (states) => states.contains(MaterialState.pressed)
                            ? AppColors.white.withOpacity(0.12)
                            : null,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700), // Vibrant yellow-gold
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveBorderRadius(context, 10),
                        ),
                        boxShadow: [
                          // Subtle shadow for depth
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            spreadRadius: 0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            ResponsiveUtils.getResponsiveSpacing(context, baseValue: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow, size: 20, color: Colors.black),
                          SizedBox(
                            width: ResponsiveUtils.getResponsiveSpacing(context, baseValue: 6),
                          ),
                          Text(
                            'Play Now',
                            style: ResponsiveUtils.getResponsiveTextStyle(
                              context,
                              baseFontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderArtwork extends StatelessWidget {
  const _PlaceholderArtwork({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ResponsiveUtils.getResponsiveTextStyle(
            context,
            baseFontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.white.withOpacity(0.9),
          ),
        ),
      ),
    );
  }
}

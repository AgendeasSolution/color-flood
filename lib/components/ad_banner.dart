import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A reusable ad banner component that displays Google AdMob banner ads
class AdBanner extends StatefulWidget {
  final double? height;
  final String? adUnitId;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailedToLoad;

  const AdBanner({
    super.key,
    this.height,
    this.adUnitId,
    this.onAdLoaded,
    this.onAdFailedToLoad,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;
  bool _hasAdError = false;

  // Test ad unit ID for development (works on both platforms)
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  
  // Production ad unit IDs for each platform
  static const String _productionAdUnitIdAndroid = 'ca-app-pub-3772142815301617/4936791314';
  static const String _productionAdUnitIdIOS = 'ca-app-pub-3772142815301617/3268810139';
  
  /// Get the production ad unit ID based on the current platform
  static String get _productionAdUnitId {
    if (Platform.isAndroid) {
      return _productionAdUnitIdAndroid;
    } else if (Platform.isIOS) {
      return _productionAdUnitIdIOS;
    } else {
      // Fallback to Android for other platforms
      return _productionAdUnitIdAndroid;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAndLoadAd();
  }

  void _initializeAndLoadAd() async {
    try {
      // Initialize MobileAds if not already initialized
      await MobileAds.instance.initialize();
      _loadBannerAd();
    } catch (e) {
      // If plugin is not available, show placeholder
      if (mounted) {
        setState(() {
          _isAdLoading = false;
          _hasAdError = false;
          _isAdLoaded = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    if (_isAdLoading || _isAdLoaded || !mounted) return;

    setState(() {
      _isAdLoading = true;
      _hasAdError = false;
    });

    try {
      _bannerAd = BannerAd(
        adUnitId: widget.adUnitId ?? _productionAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isAdLoaded = true;
                _isAdLoading = false;
                _hasAdError = false;
              });
              widget.onAdLoaded?.call();
            }
          },
          onAdFailedToLoad: (ad, error) {
            if (mounted) {
              setState(() {
                _isAdLoaded = false;
                _isAdLoading = false;
                _hasAdError = true;
              });
              ad.dispose();
              widget.onAdFailedToLoad?.call();
            }
          },
        ),
      );

      _bannerAd!.load();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdLoaded = false;
          _isAdLoading = false;
          _hasAdError = true;
        });
        widget.onAdFailedToLoad?.call();
      }
    }
  }

  void _retryLoadAd() {
    if (_bannerAd != null) {
      _bannerAd!.dispose();
      _bannerAd = null;
    }
    _loadBannerAd();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height ?? 50.0,
      child: _buildAdContent(),
    );
  }

  Widget _buildAdContent() {
    if (_isAdLoading) {
      return const SizedBox.shrink(); // Hide loading indicator completely
    }

    if (_isAdLoaded && _bannerAd != null) {
      return SizedBox(
        width: double.infinity,
        height: widget.height ?? 50.0,
        child: AdWidget(ad: _bannerAd!),
      );
    }

    if (_hasAdError) {
      return const SizedBox.shrink(); // Hide error state completely
    }

    // Show placeholder when plugin is not available or ad is not loaded
    return const SizedBox.shrink(); // Hide placeholder completely
  }
}


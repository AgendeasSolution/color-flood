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

  // Test ad unit ID for development
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  
  // Production ad unit ID (use this when ready for production)
  static const String _productionAdUnitId = 'ca-app-pub-3772142815301617/4936791314';

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
      print('Failed to initialize Google Mobile Ads: $e');
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
        adUnitId: widget.adUnitId ?? _productionAdUnitId ,
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
              print('Banner ad failed to load: $error');
              print('Error code: ${error.code}, Message: ${error.message}');
              
              // Handle different error types
              if (error.code == 3) {
                print('No fill error - no ads available for this ad unit');
              } else if (error.code == 0) {
                print('Internal error - check ad unit ID and configuration');
              } else if (error.code == 1) {
                print('Invalid request - check ad unit ID format');
              }
              
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
      print('Error creating banner ad: $e');
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


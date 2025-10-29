import 'dart:math';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service to manage interstitial ads
class InterstitialAdService {
  static InterstitialAdService? _instance;
  static InterstitialAdService get instance => _instance ??= InterstitialAdService._();
  
  InterstitialAdService._();

  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  bool _isLoading = false;

  /// Test ad unit ID for development
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  
  /// Production ad unit ID (use this when ready for production)
  static const String _productionAdUnitId = 'ca-app-pub-3772142815301617/7195288993';

  /// Current ad unit ID (using test for development)
  /// Change to _productionAdUnitId when ready for production
  static const String _adUnitId = _productionAdUnitId;

  /// Check if ad is ready to show
  bool get isAdReady => _isAdReady;

  /// Load interstitial ad
  Future<void> loadAd() async {
    if (_isLoading || _isAdReady) return;

    _isLoading = true;

    try {
      await InterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isAdReady = true;
            _isLoading = false;
            
            // Set up ad callbacks
            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {},
              onAdDismissedFullScreenContent: (ad) {
                _disposeAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _disposeAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            _isAdReady = false;
          },
        ),
      );
    } catch (e) {
      _isLoading = false;
      _isAdReady = false;
    }
  }

  /// Show interstitial ad if ready
  Future<bool> showAd() async {
    if (!_isAdReady || _interstitialAd == null) {
      await loadAd();
      return false;
    }

    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      _disposeAd();
      return false;
    }
  }

  /// Show interstitial ad with 50% probability
  /// Returns true if ad was shown, false if not shown (due to probability or other reasons)
  Future<bool> showAdWithProbability() async {
    return await showAdWithCustomProbability(0.5); // 50% probability
  }

  /// Show interstitial ad with custom probability (0.0 to 1.0)
  /// Returns true if ad was shown, false if not shown (due to probability or other reasons)
  Future<bool> showAdWithCustomProbability(double probability) async {
    // Generate random number between 0 and 1
    final random = Random();
    final shouldShowAd = random.nextDouble() < probability;
    
    if (!shouldShowAd) {
      return false; // Skip showing ad
    }

    // Try to show ad if probability allows
    return await showAd();
  }

  /// Show interstitial ad with 100% probability (always show)
  /// Returns true if ad was shown, false if not shown (due to loading errors)
  Future<bool> showAdAlways() async {
    return await showAdWithCustomProbability(1.0); // 100% probability
  }

  /// Preload ad for better user experience
  Future<void> preloadAd() async {
    if (!_isAdReady && !_isLoading) {
      await loadAd();
    }
  }

  /// Dispose current ad
  void _disposeAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdReady = false;
  }

  /// Dispose service
  void dispose() {
    _disposeAd();
  }
}

import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service to manage rewarded ads
class RewardedAdService {
  static RewardedAdService? _instance;
  static RewardedAdService get instance => _instance ??= RewardedAdService._();
  
  RewardedAdService._();

  RewardedAd? _rewardedAd;
  bool _isAdReady = false;
  bool _isLoading = false;

  /// Test ad unit ID for development (works on both platforms)
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  
  /// Production ad unit IDs for each platform
  static const String _productionAdUnitIdAndroid = 'ca-app-pub-3772142815301617/REWARDED_AD_ANDROID';
  static const String _productionAdUnitIdIOS = 'ca-app-pub-3772142815301617/REWARDED_AD_IOS';
  
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

  /// Current ad unit ID (using test for now - update with production IDs when ready)
  static String get _adUnitId => _testAdUnitId;

  /// Check if ad is ready to show
  bool get isAdReady => _isAdReady;

  /// Load rewarded ad
  Future<void> loadAd() async {
    if (_isLoading || _isAdReady) return;

    _isLoading = true;

    try {
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isAdReady = true;
            _isLoading = false;
            
            // Set up ad callbacks
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
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

  /// Show rewarded ad if ready
  /// Returns true if ad was shown, false otherwise
  /// The onRewarded callback will be called when user earns the reward
  Future<bool> showAd({
    required Function(RewardItem) onRewarded,
    Function()? onAdFailedToShow,
  }) async {
    if (!_isAdReady || _rewardedAd == null) {
      await loadAd();
      if (!_isAdReady || _rewardedAd == null) {
        onAdFailedToShow?.call();
        return false;
      }
    }

    try {
      // Update the full screen content callback to handle failure
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {},
        onAdDismissedFullScreenContent: (ad) {
          _disposeAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _disposeAd();
          onAdFailedToShow?.call();
        },
      );
      
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onRewarded(reward);
          // Note: ad will be disposed by fullScreenContentCallback
        },
      );
      
      return true;
    } catch (e) {
      _disposeAd();
      onAdFailedToShow?.call();
      return false;
    }
  }

  /// Preload ad for better user experience
  Future<void> preloadAd() async {
    if (!_isAdReady && !_isLoading) {
      await loadAd();
    }
  }

  /// Dispose current ad
  void _disposeAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdReady = false;
  }

  /// Dispose service
  void dispose() {
    _disposeAd();
  }
}


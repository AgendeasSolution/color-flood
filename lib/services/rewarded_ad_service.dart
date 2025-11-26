import 'dart:io';
import 'package:flutter/foundation.dart';
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
    if (_isLoading || _isAdReady) {
      debugPrint('[RewardedAdService] loadAd skipped - isLoading: $_isLoading, isAdReady: $_isAdReady');
      return;
    }

    debugPrint('[RewardedAdService] Loading ad with unit ID: $_adUnitId');
    _isLoading = true;

    try {
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('[RewardedAdService] Ad loaded successfully');
            _rewardedAd = ad;
            _isAdReady = true;
            _isLoading = false;
            
            // Set up ad callbacks
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('[RewardedAdService] Ad showed full screen content (initial callback)');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('[RewardedAdService] Ad dismissed (initial callback)');
                _disposeAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('[RewardedAdService] Ad failed to show (initial callback): $error');
                _disposeAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('[RewardedAdService] Ad failed to load: $error');
            _isLoading = false;
            _isAdReady = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('[RewardedAdService] Exception loading ad: $e');
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
      debugPrint('[RewardedAdService] showAd called - isAdReady: $_isAdReady, _rewardedAd: ${_rewardedAd != null}');
    
    if (!_isAdReady || _rewardedAd == null) {
      debugPrint('[RewardedAdService] Ad not ready, loading...');
      await loadAd();
      if (!_isAdReady || _rewardedAd == null) {
        debugPrint('[RewardedAdService] Failed to load ad');
        onAdFailedToShow?.call();
        return false;
      }
      debugPrint('[RewardedAdService] Ad loaded successfully');
    }

    try {
      // Update the full screen content callback to handle failure
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('[RewardedAdService] Ad showed full screen content');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('[RewardedAdService] Ad dismissed');
          _disposeAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('[RewardedAdService] Ad failed to show: $error');
          _disposeAd();
          onAdFailedToShow?.call();
        },
      );
      
      debugPrint('[RewardedAdService] Attempting to show ad...');
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('[RewardedAdService] User earned reward: ${reward.amount} ${reward.type}');
          onRewarded(reward);
          // Note: ad will be disposed by fullScreenContentCallback
        },
      );
      
      debugPrint('[RewardedAdService] Ad show called successfully');
      return true;
    } catch (e) {
      debugPrint('[RewardedAdService] Exception showing ad: $e');
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


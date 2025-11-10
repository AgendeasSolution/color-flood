import 'package:flutter/material.dart';
import '../ad_banner.dart';

/// Wrapper widget for banner ads with callback support
class BannerAdWidget extends StatelessWidget {
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailedToLoad;
  final VoidCallback? onAdClicked;

  const BannerAdWidget({
    super.key,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdClicked,
  });

  @override
  Widget build(BuildContext context) {
    return AdBanner(
      height: 90,
      onAdLoaded: onAdLoaded,
      onAdFailedToLoad: onAdFailedToLoad,
    );
  }
}


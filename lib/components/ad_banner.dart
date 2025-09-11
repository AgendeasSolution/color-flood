import 'package:flutter/material.dart';

/// A reusable ad banner component that displays at the bottom of screens
/// This is a placeholder implementation that can be replaced with real ad SDK
class AdBanner extends StatelessWidget {
  final double? height;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const AdBanner({
    super.key,
    this.height,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height ?? 50.0,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.8),
            const Color(0xFF16213E).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.ads_click,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Advertisement',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '320x50',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A more sophisticated ad banner with loading state and error handling
class AdBannerWithState extends StatefulWidget {
  final double? height;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailedToLoad;

  const AdBannerWithState({
    super.key,
    this.height,
    this.margin,
    this.padding,
    this.onAdLoaded,
    this.onAdFailedToLoad,
  });

  @override
  State<AdBannerWithState> createState() => _AdBannerWithStateState();
}

class _AdBannerWithStateState extends State<AdBannerWithState> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _simulateAdLoad();
  }

  void _simulateAdLoad() {
    // Simulate ad loading delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.onAdLoaded?.call();
      }
    });
  }

  void _retryLoadAd() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _simulateAdLoad();
  }

  @override
  Widget build(BuildContext context) {
    final hasZeroMargin = widget.margin == EdgeInsets.zero;
    
    return Container(
      width: double.infinity,
      height: widget.height ?? 50.0,
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: widget.padding ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.8),
            const Color(0xFF16213E).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: hasZeroMargin 
            ? BorderRadius.zero 
            : BorderRadius.circular(12),
        border: hasZeroMargin 
            ? null 
            : Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
        boxShadow: hasZeroMargin 
            ? null 
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.withOpacity(0.7),
              size: 16,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _retryLoadAd,
              child: Text(
                'Retry Ad',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.ads_click,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Advertisement',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '320x50',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

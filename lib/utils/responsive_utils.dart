import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
class ResponsiveUtils {
  // Breakpoints
  static const double smallPhone = 360.0;
  static const double mediumPhone = 400.0;
  static const double largePhone = 480.0;
  static const double smallTablet = 600.0;
  static const double mediumTablet = 768.0;
  static const double largeTablet = 900.0;
  static const double desktop = 1200.0;

  /// Check if the screen is a small phone
  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < smallPhone;
  }

  /// Check if the screen is a medium phone
  static bool isMediumPhone(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= smallPhone && width < largePhone;
  }

  /// Check if the screen is a large phone or small tablet
  static bool isLargePhone(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= largePhone && width < smallTablet;
  }

  /// Check if the screen is a tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= smallTablet;
  }

  /// Check if the screen is a small tablet
  static bool isSmallTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= smallTablet && width < mediumTablet;
  }

  /// Check if the screen is a large tablet or desktop
  static bool isLargeTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= mediumTablet;
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T smallPhone,
    required T mediumPhone,
    required T largePhone,
    required T tablet,
  }) {
    if (isSmallPhone(context)) return smallPhone;
    if (isMediumPhone(context)) return mediumPhone;
    if (isLargePhone(context)) return largePhone;
    return tablet;
  }

  /// Get responsive font size based on screen width
  static double getResponsiveFontSize(
    BuildContext context, {
    double smallPhone = 10,
    double mediumPhone = 12,
    double largePhone = 14,
    double tablet = 16,
  }) {
    return getResponsiveValue(
      context: context,
      smallPhone: smallPhone,
      mediumPhone: mediumPhone,
      largePhone: largePhone,
      tablet: tablet,
    );
  }

  /// Get responsive spacing based on screen size
  static double getResponsiveSpacing(
    BuildContext context, {
    double smallPhone = 4.0,
    double mediumPhone = 6.0,
    double largePhone = 8.0,
    double tablet = 10.0,
  }) {
    return getResponsiveValue(
      context: context,
      smallPhone: smallPhone,
      mediumPhone: mediumPhone,
      largePhone: largePhone,
      tablet: tablet,
    );
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    EdgeInsets smallPhone = const EdgeInsets.all(8),
    EdgeInsets mediumPhone = const EdgeInsets.all(12),
    EdgeInsets largePhone = const EdgeInsets.all(16),
    EdgeInsets tablet = const EdgeInsets.all(20),
  }) {
    return getResponsiveValue(
      context: context,
      smallPhone: smallPhone,
      mediumPhone: mediumPhone,
      largePhone: largePhone,
      tablet: tablet,
    );
  }

  /// Get responsive button size
  static double getResponsiveButtonSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < smallPhone) return 36;
    if (width < mediumPhone) return 40;
    if (width < largePhone) return 44;
    if (width < smallTablet) return 48;
    return 52;
  }

  /// Get responsive logo font size
  static double getResponsiveLogoSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < smallPhone) return 32;
    if (width < mediumPhone) return 36;
    if (width < largePhone) return 40;
    if (width < smallTablet) return 44;
    if (width < mediumTablet) return 48;
    return 56;
  }

  /// Get responsive grid cross axis count for level selection
  static int getResponsiveLevelGridCount(BuildContext context) {
    if (isTablet(context)) {
      // Tablets: show more columns
      if (isLargeTablet(context)) return 4;
      return 3;
    }
    // Phones: keep it at 3 columns
    return 3;
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(
    BuildContext context, {
    double smallPhone = 14.0,
    double mediumPhone = 16.0,
    double largePhone = 18.0,
    double tablet = 20.0,
  }) {
    return getResponsiveValue(
      context: context,
      smallPhone: smallPhone,
      mediumPhone: mediumPhone,
      largePhone: largePhone,
      tablet: tablet,
    );
  }

  /// Get responsive dialog width
  static double getResponsiveDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isTablet(context)) {
      return (screenWidth * 0.6).clamp(500, 800);
    }
    return (screenWidth * 0.9).clamp(300, 500);
  }

  /// Get responsive level button size
  static double getResponsiveLevelButtonSize(BuildContext context) {
    return getResponsiveValue(
      context: context,
      smallPhone: 50.0,
      mediumPhone: 55.0,
      largePhone: 60.0,
      tablet: 70.0,
    );
  }

  /// Get safe area padding
  static double getSafeAreaTop(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// Get safe area bottom padding
  static double getSafeAreaBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }
}


import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';

/// Glass morphism button component
class GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final List<Color>? gradientColors;

  const GlassButton({
    super.key,
    required this.onTap,
    required this.child,
    this.padding,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: padding ?? ResponsiveUtils.getResponsivePadding(
              context,
              smallPhone: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              mediumPhone: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              largePhone: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              tablet: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors ?? [
                  AppColors.surfaceLight.withOpacity(0.9),
                  AppColors.surface.withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceLight.withOpacity(0.6)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

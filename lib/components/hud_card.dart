import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// Glass morphism HUD card component
class HudCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const HudCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.9),
                const Color(0xFF2563EB).withOpacity(0.8),
                const Color(0xFF1D4ED8).withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFF1D4ED8).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

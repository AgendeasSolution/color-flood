import 'dart:ui';
import 'package:flutter/material.dart';

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: 20, 
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors ?? [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

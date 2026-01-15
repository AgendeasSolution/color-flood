import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import 'wood_button.dart';

/// Back button row with wood-textured buttons in skeuomorphic style
class BackButtonRow extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onReset;
  final Widget? centerWidget;
  final bool showResetBadge;
  final EdgeInsetsGeometry? padding;

  const BackButtonRow({
    super.key,
    required this.onBack,
    this.onReset,
    this.centerWidget,
    this.showResetBadge = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Make buttons smaller - reduce size by 20%
    final baseButtonSize = ResponsiveUtils.getResponsiveButtonSize(context);
    final buttonSize = baseButtonSize * 0.8;
    final spacing = ResponsiveUtils.getResponsiveSpacing(
      context,
      smallPhone: 12,
      mediumPhone: 14,
      largePhone: 16,
      tablet: 20,
    );

    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.only(
        left: spacing,
        right: spacing,
        bottom: spacing * 0.5,
        // No top padding to remove margin
      ),
      // Transparent background
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button (Left)
          WoodButton(
            onTap: onBack,
            size: buttonSize,
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white, // White for contrast on blue
              size: buttonSize * 0.5,
            ),
          ),

          // Center Widget (Level number, etc.)
          if (centerWidget != null)
            Expanded(
              child: Center(
                child: centerWidget!,
              ),
            ),

          // Reset Button (Right)
          if (onReset != null)
            WoodButton(
              onTap: onReset!,
              size: buttonSize,
              showBadge: showResetBadge,
              icon: Icon(
                Icons.refresh,
                color: Colors.white, // White for contrast on blue
                size: buttonSize * 0.5,
              ),
            ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import 'wood_button.dart';

/// Back button row with wood-textured buttons in skeuomorphic style
class BackButtonRow extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onReset;
  final VoidCallback? onUndo;
  final Widget? centerWidget;
  final bool showResetBadge;
  final EdgeInsetsGeometry? padding;

  const BackButtonRow({
    super.key,
    required this.onBack,
    this.onReset,
    this.onUndo,
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left side buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
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
            ],
          ),

          // Center Widget (Level number, etc.) - Centered independently
          if (centerWidget != null)
            Center(
              child: centerWidget!,
            ),

          // Right side buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Undo Button (Left of Reset)
              if (onUndo != null)
                WoodButton(
                  onTap: onUndo!,
                  size: buttonSize,
                  icon: Icon(
                    Icons.undo,
                    color: Colors.white, // White for contrast on blue
                    size: buttonSize * 0.5,
                  ),
                ),
              
              // Spacing between undo and reset
              if (onUndo != null && onReset != null)
                SizedBox(width: spacing * 0.5),

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
        ],
      ),
    );
  }
}


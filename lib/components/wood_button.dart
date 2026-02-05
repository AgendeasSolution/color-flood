import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';

/// Wood-textured, skeuomorphic circular button component
class WoodButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget icon;
  final double? size;
  final bool showBadge;

  const WoodButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.size,
    this.showBadge = false,
  });

  @override
  State<WoodButton> createState() => _WoodButtonState();
}

class _WoodButtonState extends State<WoodButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.size ?? ResponsiveUtils.getResponsiveButtonSize(context);
    final pressOffset = _isPressed ? 2.0 : 0.0;
    
    // Gray colors to match background
    const grayBaseColor = Color(0xFF1F2937); // Surface
    const grayLightColor = Color(0xFF374151); // Surface light
    const grayDarkColor = Color(0xFF111827); // Background
    const iconColor = Color(0xFFFFFFFF); // White for contrast
    const embossColor = Color(0xFF6B7280); // Gray for embossed edge
    const lightBorderColor = Color(0xFF4B5563); // Gray border

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Transform.translate(
        offset: Offset(0, pressOffset),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Main shadow for depth
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 0,
                offset: Offset(0, 4 + pressOffset),
              ),
              // Soft outer glow
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                spreadRadius: -2,
                offset: Offset(0, 6 + pressOffset),
              ),
            ],
          ),
          child: ClipOval(
            child: Stack(
              children: [
                // Base gray layer with gradient
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.2,
                      colors: [
                        grayLightColor,
                        grayBaseColor,
                        grayDarkColor,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                
                // Subtle texture pattern overlay (optional, can be removed if too busy)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WoodGrainPainter(),
                  ),
                ),
                
                // Additional depth with subtle radial gradient overlay
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.0,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
                
                // Light border (outer) - very subtle
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: lightBorderColor,
                      width: 2.0,
                    ),
                  ),
                ),
                
                // Inner embossed edge effect
                Positioned(
                  top: 3,
                  left: 3,
                  right: 3,
                  bottom: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: embossColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                
                // Icon in center
                Center(
                  child: DefaultTextStyle(
                    style: TextStyle(color: iconColor),
                    child: widget.icon,
                  ),
                ),
                
                // Notification badge (if needed)
                if (widget.showBadge)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: buttonSize * 0.3,
                      height: buttonSize * 0.3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for wood grain texture
class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw curved wood grain lines radiating from center
    final grainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 2 * math.pi) / 12;
      final startRadius = radius * 0.25;
      final endRadius = radius * 0.95;
      
      final startX = center.dx + startRadius * math.cos(angle);
      final startY = center.dy + startRadius * math.sin(angle);
      final endX = center.dx + endRadius * math.cos(angle);
      final endY = center.dy + endRadius * math.sin(angle);

      grainPaint.color = AppColors.surfaceLight.withOpacity(0.25 - (i % 3) * 0.04);
      
      final path = Path();
      path.moveTo(startX, startY);
      // Create curved grain lines
      final midX = center.dx + (radius * 0.6) * math.cos(angle + 0.1);
      final midY = center.dy + (radius * 0.6) * math.sin(angle + 0.1);
      path.quadraticBezierTo(midX, midY, endX, endY);
      canvas.drawPath(path, grainPaint);
    }

    // Add horizontal grain lines for more texture
    for (int i = 0; i < 6; i++) {
      final y = center.dy + (radius * 0.7) * (i - 3) / 3;
      if (y > center.dy - radius && y < center.dy + radius) {
        final x1 = center.dx - math.sqrt(radius * radius - (y - center.dy) * (y - center.dy));
        final x2 = center.dx + math.sqrt(radius * radius - (y - center.dy) * (y - center.dy));
        
        grainPaint.color = AppColors.surfaceLight.withOpacity(0.2);
        grainPaint.strokeWidth = 0.8;
        canvas.drawLine(Offset(x1, y), Offset(x2, y), grainPaint);
      }
    }

    // Add grain spots and knots
    final spotPaint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = i * 0.8;
      final dist = radius * (0.4 + (i % 3) * 0.2);
      final x = center.dx + dist * math.cos(angle);
      final y = center.dy + dist * math.sin(angle);
      
      spotPaint.color = AppColors.surfaceLight.withOpacity(0.2);
      canvas.drawCircle(Offset(x, y), 1.2, spotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

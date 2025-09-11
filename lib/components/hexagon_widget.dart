import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom hexagon widget for level selection
class HexagonWidget extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final double size;
  final VoidCallback? onTap;

  const HexagonWidget({
    super.key,
    required this.child,
    required this.colors,
    required this.borderColor,
    this.borderWidth = 1.0,
    this.shadows,
    this.size = 60.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        size: Size(size, size),
        painter: HexagonPainter(
          colors: colors,
          borderColor: borderColor,
          borderWidth: borderWidth,
          shadows: shadows,
        ),
        child: Center(
          child: child,
        ),
      ),
    );
  }
}

/// Custom painter for drawing hexagons
class HexagonPainter extends CustomPainter {
  final List<Color> colors;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;

  HexagonPainter({
    required this.colors,
    required this.borderColor,
    required this.borderWidth,
    this.shadows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - borderWidth;

    // Create hexagon path
    final path = _createHexagonPath(center, radius);

    // Draw shadows first
    if (shadows != null) {
      for (final shadow in shadows!) {
        final shadowPath = _createHexagonPath(
          Offset(center.dx + shadow.offset.dx, center.dy + shadow.offset.dy),
          radius - shadow.spreadRadius,
        );
        
        final shadowPaint = Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);
        
        canvas.drawPath(shadowPath, shadowPaint);
      }
    }

    // Create gradient
    final gradient = LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Draw hexagon fill
    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(path, fillPaint);

    // Draw inner glow effect
    final innerGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);

    final innerPath = _createHexagonPath(center, radius - 2);
    canvas.drawPath(innerPath, innerGlowPaint);

    // Draw hexagon border with gradient
    final borderGradient = LinearGradient(
      colors: [
        borderColor.withOpacity(0.8),
        borderColor,
        borderColor.withOpacity(0.6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final borderPaint = Paint()
      ..shader = borderGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawPath(path, borderPaint);

    // Draw highlight on top edge
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final highlightPath = _createHexagonPath(center, radius - 1);
    canvas.drawPath(highlightPath, highlightPaint);
  }

  Path _createHexagonPath(Offset center, double radius) {
    final path = Path();
    const double angleStep = math.pi / 3; // 60 degrees in radians

    for (int i = 0; i < 6; i++) {
      final angle = i * angleStep - math.pi / 2; // Start from top
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is HexagonPainter &&
        (oldDelegate.colors != colors ||
            oldDelegate.borderColor != borderColor ||
            oldDelegate.borderWidth != borderWidth ||
            oldDelegate.shadows != shadows);
  }
}

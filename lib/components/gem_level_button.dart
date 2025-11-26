import 'dart:ui';
import 'package:flutter/material.dart';

/// 3D gem widget for level buttons matching game board style
class GemLevelButton extends StatelessWidget {
  final Color baseColor;
  final double size;
  final Widget child;
  final VoidCallback? onTap;
  final List<BoxShadow>? customShadows;

  const GemLevelButton({
    super.key,
    required this.baseColor,
    required this.size,
    required this.child,
    this.onTap,
    this.customShadows,
  });

  @override
  Widget build(BuildContext context) {
    final bevelSize = size * 0.14; // Same bevel ratio as game board
    
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.12),
            boxShadow: customShadows ?? [
              // Deep shadow for dramatic 3D effect
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 10,
                spreadRadius: -3,
                offset: const Offset(0, 5),
              ),
              // Medium shadow layer
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: -1,
                offset: const Offset(0, 2),
              ),
              // Inner glow with color
              BoxShadow(
                color: baseColor.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1.5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.12),
            child: CustomPaint(
              size: Size(size, size),
              painter: _GemLevelPainter(
                baseColor: baseColor,
                size: size,
                bevelSize: bevelSize,
              ),
              child: Center(
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for 3D gem level buttons
class _GemLevelPainter extends CustomPainter {
  final Color baseColor;
  final double size;
  final double bevelSize;

  _GemLevelPainter({
    required this.baseColor,
    required this.size,
    required this.bevelSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerSize = this.size - (bevelSize * 2);
    final innerOffset = bevelSize * 0.65;
    
    // Helper functions
    Color lightenColor(Color color, double amount) {
      final hsl = HSLColor.fromColor(color);
      final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
      final saturation = (hsl.saturation * 1.1).clamp(0.0, 1.0);
      return hsl.withLightness(lightness).withSaturation(saturation).toColor();
    }
    
    Color darkenColor(Color color, double amount) {
      final hsl = HSLColor.fromColor(color);
      final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
      return hsl.withLightness(lightness).toColor();
    }
    
    Color blendColor(Color c1, Color c2, double ratio) {
      return Color.lerp(c1, c2, ratio)!;
    }

    // Base background with rich gradient for depth
    final baseGradient = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [
          darkenColor(baseColor, 0.2),
          darkenColor(baseColor, 0.15),
          darkenColor(baseColor, 0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromLTWH(0, 0, this.size, this.size),
      );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, this.size, this.size),
        Radius.circular(this.size * 0.12),
      ),
      baseGradient,
    );

    // Central square facet (main raised surface)
    final centerLeft = bevelSize;
    final centerTop = bevelSize;
    
    // Central facet with rich, multi-stop gradient
    final centerGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          lightenColor(baseColor, 0.3),
          lightenColor(baseColor, 0.15),
          baseColor,
          darkenColor(baseColor, 0.15),
          darkenColor(baseColor, 0.3),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(
        Rect.fromLTWH(centerLeft, centerTop, centerSize, centerSize),
      );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerLeft, centerTop, centerSize, centerSize),
        Radius.circular(this.size * 0.12),
      ),
      centerGradient,
    );

    // Primary light source highlight (top-left)
    final primaryHighlight = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 0.65,
        colors: [
          Colors.white.withOpacity(0.8),
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.2),
          blendColor(Colors.white, baseColor, 0.3).withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(
        Rect.fromLTWH(centerLeft, centerTop, centerSize * 0.7, centerSize * 0.7),
      );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerLeft, centerTop, centerSize * 0.7, centerSize * 0.7),
        Radius.circular(this.size * 0.12),
      ),
      primaryHighlight,
    );

    // Secondary highlight (top-right, softer)
    final secondaryHighlight = Paint()
      ..shader = RadialGradient(
        center: Alignment.topRight,
        radius: 0.5,
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromLTWH(centerLeft + centerSize * 0.3, centerTop, centerSize * 0.5, centerSize * 0.5),
      );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerLeft + centerSize * 0.3, centerTop, centerSize * 0.5, centerSize * 0.5),
        Radius.circular(this.size * 0.12),
      ),
      secondaryHighlight,
    );

    // Inner glow for depth
    final innerGlow = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          Colors.transparent,
          baseColor.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromLTWH(centerLeft, centerTop, centerSize, centerSize),
      );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerLeft, centerTop, centerSize, centerSize),
        Radius.circular(this.size * 0.12),
      ),
      innerGlow,
    );

    // Top trapezoidal facet
    final topFacetPath = Path()
      ..moveTo(bevelSize, bevelSize)
      ..lineTo(this.size - bevelSize, bevelSize)
      ..lineTo(this.size - innerOffset, innerOffset)
      ..lineTo(innerOffset, innerOffset)
      ..close();
    
    final topFacetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.7),
          Colors.white.withOpacity(0.4),
          blendColor(Colors.white, baseColor, 0.5).withOpacity(0.3),
          lightenColor(baseColor, 0.15).withOpacity(0.5),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(
        Rect.fromLTWH(0, 0, this.size, bevelSize),
      );
    
    canvas.drawPath(topFacetPath, topFacetPaint);

    // Bottom trapezoidal facet
    final bottomFacetPath = Path()
      ..moveTo(innerOffset, this.size - innerOffset)
      ..lineTo(this.size - innerOffset, this.size - innerOffset)
      ..lineTo(this.size - bevelSize, this.size - bevelSize)
      ..lineTo(bevelSize, this.size - bevelSize)
      ..close();
    
    final bottomFacetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          baseColor.withOpacity(0.5),
          darkenColor(baseColor, 0.35).withOpacity(0.85),
          darkenColor(baseColor, 0.5).withOpacity(0.95),
          Colors.black.withOpacity(0.3),
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(
        Rect.fromLTWH(0, this.size - bevelSize, this.size, bevelSize),
      );
    
    canvas.drawPath(bottomFacetPath, bottomFacetPaint);

    // Left trapezoidal facet
    final leftFacetPath = Path()
      ..moveTo(bevelSize, bevelSize)
      ..lineTo(innerOffset, innerOffset)
      ..lineTo(innerOffset, this.size - innerOffset)
      ..lineTo(bevelSize, this.size - bevelSize)
      ..close();
    
    final leftFacetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.55),
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.1),
          lightenColor(baseColor, 0.1).withOpacity(0.4),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(
        Rect.fromLTWH(0, 0, bevelSize, this.size),
      );
    
    canvas.drawPath(leftFacetPath, leftFacetPaint);

    // Right trapezoidal facet
    final rightFacetPath = Path()
      ..moveTo(this.size - bevelSize, bevelSize)
      ..lineTo(this.size - bevelSize, this.size - bevelSize)
      ..lineTo(this.size - innerOffset, this.size - innerOffset)
      ..lineTo(this.size - innerOffset, innerOffset)
      ..close();
    
    final rightFacetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          darkenColor(baseColor, 0.4).withOpacity(0.8),
          darkenColor(baseColor, 0.25).withOpacity(0.65),
          darkenColor(baseColor, 0.1).withOpacity(0.5),
          baseColor.withOpacity(0.4),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(
        Rect.fromLTWH(this.size - bevelSize, 0, bevelSize, this.size),
      );
    
    canvas.drawPath(rightFacetPath, rightFacetPaint);
    
    // Professional facet separation lines (subtle but defined)
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    
    // Top facet separation
    canvas.drawLine(
      Offset(bevelSize, bevelSize),
      Offset(this.size - bevelSize, bevelSize),
      linePaint,
    );
    // Bottom facet separation
    canvas.drawLine(
      Offset(bevelSize, this.size - bevelSize),
      Offset(this.size - bevelSize, this.size - bevelSize),
      linePaint,
    );
    // Left facet separation
    canvas.drawLine(
      Offset(bevelSize, bevelSize),
      Offset(bevelSize, this.size - bevelSize),
      linePaint,
    );
    // Right facet separation
    canvas.drawLine(
      Offset(this.size - bevelSize, bevelSize),
      Offset(this.size - bevelSize, this.size - bevelSize),
      linePaint,
    );

    // Top-left triangular corner facet (brightest corner, catches primary light)
    final topLeftCornerPath = Path()
      ..moveTo(0, 0)
      ..lineTo(bevelSize, bevelSize)
      ..lineTo(innerOffset, innerOffset)
      ..lineTo(innerOffset, 0)
      ..lineTo(0, innerOffset)
      ..close();
    
    final topLeftCornerPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.1,
        colors: [
          Colors.white.withOpacity(0.85),
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.3),
          blendColor(Colors.white, baseColor, 0.4).withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(
        Rect.fromLTWH(0, 0, bevelSize, bevelSize),
      );
    
    canvas.drawPath(topLeftCornerPath, topLeftCornerPaint);

    // Top-right triangular corner facet (bright, secondary light)
    final topRightCornerPath = Path()
      ..moveTo(this.size, 0)
      ..lineTo(this.size, innerOffset)
      ..lineTo(this.size - innerOffset, innerOffset)
      ..lineTo(this.size - bevelSize, bevelSize)
      ..lineTo(this.size - innerOffset, 0)
      ..close();
    
    final topRightCornerPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topRight,
        radius: 1.1,
        colors: [
          Colors.white.withOpacity(0.8),
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.25),
          blendColor(Colors.white, baseColor, 0.3).withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(
        Rect.fromLTWH(this.size - bevelSize, 0, bevelSize, bevelSize),
      );
    
    canvas.drawPath(topRightCornerPath, topRightCornerPaint);

    // Bottom-left triangular corner facet (medium shadow, some reflected light)
    final bottomLeftCornerPath = Path()
      ..moveTo(0, this.size)
      ..lineTo(0, this.size - innerOffset)
      ..lineTo(innerOffset, this.size - innerOffset)
      ..lineTo(bevelSize, this.size - bevelSize)
      ..lineTo(innerOffset, this.size)
      ..close();
    
    final bottomLeftCornerPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomLeft,
        radius: 1.1,
        colors: [
          darkenColor(baseColor, 0.3).withOpacity(0.7),
          darkenColor(baseColor, 0.2).withOpacity(0.5),
          darkenColor(baseColor, 0.1).withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(
        Rect.fromLTWH(0, this.size - bevelSize, bevelSize, bevelSize),
      );
    
    canvas.drawPath(bottomLeftCornerPath, bottomLeftCornerPaint);

    // Bottom-right triangular corner facet (darkest corner, deepest shadow)
    final bottomRightCornerPath = Path()
      ..moveTo(this.size, this.size)
      ..lineTo(this.size, this.size - innerOffset)
      ..lineTo(this.size - innerOffset, this.size - innerOffset)
      ..lineTo(this.size - bevelSize, this.size - bevelSize)
      ..lineTo(this.size - innerOffset, this.size)
      ..close();
    
    final bottomRightCornerPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomRight,
        radius: 1.1,
        colors: [
          Colors.black.withOpacity(0.5),
          darkenColor(baseColor, 0.5).withOpacity(0.7),
          darkenColor(baseColor, 0.3).withOpacity(0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(
        Rect.fromLTWH(this.size - bevelSize, this.size - bevelSize, bevelSize, bevelSize),
      );
    
    canvas.drawPath(bottomRightCornerPath, bottomRightCornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _GemLevelPainter ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.size != size ||
        oldDelegate.bevelSize != bevelSize;
  }
}


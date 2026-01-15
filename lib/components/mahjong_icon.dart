import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Physics/Math icon types
enum MahjongIconType {
  alpha,        // α
  beta,         // β
  gamma,        // γ
  sigma,        // σ
  triangle,     // Δ
  verticalLines, // ||| (3 vertical lines)
}

/// Custom widget for rendering Mahjong tile icons
class MahjongIcon extends StatelessWidget {
  final Color color;
  final double size;
  final MahjongIconType iconType;

  const MahjongIcon({
    super.key,
    required this.color,
    required this.size,
    required this.iconType,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MahjongIconPainter(
          iconType: iconType,
          color: color,
        ),
      ),
    );
  }

  /// Get icon type for a given color
  static MahjongIconType getIconTypeForColor(Color color) {
    // Red - Alpha (α)
    if (color.value == 0xFFEF4444) {
      return MahjongIconType.alpha;
    }
    // Blue - Beta (β)
    else if (color.value == 0xFF3B82F6) {
      return MahjongIconType.beta;
    }
    // Green - Gamma (γ)
    else if (color.value == 0xFF30D158) {
      return MahjongIconType.gamma;
    }
    // Yellow - Sigma (σ)
    else if (color.value == 0xFFFFD60A) {
      return MahjongIconType.sigma;
    }
    // Orange - Triangle (Δ)
    else if (color.value == 0xFFFF9F0A) {
      return MahjongIconType.triangle;
    }
    // Pink - 3 Vertical Lines (|||)
    else if (color.value == 0xFFEC4899) {
      return MahjongIconType.verticalLines;
    }
    // Default
    else {
      return MahjongIconType.alpha;
    }
  }
}

/// Custom painter for Mahjong icons
class _MahjongIconPainter extends CustomPainter {
  final MahjongIconType iconType;
  final Color color;

  _MahjongIconPainter({
    required this.iconType,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (iconType) {
      case MahjongIconType.alpha:
        _drawAlpha(canvas, size, center, paint);
        break;
      case MahjongIconType.beta:
        _drawBeta(canvas, size, center, paint);
        break;
      case MahjongIconType.gamma:
        _drawGamma(canvas, size, center, paint);
        break;
      case MahjongIconType.sigma:
        _drawSigma(canvas, size, center, paint);
        break;
      case MahjongIconType.triangle:
        _drawTriangle(canvas, size, center, paint);
        break;
      case MahjongIconType.verticalLines:
        _drawVerticalLines(canvas, size, center, paint);
        break;
    }
  }

  void _drawAlpha(Canvas canvas, Size size, Offset center, Paint paint) {
    // Draw Alpha (α)
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'α',
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawBeta(Canvas canvas, Size size, Offset center, Paint paint) {
    // Draw Beta (β)
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'β',
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawGamma(Canvas canvas, Size size, Offset center, Paint paint) {
    // Draw Gamma (γ)
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'γ',
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawSigma(Canvas canvas, Size size, Offset center, Paint paint) {
    // Draw Sigma (σ)
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'σ',
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawTriangle(Canvas canvas, Size size, Offset center, Paint paint) {
    // Draw Triangle (Δ)
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Δ',
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawVerticalLines(Canvas canvas, Size size, Offset center, Paint paint) {
    // Draw 3 vertical lines (|||)
    final lineWidth = size.width * 0.08;
    final lineHeight = size.height * 0.5;
    final spacing = size.width * 0.15;
    
    for (int i = 0; i < 3; i++) {
      final x = center.dx - spacing + (i * spacing);
      final rect = Rect.fromCenter(
        center: Offset(x, center.dy),
        width: lineWidth,
        height: lineHeight,
      );
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(lineWidth / 2));
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(_MahjongIconPainter oldDelegate) {
    return oldDelegate.iconType != iconType || oldDelegate.color != color;
  }
}

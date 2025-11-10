import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter for creating floating golden particles
class CustomParticlePainter extends CustomPainter {
  final double animationValue;
  final Size screenSize;
  
  // Golden color palette
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color lightGold = Color(0xFFFFF8DC);
  static const Color darkGold = Color(0xFFB8860B);
  
  CustomParticlePainter({
    required this.animationValue,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Draw small twinkling stars (30 particles)
    _drawSmallStars(canvas, paint);
    
    // Draw medium glowing stars (8 particles)
    _drawMediumStars(canvas, paint);
    
    // Draw large glowing orbs (4 particles)
    _drawLargeOrbs(canvas, paint);
    
    // Draw distant nebula-like effects (2 particles)
    _drawNebulaEffects(canvas, paint);
  }
  
  void _drawSmallStars(Canvas canvas, Paint paint) {
    final random = math.Random(42); // Fixed seed for consistent positioning
    
    for (int i = 0; i < 30; i++) {
      final x = (random.nextDouble() * screenSize.width);
      final y = (random.nextDouble() * screenSize.height);
      final radius = 0.5 + random.nextDouble() * 0.5; // 0.5-1px radius
      
      // Twinkling effect
      final twinkle = (math.sin(animationValue * 2 * math.pi + i * 0.5) + 1) / 2;
      final alpha = (0.2 + twinkle * 0.3).clamp(0.0, 1.0);
      
      paint.color = primaryGold.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  void _drawMediumStars(Canvas canvas, Paint paint) {
    final random = math.Random(123);
    
    for (int i = 0; i < 8; i++) {
      final x = (random.nextDouble() * screenSize.width);
      final y = (random.nextDouble() * screenSize.height);
      final radius = 1.0 + random.nextDouble() * 1.0; // 1-2px radius
      
      // Gentle pulsing glow
      final pulse = (math.sin(animationValue * math.pi + i * 0.3) + 1) / 2;
      final alpha = (0.3 + pulse * 0.2).clamp(0.0, 1.0);
      
      // Create glow effect with multiple circles
      paint.color = primaryGold.withOpacity(alpha * 0.2);
      canvas.drawCircle(Offset(x, y), radius * 1.5, paint);
      
      paint.color = primaryGold.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  void _drawLargeOrbs(Canvas canvas, Paint paint) {
    final random = math.Random(456);
    
    for (int i = 0; i < 4; i++) {
      final x = (random.nextDouble() * screenSize.width);
      final y = (random.nextDouble() * screenSize.height);
      final radius = 2.0 + random.nextDouble() * 1.0; // 2-3px radius
      
      // Slow breathing effect
      final breath = (math.sin(animationValue * 0.5 * math.pi + i * 0.8) + 1) / 2;
      final alpha = (0.15 + breath * 0.15).clamp(0.0, 1.0);
      
      // Create multiple layers for glow
      paint.color = primaryGold.withOpacity(alpha * 0.05);
      canvas.drawCircle(Offset(x, y), radius * 2, paint);
      
      paint.color = primaryGold.withOpacity(alpha * 0.2);
      canvas.drawCircle(Offset(x, y), radius * 1.5, paint);
      
      paint.color = primaryGold.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  void _drawNebulaEffects(Canvas canvas, Paint paint) {
    final random = math.Random(789);
    
    for (int i = 0; i < 2; i++) {
      final x = (random.nextDouble() * screenSize.width);
      final y = (random.nextDouble() * screenSize.height);
      final radius = 8.0 + random.nextDouble() * 5.0; // 8-13px radius
      
      // Slow, dreamy movement
      final drift = (math.sin(animationValue * 0.3 * math.pi + i * 1.2) + 1) / 2;
      final alpha = (0.03 + drift * 0.05).clamp(0.0, 1.0);
      
      // Create nebula-like gradient effect
      final gradient = RadialGradient(
        colors: [
          primaryGold.withOpacity(alpha),
          primaryGold.withOpacity(alpha * 0.5),
          primaryGold.withOpacity(alpha * 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      );
      
      paint.shader = gradient.createShader(Rect.fromCircle(
        center: Offset(x, y),
        radius: radius,
      ));
      
      canvas.drawCircle(Offset(x, y), radius, paint);
      paint.shader = null; // Reset shader
    }
  }

  @override
  bool shouldRepaint(CustomParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Reusable animated background widget with floating golden particles
class AnimatedBackground extends StatefulWidget {
  final bool enableAnimation;
  final Duration animationDuration;
  final AnimationController? controller;
  
  const AnimatedBackground({
    super.key,
    this.enableAnimation = true,
    this.animationDuration = const Duration(seconds: 20),
    this.controller,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExternalController = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    if (widget.controller != null) {
      // Use external controller
      _animationController = widget.controller!;
      _isExternalController = true;
      _animation = CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      );
    } else {
      // Create internal controller
      _animationController = AnimationController(
        vsync: this,
        duration: widget.animationDuration,
      );
      _animation = CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      );

      if (widget.enableAnimation) {
        _animationController.repeat(); // Continuous loop
      }
    }
  }

  @override
  void dispose() {
    // Only dispose if we created the controller internally
    if (!_isExternalController) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0A0A0A), // Deep black
            Color(0xFF1A1A2E), // Dark blue
            Color(0xFF16213E), // Darker blue
            Color(0xFF0F3460), // Navy blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: CustomParticlePainter(
              animationValue: _animation.value,
              screenSize: MediaQuery.of(context).size,
            ),
            size: MediaQuery.of(context).size,
          );
        },
      ),
    );
  }
}
